import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/change_set.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_document.dart';
import 'package:wandrr/data/store/models/model_collection.dart';

/// A Firestore-backed collection that manages a set of models with automatic synchronization.
/// Uses Firestore's withConverter API for type-safe document conversion.
class FirestoreModelCollection<TModel>
    implements ModelCollectionModifier<TModel> {
  final CollectionReference<CollectionDocument<TModel>>
      _typedCollectionReference;
  StreamSubscription? _collectionStreamSubscription;
  bool _isLoaded = false;

  /// IDs of documents that were explicitly added/deleted/updated by local
  /// actions. The Firestore listener will skip emitting stream events for
  /// these IDs exactly once, since the caller already handles the UI change.
  final Set<String> _idListFromExplicitActions = {};
  final StreamController<bool> _isLoadedStreamController =
      StreamController<bool>.broadcast();

  /// Creates a new FirestoreModelCollection instance.
  ///
  /// [collectionReference] - The raw Firestore collection reference
  /// [fromDocumentSnapshot] - Function to convert a DocumentSnapshot to a LeafRepositoryItem
  /// [collectionDocumentCreator] - Function to create a LeafRepositoryItem from a Model
  /// [query] - Optional query to filter the collection
  static ModelCollectionModifier<Model> createInstance<Model>(
      CollectionReference collectionReference,
      CollectionDocument<Model> Function(DocumentSnapshot documentSnapshot)
          fromDocumentSnapshot,
      CollectionDocument<Model> Function(Model) collectionDocumentCreator,
      {Query? query}) {
    // Create typed converter for Firestore
    final typedCollectionReference =
        collectionReference.withConverter<CollectionDocument<Model>>(
      fromFirestore: (snapshot, _) => fromDocumentSnapshot(snapshot),
      toFirestore: (item, _) => item.toJson(),
    );

    // Apply query with converter if provided
    Query<CollectionDocument<Model>>? typedQuery;
    if (query != null) {
      typedQuery = query.withConverter<CollectionDocument<Model>>(
        fromFirestore: (snapshot, _) => fromDocumentSnapshot(snapshot),
        toFirestore: (item, _) => item.toJson(),
      );
    }

    final collection = FirestoreModelCollection<Model>._(
      typedCollectionReference: typedCollectionReference,
      typedQuery: typedQuery,
      collectionDocumentCreator: collectionDocumentCreator,
      collectionItems: [],
    );
    collection.startListening();
    return collection;
  }

  @override
  Iterable<TModel> get items =>
      _items.map((collectionItem) => collectionItem.facade);
  final List<CollectionDocument<TModel>> _items;

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
    _items.clear();
  }

  @override
  Stream<CollectionItemChangeMetadata<TModel>> get onDocumentAdded =>
      _additionStreamController.stream;
  final StreamController<CollectionItemChangeMetadata<TModel>>
      _additionStreamController =
      StreamController<CollectionItemChangeMetadata<TModel>>.broadcast();

  @override
  Stream<CollectionItemChangeMetadata<TModel>> get onDocumentDeleted =>
      _deletionStreamController.stream;
  final StreamController<CollectionItemChangeMetadata<TModel>>
      _deletionStreamController =
      StreamController<CollectionItemChangeMetadata<TModel>>.broadcast();

  @override
  Stream<CollectionItemChangeMetadata<Changeset<TModel>>>
      get onDocumentUpdated => _updationStreamController.stream;
  final StreamController<CollectionItemChangeMetadata<Changeset<TModel>>>
      _updationStreamController = StreamController<
          CollectionItemChangeMetadata<Changeset<TModel>>>.broadcast();

  @override
  CollectionDocument<TModel> Function(TModel model) collectionDocumentCreator;

  @override
  Future<TModel?> tryAdd(TModel toAdd) async {
    final collectionDocument = collectionDocumentCreator(toAdd);
    final addResult = await _typedCollectionReference.add(collectionDocument);
    collectionDocument.id = addResult.id;
    // Mark this ID so the listener skips emitting an 'added' stream event
    // (the caller already handles the UI update).
    _idListFromExplicitActions.add(addResult.id);
    return collectionDocument.facade;
  }

  @override
  Future<bool> tryDeleteItem(TModel toDelete) async {
    final collectionDocument = collectionDocumentCreator(toDelete);
    try {
      await _typedCollectionReference
          .doc(collectionDocument.documentReference.id)
          .delete();
      _idListFromExplicitActions.add(collectionDocument.documentReference.id);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  @override
  Future<bool> tryUpdateItem(TModel toUpdate) async {
    final collectionDocument = collectionDocumentCreator(toUpdate);
    final matchingElementIndex = _items.indexWhere((document) =>
        document.documentReference.id ==
        collectionDocument.documentReference.id);
    if (matchingElementIndex == -1) {
      return false;
    }
    try {
      await _typedCollectionReference
          .doc(collectionDocument.documentReference.id)
          .set(collectionDocument, SetOptions(merge: true));
    } on Exception {
      return false;
    }
    _idListFromExplicitActions.add(collectionDocument.documentReference.id);
    return true;
  }

  void _onCollectionDataUpdate(
      List<DocumentChange<CollectionDocument<TModel>>> documentChanges) {
    if (!_isLoaded) {
      _isLoaded = true;
      _isLoadedStreamController.add(true);
    }
    if (documentChanges.isEmpty) {
      return;
    }
    for (final documentChange in documentChanges) {
      final documentSnapshot = documentChange.doc;
      final collectionDocument = documentSnapshot.data();

      if (collectionDocument == null) {
        continue;
      }

      switch (documentChange.type) {
        case DocumentChangeType.added:
          {
            if (!_items.any((element) =>
                element.documentReference.id ==
                collectionDocument.documentReference.id)) {
              _items.add(collectionDocument);
              // Only broadcast if this wasn't an explicit local action
              if (!_idListFromExplicitActions
                  .remove(collectionDocument.documentReference.id)) {
                _additionStreamController.add(CollectionItemChangeMetadata(
                    collectionDocument.facade,
                    isFromExplicitAction: false));
              }
            } else {
              // Doc already present, consume the pending ID if any
              _idListFromExplicitActions
                  .remove(collectionDocument.documentReference.id);
            }
            break;
          }
        case DocumentChangeType.removed:
          {
            if (_items.any((element) =>
                element.documentReference.id == documentSnapshot.id)) {
              _items.removeWhere((element) =>
                  element.documentReference.id == documentSnapshot.id);
              if (!_idListFromExplicitActions.remove(documentSnapshot.id)) {
                _deletionStreamController.add(CollectionItemChangeMetadata(
                    collectionDocument.facade,
                    isFromExplicitAction: false));
              }
            } else {
              _idListFromExplicitActions.remove(documentSnapshot.id);
            }
            break;
          }
        case DocumentChangeType.modified:
          {
            final matchingElementIndex = _items.indexWhere((element) =>
                element.documentReference.id == documentSnapshot.id);
            if (matchingElementIndex == -1) {
              break;
            }
            final collectionItemBeforeUpdate = _items[matchingElementIndex];
            _items[matchingElementIndex] = collectionDocument;
            final hasFacadeChanged =
                collectionItemBeforeUpdate.facade != collectionDocument.facade;
            final wasFromExplicitAction =
                _idListFromExplicitActions.remove(documentSnapshot.id);

            if (hasFacadeChanged && !wasFromExplicitAction) {
              _updationStreamController.add(CollectionItemChangeMetadata(
                  Changeset(collectionItemBeforeUpdate.facade,
                      collectionDocument.facade),
                  isFromExplicitAction: false));
            }
            break;
          }
      }
    }
  }

  FirestoreModelCollection._({
    required this.collectionDocumentCreator,
    required CollectionReference<CollectionDocument<TModel>>
        typedCollectionReference,
    required this.typedQuery,
    required List<CollectionDocument<TModel>> collectionItems,
  })  : _typedCollectionReference = typedCollectionReference,
        _items = collectionItems;

  final Query<CollectionDocument<TModel>>? typedQuery;

  void startListening() {
    if (_collectionStreamSubscription != null) {
      return;
    }
    final queryToUse = typedQuery != null
        ? typedQuery!
        : (_typedCollectionReference as Query<CollectionDocument<TModel>>);
    _collectionStreamSubscription = queryToUse
        .snapshots()
        .listen((event) => _onCollectionDataUpdate(event.docChanges));
  }
}
