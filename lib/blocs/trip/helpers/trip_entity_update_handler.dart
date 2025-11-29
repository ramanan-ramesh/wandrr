import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Handles CRUD operations for trip entities
class TripEntityUpdateHandler {
  /// Processes and emits state for a trip entity update
  Future<void> updateTripEntityAndEmitState<E extends TripEntity>({
    required E tripEntity,
    required DataState requestedDataState,
    required ModelCollectionModifier<E> modelCollection,
    required Emitter<TripManagementState> emit,
  }) async {
    switch (requestedDataState) {
      case DataState.newUiEntry:
        _emitNewUiEntry(tripEntity, emit);

      case DataState.create:
        await _handleCreate(tripEntity, modelCollection, emit);

      case DataState.delete:
        await _handleDelete(tripEntity, modelCollection, emit);

      case DataState.update:
        await _handleUpdate(tripEntity, modelCollection, emit);

      case DataState.select:
        _handleSelect(tripEntity, modelCollection, emit);

      default:
        break;
    }
  }

  /// Emits a new UI entry state
  void _emitNewUiEntry<E extends TripEntity>(
      E tripEntity, Emitter<TripManagementState> emit) {
    emit(UpdatedTripEntity<E>.createdNewUiEntry(
      tripEntity: tripEntity,
      isOperationSuccess: true,
    ));
  }

  /// Handles the create operation
  Future<void> _handleCreate<E extends TripEntity>(
    E tripEntity,
    ModelCollectionModifier<E> modelCollection,
    Emitter<TripManagementState> emit,
  ) async {
    if (tripEntity.id != null) return;

    final addedEntity = await modelCollection.tryAdd(tripEntity);
    if (addedEntity != null) {
      emit(UpdatedTripEntity<E>.created(
        tripEntityModificationData: CollectionItemChangeMetadata(
          addedEntity.facade,
          isFromExplicitAction: true,
        ),
        isOperationSuccess: true,
      ));
    } else {
      emit(UpdatedTripEntity<E>.created(
        tripEntityModificationData: CollectionItemChangeMetadata(
          tripEntity,
          isFromExplicitAction: true,
        ),
        isOperationSuccess: false,
      ));
    }
  }

  /// Handles the delete operation
  Future<void> _handleDelete<E extends TripEntity>(
    E tripEntity,
    ModelCollectionModifier<E> modelCollection,
    Emitter<TripManagementState> emit,
  ) async {
    var tripEntityId = tripEntity.id;
    if (tripEntityId == null || tripEntityId.isEmpty) {
      emit(UpdatedTripEntity<E>.deleted(
        tripEntityModificationData: CollectionItemChangeMetadata(
          tripEntity,
          isFromExplicitAction: true,
        ),
        isOperationSuccess: true,
      ));
      return;
    }

    final entityExists = modelCollection.collectionItems
        .whereType<TripEntity>()
        .any((element) => element.id == tripEntityId);

    if (!entityExists) return;

    final didDelete = await modelCollection.tryDeleteItem(tripEntity);
    emit(UpdatedTripEntity<E>.deleted(
      tripEntityModificationData: CollectionItemChangeMetadata(
        tripEntity,
        isFromExplicitAction: true,
      ),
      isOperationSuccess: didDelete,
    ));
  }

  /// Handles the update operation
  Future<void> _handleUpdate<E extends TripEntity>(
    E tripEntity,
    ModelCollectionModifier<E> modelCollection,
    Emitter<TripManagementState> emit,
  ) async {
    var tripEntityId = tripEntity.id;
    if (tripEntityId == null || tripEntityId.isEmpty) return;

    final collectionItem = modelCollection.collectionItems
        .whereType<TripEntity>()
        .where((element) => element.id == tripEntityId)
        .firstOrNull;

    if (collectionItem == null) return;

    final didUpdate = await modelCollection.tryUpdateItem(tripEntity);
    emit(UpdatedTripEntity.updated(
      tripEntityModificationData: CollectionItemChangeMetadata(
        CollectionItemChangeSet<E>(collectionItem as E, tripEntity),
        isFromExplicitAction: true,
      ),
      isOperationSuccess: didUpdate,
    ));
  }

  /// Handles the select operation
  void _handleSelect<E extends TripEntity>(
    E tripEntity,
    ModelCollectionModifier<E> modelCollection,
    Emitter<TripManagementState> emit,
  ) {
    final originalTripEntity = modelCollection.collectionItems
        .whereType<TripEntity>()
        .where((e) => e.id == tripEntity.id)
        .firstOrNull as E?;

    emit(UpdatedTripEntity<E>.selected(
      tripEntity: originalTripEntity ?? tripEntity,
    ));
  }
}
