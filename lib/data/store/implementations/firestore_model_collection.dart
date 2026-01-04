import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/store/models/model_collection.dart';

/// A Firestore-backed collection that manages a set of models with automatic synchronization.
/// Uses Firestore's withConverter API for type-safe document conversion.
class FirestoreModelCollection<Model>
    implements ModelCollectionModifier<Model> {
  final CollectionReference<LeafRepositoryItem<Model>>
      _typedCollectionReference;
  bool _shouldListenToUpdates = false;
  late final StreamSubscription _collectionStreamSubscription;

  /// Creates a new FirestoreModelCollection instance.
  ///
  /// [collectionReference] - The raw Firestore collection reference
  /// [fromDocumentSnapshot] - Function to convert a DocumentSnapshot to a LeafRepositoryItem
  /// [leafRepositoryItemCreator] - Function to create a LeafRepositoryItem from a Model
  /// [query] - Optional query to filter the collection
  static Future<ModelCollectionModifier<Model>> createInstance<Model>(
      CollectionReference collectionReference,
      LeafRepositoryItem<Model> Function(DocumentSnapshot documentSnapshot)
          fromDocumentSnapshot,
      LeafRepositoryItem<Model> Function(Model) leafRepositoryItemCreator,
      {Query? query}) async {
    // Create typed converter for Firestore
    final typedCollectionReference =
        collectionReference.withConverter<LeafRepositoryItem<Model>>(
      fromFirestore: (snapshot, _) => fromDocumentSnapshot(snapshot),
      toFirestore: (item, _) => item.toJson(),
    );

    // Apply query with converter if provided
    Query<LeafRepositoryItem<Model>>? typedQuery;
    if (query != null) {
      typedQuery = query.withConverter<LeafRepositoryItem<Model>>(
        fromFirestore: (snapshot, _) => fromDocumentSnapshot(snapshot),
        toFirestore: (item, _) => item.toJson(),
      );
    }

    // Load initial collection items
    var collectionItems = <LeafRepositoryItem<Model>>[];
    var queryResult = await (typedQuery ?? typedCollectionReference).get();
    for (final documentSnapshot in queryResult.docs) {
      collectionItems.add(documentSnapshot.data());
    }

    return FirestoreModelCollection<Model>._(
      typedCollectionReference: typedCollectionReference,
      typedQuery: typedQuery,
      repositoryItemCreator: leafRepositoryItemCreator,
      collectionItems: collectionItems,
    );
  }

  @override
  Iterable<Model> get collectionItems =>
      _collectionItems.map((collectionItem) => collectionItem.facade);
  final List<LeafRepositoryItem<Model>> _collectionItems;

  @override
  Future dispose() async {
    await _collectionStreamSubscription.cancel();
    await _updationStreamController.close();
    await _deletionStreamController.close();
    await _additionStreamController.close();
    _collectionItems.clear();
  }

  @override
  Stream<CollectionItemChangeMetadata<Model>> get onDocumentAdded =>
      _additionStreamController.stream;
  final StreamController<CollectionItemChangeMetadata<Model>>
      _additionStreamController =
      StreamController<CollectionItemChangeMetadata<Model>>.broadcast();

  @override
  Stream<CollectionItemChangeMetadata<Model>> get onDocumentDeleted =>
      _deletionStreamController.stream;
  final StreamController<CollectionItemChangeMetadata<Model>>
      _deletionStreamController =
      StreamController<CollectionItemChangeMetadata<Model>>.broadcast();

  @override
  Stream<CollectionItemChangeMetadata<CollectionItemChangeSet<Model>>>
      get onDocumentUpdated => _updationStreamController.stream;
  final StreamController<
          CollectionItemChangeMetadata<CollectionItemChangeSet<Model>>>
      _updationStreamController = StreamController<
          CollectionItemChangeMetadata<
              CollectionItemChangeSet<Model>>>.broadcast();

  @override
  LeafRepositoryItem<Model> Function(Model model) repositoryItemCreator;

  @override
  Future<void> runUpdateTransaction(
      Future<void> Function() updateTransaction) async {
    _collectionStreamSubscription.pause();
    _shouldListenToUpdates = false;
    await updateTransaction();
    _collectionStreamSubscription.resume();
    _shouldListenToUpdates = true;
  }

  @override
  Future<Model?> tryAdd(Model toAdd) async {
    LeafRepositoryItem<Model>? addedCollectionItem;

    await runUpdateTransaction(() async {
      var leafRepositoryItem = repositoryItemCreator(toAdd);
      var addResult = await _typedCollectionReference.add(leafRepositoryItem);
      addedCollectionItem = leafRepositoryItem;
      addedCollectionItem!.id = addResult.id;
      _collectionItems.add(addedCollectionItem!);
      _additionStreamController.add(CollectionItemChangeMetadata(
          addedCollectionItem!.facade,
          isFromExplicitAction: true));
    });

    return addedCollectionItem?.facade;
  }

  @override
  FutureOr<bool> tryDeleteItem(Model toDelete) async {
    var didDelete = false;
    await runUpdateTransaction(() async {
      var leafRepositoryItem = repositoryItemCreator(toDelete);
      didDelete = await _tryDeleteCollectionItem(leafRepositoryItem);
      if (didDelete) {
        _deletionStreamController.add(CollectionItemChangeMetadata(
            leafRepositoryItem.facade,
            isFromExplicitAction: true));
      }
    });
    return didDelete;
  }

  @override
  FutureOr<bool> tryUpdateItem(Model toUpdate) async {
    var didUpdate = false;
    await runUpdateTransaction(() async {
      var leafRepositoryItem = repositoryItemCreator(toUpdate);
      var matchingElementIndex = _collectionItems.indexWhere((repositoryItem) =>
          repositoryItem.documentReference.id ==
          leafRepositoryItem.documentReference.id);
      if (matchingElementIndex == -1) {
        didUpdate = false;
        return;
      }
      var collectionItemBeforeUpdate = _collectionItems[matchingElementIndex];

      var typedDocRef = _typedCollectionReference
          .doc(leafRepositoryItem.documentReference.id);

      didUpdate = await typedDocRef
          .set(leafRepositoryItem, SetOptions(merge: false))
          .then((value) {
        return true;
      }).catchError((error, stackTrace) {
        return false;
      });

      if (didUpdate) {
        _collectionItems[matchingElementIndex] = leafRepositoryItem;
        _updationStreamController.add(CollectionItemChangeMetadata(
            CollectionItemChangeSet(
                collectionItemBeforeUpdate.facade, leafRepositoryItem.facade),
            isFromExplicitAction: true));
      }
    });
    return didUpdate;
  }

  void _onCollectionDataUpdate(
      List<DocumentChange<LeafRepositoryItem<Model>>> documentChanges) {
    if (!_shouldListenToUpdates || documentChanges.isEmpty) {
      return;
    }
    for (final documentChange in documentChanges) {
      var documentSnapshot = documentChange.doc;
      var leafRepositoryItem = documentSnapshot.data();

      if (leafRepositoryItem == null) {
        continue;
      }

      switch (documentChange.type) {
        case DocumentChangeType.added:
          {
            if (!_collectionItems.any((element) =>
                element.documentReference.id ==
                leafRepositoryItem.documentReference.id)) {
              _collectionItems.add(leafRepositoryItem);
              _additionStreamController.add(CollectionItemChangeMetadata(
                  leafRepositoryItem.facade,
                  isFromExplicitAction: false));
            }

            break;
          }
        case DocumentChangeType.removed:
          {
            if (_collectionItems.any((element) =>
                element.documentReference.id == documentSnapshot.id)) {
              _collectionItems.removeWhere((element) =>
                  element.documentReference.id == documentSnapshot.id);
              _deletionStreamController.add(CollectionItemChangeMetadata(
                  leafRepositoryItem.facade,
                  isFromExplicitAction: false));
            }
            break;
          }
        case DocumentChangeType.modified:
          {
            var matchingElementIndex = _collectionItems.indexWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            var collectionItemBeforeUpdate =
                _collectionItems[matchingElementIndex];
            if (collectionItemBeforeUpdate.facade !=
                leafRepositoryItem.facade) {
              _collectionItems[matchingElementIndex] = leafRepositoryItem;
              _updationStreamController.add(CollectionItemChangeMetadata(
                  CollectionItemChangeSet(collectionItemBeforeUpdate.facade,
                      leafRepositoryItem.facade),
                  isFromExplicitAction: false));
            }
            break;
          }
      }
    }
  }

  FutureOr<bool> _tryDeleteCollectionItem(LeafRepositoryItem toDelete) async {
    var didDelete = false;
    await toDelete.documentReference.delete().onError((error, stackTrace) {
      didDelete = false;
    }).then((value) {
      didDelete = true;
    });

    return didDelete;
  }

  FirestoreModelCollection._({
    required this.repositoryItemCreator,
    required CollectionReference<LeafRepositoryItem<Model>>
        typedCollectionReference,
    required Query<LeafRepositoryItem<Model>>? typedQuery,
    required List<LeafRepositoryItem<Model>> collectionItems,
  })  : _typedCollectionReference = typedCollectionReference,
        _collectionItems = collectionItems {
    _shouldListenToUpdates = false;
    _collectionStreamSubscription = (typedQuery ?? typedCollectionReference)
        .snapshots()
        .listen((event) => _onCollectionDataUpdate(event.docChanges));
    _shouldListenToUpdates = true;
  }
}
