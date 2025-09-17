import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/store/models/model_collection.dart';

//TODO: Prevent multiple events resulting due to same document change. Also, clone all collection items during external access
class FirestoreModelCollection<Model>
    implements ModelCollectionModifier<Model> {
  final CollectionReference<Object?> _collectionReference;
  bool _shouldListenToUpdates = false;
  late final StreamSubscription _collectionStreamSubscription;
  final FutureOr<LeafRepositoryItem<Model>?> Function(
      DocumentSnapshot documentSnapshot) _fromDocumentSnapshot;

  static Future<ModelCollectionModifier<Model>> createInstance<Model>(
      CollectionReference collectionReference,
      FutureOr<LeafRepositoryItem<Model>> Function(
              DocumentSnapshot documentSnapshot)
          fromDocumentSnapshot,
      LeafRepositoryItem<Model> Function(Model) leafRepositoryItemCreator,
      {Query? query}) async {
    var collectionItems = <LeafRepositoryItem<Model>>[];
    var queryResult = await (query ?? collectionReference).get();
    for (final documentSnapshot in queryResult.docs) {
      var item = await fromDocumentSnapshot(documentSnapshot);
      collectionItems.add(item);
    }
    var modelCollection = FirestoreModelCollection<Model>._(
        collectionReference: collectionReference,
        fromDocumentSnapshot: fromDocumentSnapshot,
        repositoryItemCreator: (x) => leafRepositoryItemCreator(x),
        collectionItems: collectionItems,
        query: query);
    return modelCollection;
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
    _shouldListenToUpdates = true;
    _collectionStreamSubscription.resume();
  }

  @override
  Future<LeafRepositoryItem<Model>?> tryAdd(Model toAdd) async {
    LeafRepositoryItem<Model>? addedCollectionItem;

    await runUpdateTransaction(() async {
      var leafRepositoryItem = repositoryItemCreator(toAdd);
      var addResult =
          await _collectionReference.add(leafRepositoryItem.toJson());

      var addedDocumentSnapshot = await addResult.get();
      var createdEntity = await _fromDocumentSnapshot(addedDocumentSnapshot)
          as LeafRepositoryItem<Model>;
      addedCollectionItem = createdEntity;
      _collectionItems.add(createdEntity);
      _additionStreamController.add(CollectionItemChangeMetadata(
          createdEntity.facade,
          isFromExplicitAction: true));
    });

    return addedCollectionItem;
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
  FutureOr<bool> tryUpdateItem(Model toUpdate) {
    var didUpdate = false;
    runUpdateTransaction(() async {
      var leafRepositoryItem = repositoryItemCreator(toUpdate);
      var matchingElementIndex = _collectionItems.indexWhere((element) =>
          element.documentReference.id ==
          leafRepositoryItem.documentReference.id);
      if (matchingElementIndex == -1) {
        didUpdate = false;
        return;
      }
      var collectionItemBeforeUpdate = _collectionItems[matchingElementIndex];
      didUpdate = await collectionItemBeforeUpdate.tryUpdate(toUpdate);
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

  void _onCollectionDataUpdate(List<DocumentChange> documentChanges) {
    if (!_shouldListenToUpdates || documentChanges.isEmpty) {
      return;
    }
    for (final documentChange in documentChanges) {
      var documentSnapshot = documentChange.doc;
      var leafRepositoryItem =
          _fromDocumentSnapshot(documentSnapshot) as LeafRepositoryItem<Model>;
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
            _collectionItems.removeWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            _deletionStreamController.add(CollectionItemChangeMetadata(
                leafRepositoryItem.facade,
                isFromExplicitAction: false));
            break;
          }
        case DocumentChangeType.modified:
          {
            var matchingElementIndex = _collectionItems.indexWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            var collectionItemBeforeUpdate =
                _collectionItems[matchingElementIndex];
            _collectionItems[matchingElementIndex] = leafRepositoryItem;
            _updationStreamController.add(CollectionItemChangeMetadata(
                CollectionItemChangeSet(collectionItemBeforeUpdate.facade,
                    leafRepositoryItem.facade),
                isFromExplicitAction: false));
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

  FirestoreModelCollection._(
      {required this.repositoryItemCreator,
      required CollectionReference collectionReference,
      required FutureOr<LeafRepositoryItem<Model>?> Function(
              DocumentSnapshot<Object?>)
          fromDocumentSnapshot,
      required List<LeafRepositoryItem<Model>> collectionItems,
      Query? query})
      : _fromDocumentSnapshot = fromDocumentSnapshot,
        _collectionReference = collectionReference,
        _collectionItems = collectionItems {
    //TODO: This fires the first time, even though collectionItems would have been initialized by then
    // TODO: Can we use this platform API ?- collectionReference.withConverter(fromFirestore: fromFirestore, toFirestore: toFirestore)
    _shouldListenToUpdates = false;
    _collectionStreamSubscription = (query ?? collectionReference)
        .snapshots()
        .listen((event) => _onCollectionDataUpdate(event.docChanges));
    _shouldListenToUpdates = true;
  }
}
