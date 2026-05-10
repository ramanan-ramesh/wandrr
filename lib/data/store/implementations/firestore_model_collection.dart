import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/change_set.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_document.dart';
import 'package:wandrr/data/store/models/model_collection.dart';

/// A Firestore-backed collection that manages a set of models with automatic synchronization.
/// Uses Firestore's withConverter API for type-safe document conversion.
///
/// ## Lifecycle
///
/// On construction a Firestore snapshot listener is attached immediately.
/// The very first snapshot populates [_items] and fires [onLoaded] once —
/// **no change-stream events are emitted during this initial load**.
/// Consumers should read [items] after [onLoaded] fires for initial state.
///
/// ## Write operations (`tryAdd` / `tryDeleteItem` / `tryUpdateItem`)
///
/// All three write methods are **synchronous and fire-and-forget**:
/// - They mark the document ID in [_idListFromExplicitActions].
/// - They submit the Firestore write without awaiting it.
/// - They do **not** mutate [_items] or emit any events directly.
///
/// The Firestore snapshot listener is the **sole source of truth** for both
/// local-state mutations and stream emissions.
///
/// ## Event-emission contract (post initial-load only)
///
/// ### [onDocumentAdded]
/// Fires once per `DocumentChangeType.added` echo whose ID is not already
/// in [_items].
/// - `isFromExplicitAction: true`  → triggered by a local [tryAdd] call.
/// - `isFromExplicitAction: false` → remote add from another collaborator.
/// - **Guarantee**: one event per [tryAdd] call (Firestore always echoes
///   new documents as `added`).
///
/// ### [onDocumentDeleted]
/// Fires once per `DocumentChangeType.removed` echo whose ID was in [_items].
/// - `isFromExplicitAction: true`  → triggered by a local [tryDeleteItem].
/// - `isFromExplicitAction: false` → remote delete.
/// - **Guarantee**: one event per [tryDeleteItem] call, provided the document
///   exists in [_items] at the time of the echo.
///
/// ### [onDocumentUpdated]
/// Fires on `DocumentChangeType.modified` echoes, **with different suppression
/// rules depending on the action source**:
/// - **Explicit action** (`isFromExplicitAction: true`): emitted whenever
///   Firestore delivers a `modified` echo **and** the document ID was marked
///   by [tryUpdateItem].  Always emitted regardless of whether
///   `beforeUpdate.facade == afterUpdate.facade`, because a facade-equal write
///   is still a confirmed change that callers need to count.
///   **Important**: Firestore does **not** deliver a `modified` echo for a
///   no-op write (data identical to what is already stored on the server).
///   Callers that track operation completion via `_pendingOperations` must
///   therefore *not* count updates where the entity is unchanged — see
///   `saveAllLegs` which compares each leg against `transitCollection.items`
///   before dispatching and counting an update event.
/// - **Remote change** (`isFromExplicitAction: false`): only emitted when
///   `beforeUpdate.facade != afterUpdate.facade`. Suppresses noise from
///   server-side metadata writes that produce no real data change and avoids
///   unnecessary UI rebuilds.
///
/// ## Implication for `saveAllLegs` / `_pendingOperations`
///
/// `ConflictAwareActionPage` sets `_pendingOperations = operationCount`
/// (the number of bloc events dispatched by `saveAllLegs`) and decrements it
/// on every `UpdatedTripEntity<T>` state.  The counts match only when:
/// - Each [tryAdd]         → exactly 1 `onDocumentAdded`  → 1 decrement.
/// - Each [tryDeleteItem]  → exactly 1 `onDocumentDeleted` → 1 decrement.
/// - Each [tryUpdateItem]  → exactly 1 `onDocumentUpdated` → 1 decrement,
///   but **only when Firestore echoes `modified`**, which requires the written
///   data to differ from what is already stored.  Callers must compare before
///   dispatching; `saveAllLegs` does this via `stored != leg`.
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

    return FirestoreModelCollection<Model>._(
      typedCollectionReference: typedCollectionReference,
      typedReadQuery: typedQuery,
      collectionDocumentCreator: collectionDocumentCreator,
      collectionItems: [],
    );
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
  void tryAdd(TModel toAdd) {
    final collectionDocument = collectionDocumentCreator(toAdd);
    // Generate a local document reference so the ID is known immediately
    // without awaiting Firestore.
    final docRef = _typedCollectionReference.doc();
    collectionDocument.id = docRef.id;
    // Mark ID — the snapshot listener will emit onDocumentAdded with
    // isFromExplicitAction: true when the echo arrives.
    _idListFromExplicitActions.add(docRef.id);
    // Fire-and-forget — no need to await.
    docRef.set(collectionDocument, SetOptions(merge: false));
  }

  @override
  void tryDeleteItem(TModel toDelete) {
    final collectionDocument = collectionDocumentCreator(toDelete);
    final docId = collectionDocument.documentReference.id;
    // Mark ID — the snapshot listener will emit onDocumentDeleted with
    // isFromExplicitAction: true when the echo arrives.
    _idListFromExplicitActions.add(docId);
    // Fire-and-forget — no need to await.
    _typedCollectionReference.doc(docId).delete();
  }

  @override
  void tryUpdateItem(TModel toUpdate) {
    final collectionDocument = collectionDocumentCreator(toUpdate);
    final docId = collectionDocument.documentReference.id;
    if (!_items.any((document) => document.documentReference.id == docId)) {
      return;
    }
    // Mark ID — the snapshot listener will emit onDocumentUpdated with
    // isFromExplicitAction: true when the echo arrives.
    _idListFromExplicitActions.add(docId);
    // Fire-and-forget — no need to await.
    _typedCollectionReference
        .doc(docId)
        .set(collectionDocument, SetOptions(merge: true));
  }

  void _onCollectionDataUpdate(
      List<DocumentChange<CollectionDocument<TModel>>> documentChanges) {
    // Capture whether this is the very first snapshot before mutating state.
    final isInitialLoad = !_isLoaded;

    for (final documentChange in documentChanges) {
      final documentSnapshot = documentChange.doc;
      final collectionDocument = documentSnapshot.data();

      if (collectionDocument == null) {
        continue;
      }

      switch (documentChange.type) {
        case DocumentChangeType.added:
          {
            final docId = collectionDocument.documentReference.id;
            final isExplicit = _idListFromExplicitActions.remove(docId);
            if (!_items.any((e) => e.documentReference.id == docId)) {
              _items.add(collectionDocument);
              // During initial load emit nothing — consumers read from [items]
              // after [onLoaded] fires.
              if (!isInitialLoad) {
                _additionStreamController.add(CollectionItemChangeMetadata(
                    collectionDocument.facade,
                    isFromExplicitAction: isExplicit));
              }
            }
            break;
          }
        case DocumentChangeType.removed:
          {
            final docId = documentSnapshot.id;
            final isExplicit = _idListFromExplicitActions.remove(docId);
            if (_items.any((e) => e.documentReference.id == docId)) {
              _items.removeWhere((e) => e.documentReference.id == docId);
              if (!isInitialLoad) {
                _deletionStreamController.add(CollectionItemChangeMetadata(
                    collectionDocument.facade,
                    isFromExplicitAction: isExplicit));
              }
            }
            break;
          }
        case DocumentChangeType.modified:
          {
            final docId = documentSnapshot.id;
            final matchingElementIndex =
                _items.indexWhere((e) => e.documentReference.id == docId);
            if (matchingElementIndex == -1) {
              break;
            }
            final isExplicit = _idListFromExplicitActions.remove(docId);
            final collectionItemBeforeUpdate = _items[matchingElementIndex];
            _items[matchingElementIndex] = collectionDocument;
            // Always emit for explicit actions so callers tracking
            // _pendingOperations receive exactly one completion signal per
            // tryUpdateItem call (see class-level doc for details).
            // For remote changes, only emit when the facade actually changed
            // to avoid spurious UI rebuilds.
            final shouldEmit = !isInitialLoad &&
                (isExplicit ||
                    collectionItemBeforeUpdate.facade !=
                        collectionDocument.facade);
            if (shouldEmit) {
              _updationStreamController.add(CollectionItemChangeMetadata(
                  Changeset(collectionItemBeforeUpdate.facade,
                      collectionDocument.facade),
                  isFromExplicitAction: isExplicit));
            }
            break;
          }
      }
    }

    // Emit [onLoaded] only after all items from the first snapshot are
    // committed to [_items], so listeners see a fully-populated collection.
    if (isInitialLoad) {
      _isLoaded = true;
      _isLoadedStreamController.add(true);
    }
  }

  FirestoreModelCollection._({
    required CollectionReference<CollectionDocument<TModel>>
        typedCollectionReference,
    required this.collectionDocumentCreator,
    required Query<CollectionDocument<TModel>>? typedReadQuery,
    required List<CollectionDocument<TModel>> collectionItems,
  })  : _typedCollectionReference = typedCollectionReference,
        _items = collectionItems {
    if (_collectionStreamSubscription != null) {
      return;
    }
    final queryToUse = typedReadQuery ??
        (_typedCollectionReference as Query<CollectionDocument<TModel>>);
    _collectionStreamSubscription = queryToUse
        .snapshots()
        .listen((event) => _onCollectionDataUpdate(event.docChanges));
  }
}
