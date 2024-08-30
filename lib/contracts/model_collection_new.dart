// import 'dart:async';
// import 'dart:collection';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:wandrr/contracts/repository_pattern.dart';
//
// class CollectionModificationData<T> {
//   T modifiedCollectionItem;
//   bool isFromEvent;
//
//   CollectionModificationData(this.modifiedCollectionItem, this.isFromEvent);
// }
//
// class UpdateData<T> {
//   final T beforeUpdate;
//   final T afterUpdate;
//
//   UpdateData(this.beforeUpdate, this.afterUpdate);
// }
//
// class CollectionUpdateData<T> {
//   final List<CollectionModificationData<RepositoryPattern<T>>> documentsAdded;
//   final List<CollectionModificationData<RepositoryPattern<T>>> documentsDeleted;
//   final List<CollectionModificationData<UpdateData<RepositoryPattern<T>>>>
//       documentsUpdated;
//
//   CollectionUpdateData(
//       this.documentsAdded, this.documentsDeleted, this.documentsUpdated);
// }
//
// abstract class FacadeEventHandler<T> extends ListBase<T> implements Dispose {
//   Stream<CollectionUpdateData<T>> get onDocumentsChanged;
//
//   static Future<FacadeEventHandler<T>> createInstance<T>(
//       CollectionReference collectionReference,
//       RepositoryPattern<T> Function(DocumentSnapshot documentSnapshot)
//           fromDocumentSnapshot,
//       RepositoryPattern<T> Function(T) repositoryPatternCreator,
//       {String? documentFieldName,
//       String? documentFieldValue}) async {
//     var collectionItems = <RepositoryPattern<T>>[];
//     Query query;
//     if (documentFieldName != null && documentFieldValue != null) {
//       query = collectionReference.where(documentFieldName,
//           arrayContains: documentFieldValue);
//     } else {
//       query = collectionReference;
//     }
//     var queryResult = await query.get();
//     for (var documentSnapshot in queryResult.docs) {
//       var item = fromDocumentSnapshot(documentSnapshot);
//       collectionItems.add(item);
//     }
//     var modelCollection = _ModelCollection<T>.sync(
//         collectionReference: collectionReference,
//         fromDocumentSnapshot: fromDocumentSnapshot,
//         repositoryPatternCreator: (x) => repositoryPatternCreator(x),
//         collectionItems: collectionItems,
//         documentFieldValue: documentFieldValue,
//         documentFieldName: documentFieldName);
//     return modelCollection;
//   }
//
//   static Future<_ModelCollection<T>> createInstanceAsync<T>(
//       CollectionReference collectionReference,
//       Future<RepositoryPattern<T>> Function(DocumentSnapshot documentSnapshot)
//           fromDocumentSnapshot,
//       RepositoryPattern<T> Function(T) repositoryPatternCreator,
//       {String? documentFieldName,
//       String? documentFieldValue}) async {
//     var collectionItems = <RepositoryPattern<T>>[];
//     Query query;
//     if (documentFieldName != null && documentFieldValue != null) {
//       query = collectionReference.where(documentFieldName,
//           arrayContains: documentFieldValue);
//     } else {
//       query = collectionReference;
//     }
//     var queryResult = await query.get();
//     for (var documentSnapshot in queryResult.docs) {
//       var item = await fromDocumentSnapshot(documentSnapshot);
//       collectionItems.add(item);
//     }
//     var modelCollection = _ModelCollection<T>.async(
//         collectionReference: collectionReference,
//         fromDocumentSnapshot: fromDocumentSnapshot,
//         repositoryPatternCreator: (x) => repositoryPatternCreator(x),
//         collectionItems: collectionItems,
//         documentFieldValue: documentFieldValue);
//     return modelCollection;
//   }
// }
//
// class _ModelCollection<T> extends FacadeEventHandler<T> {
//   String? documentFieldName;
//   String? documentFieldValue;
//   final FutureOr<RepositoryPattern<T>?> Function(
//       DocumentSnapshot documentSnapshot) fromDocumentSnapshot;
//
//   final CollectionReference collectionReference;
//
//   final RepositoryPattern<T> Function(T) repositoryPatternCreator;
//
//   bool shouldListenToUpdates = false;
//
//   StreamSubscription _collectionUpdateStreamSubscription;
//
//   @override
//   Stream<CollectionUpdateData<T>> get onDocumentsChanged =>
//       _collectionUpdateStreamController.stream;
//   final StreamController<CollectionUpdateData<T>>
//       _collectionUpdateStreamController =
//       StreamController<CollectionUpdateData<T>>.broadcast();
//
//   @override
//   List<RepositoryPattern<T>> get collectionItems => List.from(_collectionItems);
//   List<RepositoryPattern<T>> _collectionItems = [];
//
//   _ModelCollection.sync(
//       {required this.collectionReference,
//       required this.fromDocumentSnapshot,
//       required this.repositoryPatternCreator,
//       required List<RepositoryPattern<T>> collectionItems,
//       required this.documentFieldName,
//       required this.documentFieldValue})
//       : _collectionItems = collectionItems {
//     Query query;
//     if (documentFieldName != null && documentFieldValue != null) {
//       query = collectionReference.where(documentFieldName!,
//           arrayContains: documentFieldValue);
//     } else {
//       query = collectionReference;
//     }
//     //TODO: This fires the first time, even though collectionItems would have been initialized by then
//     // TODO: Can we use this platform API ?- collectionReference.withConverter(fromFirestore: fromFirestore, toFirestore: toFirestore)
//     final Timestamp now = Timestamp.fromDate(DateTime.now());
//     shouldListenToUpdates = false;
//     var streamSubscription = query
//         // .where('createdAt', isGreaterThan: now)
//         .snapshots()
//         .listen((event) => _onCollectionDataUpdate(event.docChanges, now));
//     shouldListenToUpdates = true;
//     _collectionUpdateStreamSubscription = streamSubscription;
//   }
//
//   _ModelCollection.async(
//       {required this.repositoryPatternCreator,
//       required CollectionReference collectionReference,
//       required this.fromDocumentSnapshot,
//       required List<RepositoryPattern<T>> collectionItems,
//       this.documentFieldName,
//       this.documentFieldValue})
//       : _collectionItems = collectionItems {
//     // TODO: Can we use this platform API ?- collectionReference.withConverter(fromFirestore: fromFirestore, toFirestore: toFirestore)
//     Query query;
//     if (documentFieldName != null && documentFieldValue != null) {
//       query = collectionReference.where(documentFieldName!,
//           arrayContains: documentFieldValue);
//     } else {
//       query = collectionReference;
//     }
//     final Timestamp now = Timestamp.fromDate(DateTime.now());
//     shouldListenToUpdates = false;
//     var streamSubscription = query
//         .where('createdAt', isGreaterThan: now)
//         .snapshots()
//         .listen((event) async =>
//             await _onCollectionDataUpdate(event.docChanges, now));
//     shouldListenToUpdates = true;
//     _collectionUpdateStreamSubscription = streamSubscription;
//   }
//
//   void _onCollectionDataUpdate(List<DocumentChange> documentChanges,
//       Timestamp observationStartTime) async {
//     if (!shouldListenToUpdates || documentChanges.isEmpty) {
//       return;
//     }
//     var updatedDocuments = documentChanges.where(
//         (documentChange) => documentChange.type == DocumentChangeType.modified);
//     var addedDocuments = documentChanges.where(
//         (documentChange) => documentChange.type == DocumentChangeType.added);
//     var removedDocuments = documentChanges.where(
//         (documentChange) => documentChange.type == DocumentChangeType.removed);
//
//     var updatedCollectionItems =
//         <CollectionModificationData<UpdateData<RepositoryPattern<T>>>>[];
//     for (var documentChange in updatedDocuments) {
//       var documentSnapshot = documentChange.doc;
//       var repositoryPattern =
//           await fromDocumentSnapshot(documentSnapshot) as RepositoryPattern<T>;
//       var matchingElementIndex = _collectionItems.indexWhere(
//           (element) => element.documentReference.id == documentSnapshot.id);
//       var collectionItemBeforeUpdate = _collectionItems[matchingElementIndex];
//       _collectionItems[matchingElementIndex] = repositoryPattern;
//       var collectionModificationData = CollectionModificationData(
//           UpdateData(collectionItemBeforeUpdate, repositoryPattern), false);
//       updatedCollectionItems.add(collectionModificationData);
//     }
//
//     var addedCollectionItems =
//         <CollectionModificationData<RepositoryPattern<T>>>[];
//     for (var documentChange in addedDocuments) {
//       var documentSnapshot = documentChange.doc;
//       var repositoryPattern =
//           await fromDocumentSnapshot(documentSnapshot) as RepositoryPattern<T>;
//       if (!_collectionItems.any((element) =>
//           element.documentReference.id ==
//           repositoryPattern.documentReference.id)) {
//         _collectionItems.add(repositoryPattern);
//         var collectionModificationData =
//             CollectionModificationData(repositoryPattern, false);
//         addedCollectionItems.add(collectionModificationData);
//       }
//     }
//
//     var removedCollectionItems =
//         <CollectionModificationData<RepositoryPattern<T>>>[];
//     for (var documentChange in removedDocuments) {
//       var documentSnapshot = documentChange.doc;
//       var repositoryPattern =
//           await fromDocumentSnapshot(documentSnapshot) as RepositoryPattern<T>;
//       var collectionModificationData =
//           CollectionModificationData(repositoryPattern, false);
//       _collectionItems
//           .removeWhere((element) => element.id == documentSnapshot.id);
//       removedCollectionItems.add(collectionModificationData);
//     }
//
//     if (removedCollectionItems.isNotEmpty ||
//         addedCollectionItems.isNotEmpty ||
//         updatedCollectionItems.isNotEmpty) {
//       var collectionUpdateData = CollectionUpdateData(
//           addedCollectionItems, removedCollectionItems, updatedCollectionItems);
//       _collectionUpdateStreamController.add(collectionUpdateData);
//     }
//   }
//
//   void _onCollectionDataUpdateAsync(List<DocumentChange> documentChanges,
//       Timestamp observationStartTime) async {
//     if (!shouldListenToUpdates || documentChanges.isEmpty) {
//       return;
//     }
//     var updatedDocuments = documentChanges.where(
//         (documentChange) => documentChange.type == DocumentChangeType.modified);
//     var addedDocuments = documentChanges.where(
//         (documentChange) => documentChange.type == DocumentChangeType.added);
//     var removedDocuments = documentChanges.where(
//         (documentChange) => documentChange.type == DocumentChangeType.removed);
//
//     var updatedCollectionItems =
//         <CollectionModificationData<UpdateData<RepositoryPattern<T>>>>[];
//     for (var documentChange in updatedDocuments) {
//       var documentSnapshot = documentChange.doc;
//       var repositoryPattern =
//           await fromDocumentSnapshot(documentSnapshot) as RepositoryPattern<T>;
//       var matchingElementIndex = _collectionItems.indexWhere(
//           (element) => element.documentReference.id == documentSnapshot.id);
//       var collectionItemBeforeUpdate = _collectionItems[matchingElementIndex];
//       _collectionItems[matchingElementIndex] = repositoryPattern;
//       var collectionModificationData = CollectionModificationData(
//           UpdateData(collectionItemBeforeUpdate, repositoryPattern), false);
//       updatedCollectionItems.add(collectionModificationData);
//     }
//
//     var addedCollectionItems =
//         <CollectionModificationData<RepositoryPattern<T>>>[];
//     for (var documentChange in addedDocuments) {
//       var documentSnapshot = documentChange.doc;
//       var repositoryPattern =
//           await fromDocumentSnapshot(documentSnapshot) as RepositoryPattern<T>;
//       if (!_collectionItems.any((element) =>
//           element.documentReference.id ==
//           repositoryPattern.documentReference.id)) {
//         _collectionItems.add(repositoryPattern);
//         var collectionModificationData =
//             CollectionModificationData(repositoryPattern, false);
//         addedCollectionItems.add(collectionModificationData);
//       }
//     }
//
//     var removedCollectionItems =
//         <CollectionModificationData<RepositoryPattern<T>>>[];
//     for (var documentChange in removedDocuments) {
//       var documentSnapshot = documentChange.doc;
//       var repositoryPattern =
//           await fromDocumentSnapshot(documentSnapshot) as RepositoryPattern<T>;
//       var collectionModificationData =
//           CollectionModificationData(repositoryPattern, false);
//       _collectionItems
//           .removeWhere((element) => element.id == documentSnapshot.id);
//       removedCollectionItems.add(collectionModificationData);
//     }
//
//     if (removedCollectionItems.isNotEmpty ||
//         addedCollectionItems.isNotEmpty ||
//         updatedCollectionItems.isNotEmpty) {
//       var collectionUpdateData = CollectionUpdateData(
//           addedCollectionItems, removedCollectionItems, updatedCollectionItems);
//       _collectionUpdateStreamController.add(collectionUpdateData);
//     }
//   }
// }
