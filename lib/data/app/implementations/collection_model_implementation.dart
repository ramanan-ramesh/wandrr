import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/app/models/collection_change_metadata.dart';
import 'package:wandrr/data/app/models/collection_change_set.dart';
import 'package:wandrr/data/app/models/collection_model_facade.dart';
import 'package:wandrr/data/app/models/leaf_repository_item.dart';

class CollectionModelImplementation<Model>
    implements CollectionModelFacade<Model> {
  static Future<CollectionModelImplementation<Model>> createInstance<Model>(
      CollectionReference collectionReference,
      LeafRepositoryItem<Model> Function(DocumentSnapshot documentSnapshot)
          fromDocumentSnapshot,
      LeafRepositoryItem<Model> Function(Model) leafRepositoryItemCreator,
      {Query? query}) async {
    var collectionItems = <LeafRepositoryItem<Model>>[];
    var queryResult = await (query ?? collectionReference).get();
    for (var documentSnapshot in queryResult.docs) {
      var item = fromDocumentSnapshot(documentSnapshot);
      collectionItems.add(item);
    }
    var modelCollection = CollectionModelImplementation<Model>._sync(
        collectionReference: collectionReference,
        fromDocumentSnapshot: fromDocumentSnapshot,
        leafRepositoryItemCreator: (x) => leafRepositoryItemCreator(x),
        collectionItems: collectionItems,
        query: query);
    return modelCollection;
  }

  static Future<CollectionModelImplementation<Model>>
      createInstanceAsync<Model>(
          CollectionReference collectionReference,
          Future<LeafRepositoryItem<Model>> Function(
                  DocumentSnapshot documentSnapshot)
              fromDocumentSnapshot,
          LeafRepositoryItem<Model> Function(Model) repositoryPatternCreator,
          {Query? query}) async {
    var collectionItems = <LeafRepositoryItem<Model>>[];
    var queryResult = await (query ?? collectionReference).get();
    for (var documentSnapshot in queryResult.docs) {
      var item = await fromDocumentSnapshot(documentSnapshot);
      collectionItems.add(item);
    }
    var modelCollection = CollectionModelImplementation<Model>._async(
        collectionReference: collectionReference,
        fromDocumentSnapshot: fromDocumentSnapshot,
        leafRepositoryItemCreator: (x) => repositoryPatternCreator(x),
        collectionItems: collectionItems,
        query: query);
    return modelCollection;
  }

  final CollectionReference<Object?> _collectionReference;
  bool _shouldListenToUpdates = false;
  late StreamSubscription _collectionStreamSubscription;

  final FutureOr<LeafRepositoryItem<Model>?> Function(
      DocumentSnapshot documentSnapshot) fromDocumentSnapshot;

  @override
  List<LeafRepositoryItem<Model>> get collectionItems =>
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
  Stream<CollectionChangeMetadata<LeafRepositoryItem<Model>>>
      get onDocumentAdded => _additionStreamController.stream;
  final StreamController<CollectionChangeMetadata<LeafRepositoryItem<Model>>>
      _additionStreamController = StreamController<
          CollectionChangeMetadata<LeafRepositoryItem<Model>>>.broadcast();

  @override
  Stream<CollectionChangeMetadata<LeafRepositoryItem<Model>>>
      get onDocumentDeleted => _deletionStreamController.stream;
  final StreamController<CollectionChangeMetadata<LeafRepositoryItem<Model>>>
      _deletionStreamController = StreamController<
          CollectionChangeMetadata<LeafRepositoryItem<Model>>>.broadcast();

  @override
  Stream<
          CollectionChangeMetadata<
              CollectionChangeSet<LeafRepositoryItem<Model>>>>
      get onDocumentUpdated => _updationStreamController.stream;
  final StreamController<
          CollectionChangeMetadata<
              CollectionChangeSet<LeafRepositoryItem<Model>>>>
      _updationStreamController = StreamController<
          CollectionChangeMetadata<
              CollectionChangeSet<LeafRepositoryItem<Model>>>>.broadcast();

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
      var repositoryPattern = leafRepositoryItemCreator(toAdd);
      var addResult =
          await _collectionReference.add(repositoryPattern.toJson());

      var addedDocumentSnapshot = await addResult.get();
      var createdEntity = await fromDocumentSnapshot(addedDocumentSnapshot)
          as LeafRepositoryItem<Model>;
      addedCollectionItem = createdEntity;
      _collectionItems.add(createdEntity);
      _additionStreamController
          .add(CollectionChangeMetadata(createdEntity, true));
    });

    return addedCollectionItem;
  }

  @override
  FutureOr<bool> tryDeleteItem(Model toDelete) async {
    var didDelete = false;
    await runUpdateTransaction(() async {
      var repositoryPattern = leafRepositoryItemCreator(toDelete);
      didDelete = await _tryDeleteCollectionItem(repositoryPattern);
      if (didDelete) {
        _deletionStreamController
            .add(CollectionChangeMetadata(repositoryPattern, true));
      }
    });
    return didDelete;
  }

  void tryUpdateList(WriteBatch writeBatch, List<Model> updatedModelItems) {
    var newRepositoryPatterns =
        updatedModelItems.map((e) => leafRepositoryItemCreator(e)).toList();

    //Adds new items to collection. Updates items if already present.
    var itemsToAdd = <LeafRepositoryItem<Model>>[];
    var itemsToDelete = <LeafRepositoryItem<Model>>[];
    for (var indexOfItem = 0;
        indexOfItem < updatedModelItems.length;
        indexOfItem++) {
      var newItem = updatedModelItems[indexOfItem];
      var newItemRepositoryPattern = newRepositoryPatterns[indexOfItem];
      var indexInCurrentCollectionItems = _collectionItems.indexWhere(
          (collectionItem) => collectionItem.id == newItemRepositoryPattern.id);
      if (indexInCurrentCollectionItems >= 0) {
        var collectionItemToUpdate =
            _collectionItems[indexInCurrentCollectionItems];
        if (collectionItemToUpdate.facade != newItem) {
          writeBatch.set(collectionItemToUpdate.documentReference,
              newItemRepositoryPattern.toJson());
          _collectionItems[indexInCurrentCollectionItems] =
              newItemRepositoryPattern;
        }
      } else {
        var newDocument = _collectionReference.doc();
        newItemRepositoryPattern.id = newDocument.id;
        writeBatch.set(newDocument, newItemRepositoryPattern.toJson());
        itemsToAdd.add(newItemRepositoryPattern);
      }
    }

    //Deletes items that are not in new
    for (var item in _collectionItems) {
      if (!newRepositoryPatterns.any((element) => element.id == item.id)) {
        writeBatch.delete(item.documentReference);
        itemsToDelete.add(item);
      }
    }
  }

  void _onCollectionDataUpdate(List<DocumentChange> documentChanges) {
    if (!_shouldListenToUpdates || documentChanges.isEmpty) {
      return;
    }
    for (var documentChange in documentChanges) {
      var documentSnapshot = documentChange.doc;
      var repositoryPattern =
          fromDocumentSnapshot(documentSnapshot) as LeafRepositoryItem<Model>;
      switch (documentChange.type) {
        case DocumentChangeType.added:
          {
            if (!_collectionItems.any((element) =>
                element.documentReference.id ==
                repositoryPattern.documentReference.id)) {
              _collectionItems.add(repositoryPattern);
              _additionStreamController
                  .add(CollectionChangeMetadata(repositoryPattern, false));
            }

            break;
          }
        case DocumentChangeType.removed:
          {
            _collectionItems.removeWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            _deletionStreamController
                .add(CollectionChangeMetadata(repositoryPattern, false));
            break;
          }
        case DocumentChangeType.modified:
          {
            var matchingElementIndex = _collectionItems.indexWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            var collectionItemBeforeUpdate =
                _collectionItems[matchingElementIndex];
            _collectionItems[matchingElementIndex] = repositoryPattern;
            _updationStreamController.add(CollectionChangeMetadata(
                CollectionChangeSet(
                    collectionItemBeforeUpdate, repositoryPattern),
                false));
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
    for (var documentChange in documentChanges) {
      var documentSnapshot = documentChange.doc;
      var repositoryPattern = await fromDocumentSnapshot(documentSnapshot)
          as LeafRepositoryItem<Model>;
      switch (documentChange.type) {
        case DocumentChangeType.added:
          {
            if (!_collectionItems.any((element) =>
                element.documentReference.id ==
                repositoryPattern.documentReference.id)) {
              _collectionItems.add(repositoryPattern);
              _additionStreamController
                  .add(CollectionChangeMetadata(repositoryPattern, false));
            }
            break;
          }
        case DocumentChangeType.removed:
          {
            _collectionItems.removeWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            _deletionStreamController
                .add(CollectionChangeMetadata(repositoryPattern, false));
            break;
          }
        case DocumentChangeType.modified:
          {
            var matchingElementIndex = _collectionItems.indexWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            var collectionItemBeforeUpdate =
                _collectionItems[matchingElementIndex];
            _collectionItems[matchingElementIndex] = repositoryPattern;
            _updationStreamController.add(CollectionChangeMetadata(
                CollectionChangeSet(
                    collectionItemBeforeUpdate, repositoryPattern),
                false));
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

  CollectionModelImplementation._sync(
      {required this.leafRepositoryItemCreator,
      required CollectionReference collectionReference,
      required this.fromDocumentSnapshot,
      required List<LeafRepositoryItem<Model>> collectionItems,
      Query? query})
      : _collectionReference = collectionReference,
        _collectionItems = collectionItems {
    //TODO: This fires the first time, even though collectionItems would have been initialized by then
    // TODO: Can we use this platform API ?- collectionReference.withConverter(fromFirestore: fromFirestore, toFirestore: toFirestore)
    _shouldListenToUpdates = false;
    var streamSubscription = (query ?? collectionReference)
        .snapshots()
        .listen((event) => _onCollectionDataUpdate(event.docChanges));
    _shouldListenToUpdates = true;
    _collectionStreamSubscription = streamSubscription;
  }

  CollectionModelImplementation._async(
      {required this.leafRepositoryItemCreator,
      required CollectionReference collectionReference,
      required this.fromDocumentSnapshot,
      required List<LeafRepositoryItem<Model>> collectionItems,
      Query? query})
      : _collectionReference = collectionReference,
        _collectionItems = collectionItems {
    // TODO: Can we use this platform API ?- collectionReference.withConverter(fromFirestore: fromFirestore, toFirestore: toFirestore)
    _shouldListenToUpdates = false;
    var streamSubscription = (query ?? collectionReference).snapshots().listen(
        (event) async => await _onCollectionDataUpdateAsync(event.docChanges));
    _shouldListenToUpdates = true;
    _collectionStreamSubscription = streamSubscription;
  }
}
