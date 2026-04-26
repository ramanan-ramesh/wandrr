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
  StreamSubscription? _collectionStreamSubscription;
  bool _isLoaded = false;

  /// IDs of documents that were explicitly added/deleted/updated by local
  /// actions. The Firestore listener will skip emitting stream events for
  /// these IDs exactly once, since the caller already handles the UI change.
  final Set<String> _pendingExplicitIds = {};
  final StreamController<bool> _isLoadedStreamController =
      StreamController<bool>.broadcast();

  /// Creates a new FirestoreModelCollection instance.
  ///
  /// [collectionReference] - The raw Firestore collection reference
  /// [fromDocumentSnapshot] - Function to convert a DocumentSnapshot to a LeafRepositoryItem
  /// [leafRepositoryItemCreator] - Function to create a LeafRepositoryItem from a Model
  /// [query] - Optional query to filter the collection
  static ModelCollectionModifier<Model> createInstance<Model>(
      CollectionReference collectionReference,
      RepositoryDocument<Model> Function(DocumentSnapshot documentSnapshot)
          fromDocumentSnapshot,
      RepositoryDocument<Model> Function(Model) leafRepositoryItemCreator,
      {Query? query}) {
    // Create typed converter for Firestore
    final typedCollectionReference =
        collectionReference.withConverter<RepositoryDocument<Model>>(
      fromFirestore: (snapshot, _) => fromDocumentSnapshot(snapshot),
      toFirestore: (item, _) => item.toJson(),
    );

    // Apply query with converter if provided
    Query<RepositoryDocument<Model>>? typedQuery;
    if (query != null) {
      typedQuery = query.withConverter<RepositoryDocument<Model>>(
        fromFirestore: (snapshot, _) => fromDocumentSnapshot(snapshot),
        toFirestore: (item, _) => item.toJson(),
      );
    }

    var collection = FirestoreModelCollection<Model>._(
      typedCollectionReference: typedCollectionReference,
      typedQuery: typedQuery,
      repositoryItemCreator: leafRepositoryItemCreator,
      collectionItems: [],
    );
    collection.startListening();
    return collection;
  }

  @override
  Iterable<Model> get collectionItems =>
      _collectionItems.map((collectionItem) => collectionItem.facade);
  final List<RepositoryDocument<Model>> _collectionItems;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Stream<bool> get onLoaded => _isLoadedStreamController.stream;

  @override
  Future dispose() async {
    await _collectionStreamSubscription?.cancel();
    await _isLoadedStreamController.close();
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
  RepositoryDocument<Model> Function(Model model) repositoryItemCreator;

  @override
  Future<Model?> tryAdd(Model toAdd) async {
    var leafRepositoryItem = repositoryItemCreator(toAdd);
    final addResult = await _typedCollectionReference.add(leafRepositoryItem);
    leafRepositoryItem.id = addResult.id;
    // Mark this ID so the listener skips emitting an 'added' stream event
    // (the caller already handles the UI update).
    _pendingExplicitIds.add(addResult.id);
    return leafRepositoryItem.facade;
  }

  @override
  FutureOr<bool> tryDeleteItem(Model toDelete) async {
    var leafRepositoryItem = repositoryItemCreator(toDelete);
    final id = leafRepositoryItem.documentReference.id;
    final didDelete = await _tryDeleteCollectionItem(leafRepositoryItem);
    if (didDelete) {
      _pendingExplicitIds.add(id);
    }
    return didDelete;
  }

  @override
  FutureOr<bool> tryUpdateItem(Model toUpdate) async {
    var leafRepositoryItem = repositoryItemCreator(toUpdate);
    var matchingElementIndex = _collectionItems.indexWhere((repositoryItem) =>
        repositoryItem.documentReference.id ==
        leafRepositoryItem.documentReference.id);
    if (matchingElementIndex == -1) {
      return false;
    }
    var typedDocRef =
        _typedCollectionReference.doc(leafRepositoryItem.documentReference.id);
    try {
      await typedDocRef.set(leafRepositoryItem, SetOptions(merge: true));
    } on Exception {
      return false;
    }
    _pendingExplicitIds.add(leafRepositoryItem.documentReference.id);
    return true;
  }

  void _onCollectionDataUpdate(
      List<DocumentChange<RepositoryDocument<Model>>> documentChanges) {
    if (!_isLoaded) {
      _isLoaded = true;
      _isLoadedStreamController.add(true);
    }
    if (documentChanges.isEmpty) {
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
              // Only broadcast if this wasn't an explicit local action
              if (!_pendingExplicitIds
                  .remove(leafRepositoryItem.documentReference.id)) {
                _additionStreamController.add(CollectionItemChangeMetadata(
                    leafRepositoryItem.facade,
                    isFromExplicitAction: false));
              }
            } else {
              // Doc already present, consume the pending ID if any
              _pendingExplicitIds
                  .remove(leafRepositoryItem.documentReference.id);
            }
            break;
          }
        case DocumentChangeType.removed:
          {
            if (_collectionItems.any((element) =>
                element.documentReference.id == documentSnapshot.id)) {
              _collectionItems.removeWhere((element) =>
                  element.documentReference.id == documentSnapshot.id);
              if (!_pendingExplicitIds.remove(documentSnapshot.id)) {
                _deletionStreamController.add(CollectionItemChangeMetadata(
                    leafRepositoryItem.facade,
                    isFromExplicitAction: false));
              }
            } else {
              _pendingExplicitIds.remove(documentSnapshot.id);
            }
            break;
          }
        case DocumentChangeType.modified:
          {
            var matchingElementIndex = _collectionItems.indexWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            if (matchingElementIndex == -1) break;
            var collectionItemBeforeUpdate =
                _collectionItems[matchingElementIndex];
            _collectionItems[matchingElementIndex] = leafRepositoryItem;
            if (collectionItemBeforeUpdate.facade !=
                    leafRepositoryItem.facade &&
                !_pendingExplicitIds.remove(documentSnapshot.id)) {
              _updationStreamController.add(CollectionItemChangeMetadata(
                  CollectionItemChangeSet(collectionItemBeforeUpdate.facade,
                      leafRepositoryItem.facade),
                  isFromExplicitAction: false));
            } else {
              _pendingExplicitIds.remove(documentSnapshot.id);
            }
            break;
          }
      }
    }
  }

  FutureOr<bool> _tryDeleteCollectionItem(RepositoryDocument toDelete) async {
    try {
      await _typedCollectionReference
          .doc(toDelete.documentReference.id)
          .delete();
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  FirestoreModelCollection._({
    required this.repositoryItemCreator,
    required CollectionReference<RepositoryDocument<Model>>
        typedCollectionReference,
    required this.typedQuery,
    required List<RepositoryDocument<Model>> collectionItems,
  })  : _typedCollectionReference = typedCollectionReference,
        _collectionItems = collectionItems;

  final Query<RepositoryDocument<Model>>? typedQuery;

  void startListening() {
    if (_collectionStreamSubscription != null) {
      return;
    }
    final queryToUse = typedQuery != null
        ? typedQuery!
        : (_typedCollectionReference as Query<RepositoryDocument<Model>>);
    _collectionStreamSubscription = queryToUse
        .snapshots()
        .listen((event) => _onCollectionDataUpdate(event.docChanges));
  }
}
