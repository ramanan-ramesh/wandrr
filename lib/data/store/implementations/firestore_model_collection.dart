import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/store/models/model_collection.dart';

//TODO: Prevent multiple events resulting due to same document change. Also, clone all collection items during external access
class FirestoreModelCollection<Model> implements ModelCollectionFacade<Model> {
  final CollectionReference<Object?> _collectionReference;
  bool _shouldListenToUpdates = false;
  late StreamSubscription _collectionStreamSubscription;
  final FutureOr<LeafRepositoryItem<Model>?> Function(
      DocumentSnapshot documentSnapshot) _fromDocumentSnapshot;

  static Future<FirestoreModelCollection<Model>> createInstance<Model>(
      CollectionReference collectionReference,
      LeafRepositoryItem<Model> Function(DocumentSnapshot documentSnapshot)
          fromDocumentSnapshot,
      LeafRepositoryItem<Model> Function(Model) leafRepositoryItemCreator,
      {Query? query}) async {
    var collectionItems = <LeafRepositoryItem<Model>>[];
    var queryResult = await (query ?? collectionReference).get();
    for (final documentSnapshot in queryResult.docs) {
      var item = fromDocumentSnapshot(documentSnapshot);
      collectionItems.add(item);
    }
    var modelCollection = FirestoreModelCollection<Model>._sync(
        collectionReference: collectionReference,
        fromDocumentSnapshot: fromDocumentSnapshot,
        leafRepositoryItemCreator: (x) => leafRepositoryItemCreator(x),
        collectionItems: collectionItems,
        query: query);
    return modelCollection;
  }

  static Future<FirestoreModelCollection<Model>> createInstanceAsync<Model>(
      CollectionReference collectionReference,
      Future<LeafRepositoryItem<Model>> Function(
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
    var modelCollection = FirestoreModelCollection<Model>._async(
        collectionReference: collectionReference,
        fromDocumentSnapshot: fromDocumentSnapshot,
        leafRepositoryItemCreator: (x) => leafRepositoryItemCreator(x),
        collectionItems: collectionItems,
        query: query);
    return modelCollection;
  }

  @override
  Iterable<LeafRepositoryItem<Model>> get collectionItems =>
      List.from(_collectionItems);
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
  Stream<CollectionItemChangeMetadata<LeafRepositoryItem<Model>>>
      get onDocumentAdded => _additionStreamController.stream;
  final StreamController<
          CollectionItemChangeMetadata<LeafRepositoryItem<Model>>>
      _additionStreamController = StreamController<
          CollectionItemChangeMetadata<LeafRepositoryItem<Model>>>.broadcast();

  @override
  Stream<CollectionItemChangeMetadata<LeafRepositoryItem<Model>>>
      get onDocumentDeleted => _deletionStreamController.stream;
  final StreamController<
          CollectionItemChangeMetadata<LeafRepositoryItem<Model>>>
      _deletionStreamController = StreamController<
          CollectionItemChangeMetadata<LeafRepositoryItem<Model>>>.broadcast();

  @override
  Stream<
          CollectionItemChangeMetadata<
              CollectionItemChangeSet<LeafRepositoryItem<Model>>>>
      get onDocumentUpdated => _updationStreamController.stream;
  final StreamController<
          CollectionItemChangeMetadata<
              CollectionItemChangeSet<LeafRepositoryItem<Model>>>>
      _updationStreamController = StreamController<
          CollectionItemChangeMetadata<
              CollectionItemChangeSet<LeafRepositoryItem<Model>>>>.broadcast();

  @override
  LeafRepositoryItem<Model> Function(Model model) leafRepositoryItemCreator;

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
      var leafRepositoryItem = leafRepositoryItemCreator(toAdd);
      var addResult =
          await _collectionReference.add(leafRepositoryItem.toJson());

      var addedDocumentSnapshot = await addResult.get();
      var createdEntity = await _fromDocumentSnapshot(addedDocumentSnapshot)
          as LeafRepositoryItem<Model>;
      addedCollectionItem = createdEntity;
      _collectionItems.add(createdEntity);
      _additionStreamController.add(CollectionItemChangeMetadata(createdEntity,
          isFromExplicitAction: true));
    });

    return addedCollectionItem;
  }

  @override
  FutureOr<bool> tryDeleteItem(Model toDelete) async {
    var didDelete = false;
    await runUpdateTransaction(() async {
      var leafRepositoryItem = leafRepositoryItemCreator(toDelete);
      didDelete = await _tryDeleteCollectionItem(leafRepositoryItem);
      if (didDelete) {
        _deletionStreamController.add(CollectionItemChangeMetadata(
            leafRepositoryItem,
            isFromExplicitAction: true));
      }
    });
    return didDelete;
  }

  void tryUpdateList(WriteBatch writeBatch, List<Model> updatedModelItems) {
    var newLeafRepositoryItems =
        updatedModelItems.map((e) => leafRepositoryItemCreator(e)).toList();

    //Adds new items to collection. Updates items if already present.
    var itemsToAdd = <LeafRepositoryItem<Model>>[];
    var itemsToDelete = <LeafRepositoryItem<Model>>[];
    for (var indexOfItem = 0;
        indexOfItem < updatedModelItems.length;
        indexOfItem++) {
      var newItem = updatedModelItems[indexOfItem];
      var newleafRepositoryItem = newLeafRepositoryItems[indexOfItem];
      var indexInCurrentCollectionItems = _collectionItems.indexWhere(
          (collectionItem) => collectionItem.id == newleafRepositoryItem.id);
      if (indexInCurrentCollectionItems >= 0) {
        var collectionItemToUpdate =
            _collectionItems[indexInCurrentCollectionItems];
        if (collectionItemToUpdate.facade != newItem) {
          writeBatch.set(collectionItemToUpdate.documentReference,
              newleafRepositoryItem.toJson());
          _collectionItems[indexInCurrentCollectionItems] =
              newleafRepositoryItem;
        }
      } else {
        var newDocument = _collectionReference.doc();
        newleafRepositoryItem.id = newDocument.id;
        writeBatch.set(newDocument, newleafRepositoryItem.toJson());
        itemsToAdd.add(newleafRepositoryItem);
      }
    }

    //Deletes items that are not in new
    for (final item in _collectionItems) {
      if (!newLeafRepositoryItems.any((element) => element.id == item.id)) {
        writeBatch.delete(item.documentReference);
        itemsToDelete.add(item);
      }
    }
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
                  leafRepositoryItem,
                  isFromExplicitAction: false));
            }

            break;
          }
        case DocumentChangeType.removed:
          {
            _collectionItems.removeWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            _deletionStreamController.add(CollectionItemChangeMetadata(
                leafRepositoryItem,
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
                CollectionItemChangeSet(
                    collectionItemBeforeUpdate, leafRepositoryItem),
                isFromExplicitAction: false));
            break;
          }
      }
    }
  }

  Future _onCollectionDataUpdateAsync(
      List<DocumentChange> documentChanges) async {
    if (!_shouldListenToUpdates || documentChanges.isEmpty) {
      return;
    }
    for (final documentChange in documentChanges) {
      var documentSnapshot = documentChange.doc;
      var leafRepositoryItem = await _fromDocumentSnapshot(documentSnapshot)
          as LeafRepositoryItem<Model>;
      switch (documentChange.type) {
        case DocumentChangeType.added:
          {
            if (!_collectionItems.any((element) =>
                element.documentReference.id ==
                leafRepositoryItem.documentReference.id)) {
              _collectionItems.add(leafRepositoryItem);
              _additionStreamController.add(CollectionItemChangeMetadata(
                  leafRepositoryItem,
                  isFromExplicitAction: false));
            }
            break;
          }
        case DocumentChangeType.removed:
          {
            _collectionItems.removeWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            _deletionStreamController.add(CollectionItemChangeMetadata(
                leafRepositoryItem,
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
                CollectionItemChangeSet(
                    collectionItemBeforeUpdate, leafRepositoryItem),
                isFromExplicitAction: false));
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

  FirestoreModelCollection._sync(
      {required this.leafRepositoryItemCreator,
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

  FirestoreModelCollection._async(
      {required this.leafRepositoryItemCreator,
      required CollectionReference collectionReference,
      required FutureOr<LeafRepositoryItem<Model>?> Function(
              DocumentSnapshot<Object?>)
          fromDocumentSnapshot,
      required List<LeafRepositoryItem<Model>> collectionItems,
      Query? query})
      : _fromDocumentSnapshot = fromDocumentSnapshot,
        _collectionReference = collectionReference,
        _collectionItems = collectionItems {
    // TODO: Can we use this platform API ?- collectionReference.withConverter(fromFirestore: fromFirestore, toFirestore: toFirestore)
    _shouldListenToUpdates = false;
    _collectionStreamSubscription = (query ?? collectionReference)
        .snapshots()
        .listen((event) async =>
            await _onCollectionDataUpdateAsync(event.docChanges));
    _shouldListenToUpdates = true;
  }
}
