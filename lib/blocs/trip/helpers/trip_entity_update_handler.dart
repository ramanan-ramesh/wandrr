import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Handles CRUD operations for trip entities
class TripEntityUpdateHandler {
  const TripEntityUpdateHandler();

  /// Processes and updates a trip entity through CRUD operations
  Future<void> updateTripEntityAndEmitState<E extends TripEntity<Enum>>({
    required E tripEntity,
    required DataState requestedDataState,
    required ModelCollectionModifier<E> modelCollection,
    required Emitter<TripManagementState> emit,
  }) async {
    switch (requestedDataState) {
      case DataState.create:
        _handleCreate(tripEntity, modelCollection);

      case DataState.delete:
        _handleDelete(tripEntity, modelCollection);

      case DataState.update:
        _handleUpdate(tripEntity, modelCollection);

      case DataState.select:
        _handleSelect(tripEntity, modelCollection, emit);

      default:
        break;
    }
  }

  /// Handles the create operation
  void _handleCreate<E extends TripEntity<Enum>>(
      E tripEntity, ModelCollectionModifier<E> modelCollection) {
    if (tripEntity.id != null) {
      return;
    }

    modelCollection.tryAdd(tripEntity);
  }

  /// Handles the delete operation
  void _handleDelete<E extends TripEntity<Enum>>(
      E tripEntity, ModelCollectionModifier<E> modelCollection) {
    final entityExists = modelCollection.items
        .whereType<TripEntity>()
        .any((element) => element.id == tripEntity.id);

    if (!entityExists) {
      return;
    }

    modelCollection.tryDeleteItem(tripEntity);
  }

  /// Handles the update operation
  void _handleUpdate<E extends TripEntity<Enum>>(
      E tripEntity, ModelCollectionModifier<E> modelCollection) {
    var tripEntityId = tripEntity.id;
    if (tripEntityId == null || tripEntityId.isEmpty) {
      return;
    }

    final collectionItem = modelCollection.items
        .whereType<E>()
        .where((element) => element.id == tripEntityId)
        .firstOrNull;

    if (collectionItem == null) {
      return;
    }

    modelCollection.tryUpdateItem(tripEntity);
  }

  /// Handles the select operation
  void _handleSelect<E extends TripEntity<Enum>>(
      E tripEntity,
      ModelCollectionModifier<E> modelCollection,
      Emitter<TripManagementState> emit) {
    final originalTripEntity = modelCollection.items
        .whereType<TripEntity>()
        .where((e) => e.id == tripEntity.id)
        .firstOrNull as E?;

    emit(UpdatedTripEntity<E>.selected(
      tripEntity: originalTripEntity ?? tripEntity,
    ));
  }
}
