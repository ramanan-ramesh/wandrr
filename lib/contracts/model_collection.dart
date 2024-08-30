import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/contracts/repository_pattern.dart';

class CollectionModificationData<T> {
  T modifiedCollectionItem;
  bool isFromEvent;

  CollectionModificationData(this.modifiedCollectionItem, this.isFromEvent);
}

class UpdateData<T> {
  final T beforeUpdate;
  final T afterUpdate;

  UpdateData(this.beforeUpdate, this.afterUpdate);
}

abstract class EventHandler<T> {
  Stream<CollectionModificationData<RepositoryPattern<T>>> get onDocumentAdded;

  Stream<CollectionModificationData<UpdateData<RepositoryPattern<T>>>>
      get onDocumentUpdated;

  Stream<CollectionModificationData<RepositoryPattern<T>>>
      get onDocumentDeleted;
}

abstract class ModelCollectionFacade<T> implements EventHandler<T>, Dispose {
  String? documentFieldName;
  String? documentFieldValue;

  FutureOr<RepositoryPattern<T>?> Function(DocumentSnapshot documentSnapshot)
      fromDocumentSnapshot;

  ModelCollectionFacade.async(
      {required this.repositoryPatternCreator,
      required CollectionReference collectionReference,
      required this.fromDocumentSnapshot,
      required List<RepositoryPattern<T>> collectionItems,
      this.documentFieldName,
      this.documentFieldValue})
      : _collectionReference = collectionReference,
        _collectionItems = collectionItems {
    // TODO: Can we use this platform API ?- collectionReference.withConverter(fromFirestore: fromFirestore, toFirestore: toFirestore)
    Query query;
    if (documentFieldName != null && documentFieldValue != null) {
      query = collectionReference.where(documentFieldName!,
          arrayContains: documentFieldValue);
    } else {
      query = collectionReference;
    }
    final Timestamp now = Timestamp.fromDate(DateTime.now());
    shouldListenToUpdates = false;
    var streamSubscription = query
        .where('createdAt', isGreaterThan: now)
        .snapshots()
        .listen((event) async =>
            await _onCollectionDataUpdateAsync(event.docChanges));
    shouldListenToUpdates = true;
    _collectionStreamSubscription = streamSubscription;
  }

  ModelCollectionFacade.sync(
      {required this.repositoryPatternCreator,
      required CollectionReference collectionReference,
      required this.fromDocumentSnapshot,
      required List<RepositoryPattern<T>> collectionItems,
      this.documentFieldName,
      this.documentFieldValue})
      : _collectionReference = collectionReference,
        _collectionItems = collectionItems {
    Query query;
    if (documentFieldName != null && documentFieldValue != null) {
      query = collectionReference.where(documentFieldName!,
          arrayContains: documentFieldValue);
    } else {
      query = collectionReference;
    }
    //TODO: This fires the first time, even though collectionItems would have been initialized by then
    // TODO: Can we use this platform API ?- collectionReference.withConverter(fromFirestore: fromFirestore, toFirestore: toFirestore)
    final Timestamp now = Timestamp.fromDate(DateTime.now());
    shouldListenToUpdates = false;
    var streamSubscription = query
        // .where('createdAt', isGreaterThan: now)
        .snapshots()
        .listen((event) => _onCollectionDataUpdate(event.docChanges, now));
    shouldListenToUpdates = true;
    _collectionStreamSubscription = streamSubscription;
  }

  bool shouldListenToUpdates = false;
  late StreamSubscription _collectionStreamSubscription;

  List<RepositoryPattern<T>> get collectionItems => List.from(_collectionItems);
  List<RepositoryPattern<T>> _collectionItems = [];

  CollectionReference<Object?> get collectionReference => _collectionReference;
  final CollectionReference _collectionReference;

  //TODO: Only listen to those documents added after now, in case collectionItems are already initialized.
  @override
  Stream<CollectionModificationData<RepositoryPattern<T>>>
      get onDocumentAdded => _additionStreamController.stream;
  final StreamController<CollectionModificationData<RepositoryPattern<T>>>
      _additionStreamController = StreamController<
          CollectionModificationData<RepositoryPattern<T>>>.broadcast();

  @override
  Stream<CollectionModificationData<UpdateData<RepositoryPattern<T>>>>
      get onDocumentUpdated => _updationStreamController.stream;
  final StreamController<
          CollectionModificationData<UpdateData<RepositoryPattern<T>>>>
      _updationStreamController = StreamController<
          CollectionModificationData<
              UpdateData<RepositoryPattern<T>>>>.broadcast();

  @override
  Stream<CollectionModificationData<RepositoryPattern<T>>>
      get onDocumentDeleted => _deletionStreamController.stream;
  final StreamController<CollectionModificationData<RepositoryPattern<T>>>
      _deletionStreamController = StreamController<
          CollectionModificationData<RepositoryPattern<T>>>.broadcast();

  RepositoryPattern<T> Function(T) repositoryPatternCreator;

  Future<void> runUpdateTransaction(
      Future<void> Function() updateTransaction) async {
    _collectionStreamSubscription.pause();
    shouldListenToUpdates = false;
    await updateTransaction();
    shouldListenToUpdates = true;
    _collectionStreamSubscription.resume();
  }

  Future<RepositoryPattern<T>?> tryAdd(T toAdd) async {
    RepositoryPattern<T>? addedCollectionItem;

    await runUpdateTransaction(() async {
      var repositoryPattern = repositoryPatternCreator(toAdd);
      var addResult = await collectionReference.add(repositoryPattern.toJson());

      var addedDocumentSnapshot = await addResult.get();
      var createdEntity = await fromDocumentSnapshot(addedDocumentSnapshot)
          as RepositoryPattern<T>;
      addedCollectionItem = createdEntity;
      _collectionItems.add(createdEntity);
      _additionStreamController
          .add(CollectionModificationData(createdEntity, true));
    });

    return addedCollectionItem;
  }

  void tryUpdateList(WriteBatch writeBatch, List<T> newItems) {
    var newRepositoryPatterns =
        newItems.map((e) => repositoryPatternCreator(e)).toList();

    //Adds new items to collection. Updates items if already present.
    WriteBatch writeBatch = FirebaseFirestore.instance.batch();
    var itemsToAdd = <RepositoryPattern<T>>[];
    var itemsToDelete = <RepositoryPattern<T>>[];
    for (var indexOfItem = 0; indexOfItem < newItems.length; indexOfItem++) {
      var newItem = newItems[indexOfItem];
      var newItemRepositoryPattern = newRepositoryPatterns[indexOfItem];
      var indexInCurrentCollectionItems = _collectionItems.indexWhere(
          (collectionItem) => collectionItem.id == newItemRepositoryPattern.id);
      if (indexInCurrentCollectionItems >= 0) {
        var collectionItemToUpdate =
            _collectionItems[indexInCurrentCollectionItems];
        if (collectionItemToUpdate.clone() != newItem) {
          writeBatch.set(collectionItemToUpdate.documentReference,
              newItemRepositoryPattern.toJson());
          _collectionItems[indexInCurrentCollectionItems] =
              newItemRepositoryPattern;
        }
      } else {
        var newDocument = collectionReference.doc();
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

  FutureOr<bool> tryDeleteItem(T toDelete) async {
    var didDelete = false;
    await runUpdateTransaction(() async {
      var repositoryPattern = repositoryPatternCreator(toDelete);
      didDelete = await _tryDeleteCollectionItem(repositoryPattern);
      if (didDelete) {
        _deletionStreamController
            .add(CollectionModificationData(repositoryPattern, true));
      }
    });
    return didDelete;
  }

  void _onCollectionDataUpdate(
      List<DocumentChange> documentChanges, Timestamp observationStartTime) {
    if (!shouldListenToUpdates || documentChanges.isEmpty) {
      return;
    }
    for (var documentChange in documentChanges) {
      var documentSnapshot = documentChange.doc;
      var repositoryPattern =
          fromDocumentSnapshot(documentSnapshot) as RepositoryPattern<T>;
      switch (documentChange.type) {
        case DocumentChangeType.added:
          {
            if (!_collectionItems.any((element) =>
                element.documentReference.id ==
                repositoryPattern.documentReference.id)) {
              _collectionItems.add(repositoryPattern);
              _additionStreamController
                  .add(CollectionModificationData(repositoryPattern, false));
            }

            break;
          }
        case DocumentChangeType.removed:
          {
            _collectionItems.removeWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            _deletionStreamController
                .add(CollectionModificationData(repositoryPattern, false));
            break;
          }
        case DocumentChangeType.modified:
          {
            var matchingElementIndex = _collectionItems.indexWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            var collectionItemBeforeUpdate =
                _collectionItems[matchingElementIndex];
            _collectionItems[matchingElementIndex] = repositoryPattern;
            _updationStreamController.add(CollectionModificationData(
                UpdateData(collectionItemBeforeUpdate, repositoryPattern),
                false));
            break;
          }
      }
    }
  }

  Future _onCollectionDataUpdateAsync(
      List<DocumentChange> documentChanges) async {
    if (!shouldListenToUpdates || documentChanges.isEmpty) {
      return;
    }
    for (var documentChange in documentChanges) {
      var documentSnapshot = documentChange.doc;
      var repositoryPattern =
          await fromDocumentSnapshot(documentSnapshot) as RepositoryPattern<T>;
      switch (documentChange.type) {
        case DocumentChangeType.added:
          {
            if (!_collectionItems.any((element) =>
                element.documentReference.id ==
                repositoryPattern.documentReference.id)) {
              _collectionItems.add(repositoryPattern);
              _additionStreamController
                  .add(CollectionModificationData(repositoryPattern, false));
            }
            break;
          }
        case DocumentChangeType.removed:
          {
            _collectionItems.removeWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            _deletionStreamController
                .add(CollectionModificationData(repositoryPattern, false));
            break;
          }
        case DocumentChangeType.modified:
          {
            var matchingElementIndex = _collectionItems.indexWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            var collectionItemBeforeUpdate =
                _collectionItems[matchingElementIndex];
            _collectionItems[matchingElementIndex] = repositoryPattern;
            _updationStreamController.add(CollectionModificationData(
                UpdateData(collectionItemBeforeUpdate, repositoryPattern),
                false));
          }
      }
    }
  }

  @override
  Future dispose() async {
    await _collectionStreamSubscription.cancel();
    await _updationStreamController.close();
    await _deletionStreamController.close();
    await _additionStreamController.close();
    _collectionItems.clear();
  }

  FutureOr<bool> _tryDeleteCollectionItem(RepositoryPattern toDelete) async {
    var didDelete = false;
    toDelete.documentReference.delete().then((value) => didDelete = true);

    return didDelete;
  }
}

class ModelCollection<T> extends ModelCollectionFacade<T> {
  ModelCollection.async(
      {required CollectionReference collectionReference,
      required Future<RepositoryPattern<T>> Function(
              DocumentSnapshot documentSnapshot)
          fromDocumentSnapshot,
      required RepositoryPattern<T> Function(T) repositoryPatternCreator,
      required List<RepositoryPattern<T>> collectionItems,
      String? documentFieldName,
      String? documentFieldValue})
      : super.async(
            repositoryPatternCreator: repositoryPatternCreator,
            collectionReference: collectionReference,
            fromDocumentSnapshot: fromDocumentSnapshot,
            collectionItems: collectionItems,
            documentFieldName: documentFieldName,
            documentFieldValue: documentFieldValue);

  ModelCollection.sync(
      {required CollectionReference collectionReference,
      required RepositoryPattern<T> Function(DocumentSnapshot documentSnapshot)
          fromDocumentSnapshot,
      required RepositoryPattern<T> Function(T) repositoryPatternCreator,
      required List<RepositoryPattern<T>> collectionItems,
      String? documentFieldName,
      String? documentFieldValue})
      : super.sync(
            repositoryPatternCreator: repositoryPatternCreator,
            collectionReference: collectionReference,
            fromDocumentSnapshot: fromDocumentSnapshot,
            collectionItems: collectionItems,
            documentFieldName: documentFieldName,
            documentFieldValue: documentFieldValue);

  static Future<ModelCollection<T>> createInstanceAsync<T>(
      CollectionReference collectionReference,
      Future<RepositoryPattern<T>> Function(DocumentSnapshot documentSnapshot)
          fromDocumentSnapshot,
      RepositoryPattern<T> Function(T) repositoryPatternCreator,
      {String? documentFieldName,
      String? documentFieldValue}) async {
    var collectionItems = <RepositoryPattern<T>>[];
    Query query;
    if (documentFieldName != null && documentFieldValue != null) {
      query = collectionReference.where(documentFieldName,
          arrayContains: documentFieldValue);
    } else {
      query = collectionReference;
    }
    var queryResult = await query.get();
    for (var documentSnapshot in queryResult.docs) {
      var item = await fromDocumentSnapshot(documentSnapshot);
      collectionItems.add(item);
    }
    var modelCollection = ModelCollection<T>.async(
        collectionReference: collectionReference,
        fromDocumentSnapshot: fromDocumentSnapshot,
        repositoryPatternCreator: (x) => repositoryPatternCreator(x),
        collectionItems: collectionItems,
        documentFieldValue: documentFieldValue);
    return modelCollection;
  }

  static Future<ModelCollection<T>> createInstance<T>(
      CollectionReference collectionReference,
      RepositoryPattern<T> Function(DocumentSnapshot documentSnapshot)
          fromDocumentSnapshot,
      RepositoryPattern<T> Function(T) repositoryPatternCreator,
      {String? documentFieldName,
      String? documentFieldValue}) async {
    var collectionItems = <RepositoryPattern<T>>[];
    Query query;
    if (documentFieldName != null && documentFieldValue != null) {
      query = collectionReference.where(documentFieldName,
          arrayContains: documentFieldValue);
    } else {
      query = collectionReference;
    }
    var queryResult = await query.get();
    for (var documentSnapshot in queryResult.docs) {
      var item = fromDocumentSnapshot(documentSnapshot);
      collectionItems.add(item);
    }
    var modelCollection = ModelCollection<T>.sync(
        collectionReference: collectionReference,
        fromDocumentSnapshot: fromDocumentSnapshot,
        repositoryPatternCreator: (x) => repositoryPatternCreator(x),
        collectionItems: collectionItems,
        documentFieldValue: documentFieldValue);
    return modelCollection;
  }
}
