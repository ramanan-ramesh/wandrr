import 'package:wandrr/contracts/database_connectors/collection_change_metadata.dart';
import 'package:wandrr/contracts/database_connectors/data_states.dart';
import 'package:wandrr/contracts/trip_entity_facades/expense.dart';

abstract class TripManagementState {
  bool isTripEntity<T>() {
    if (this is UpdatedTripEntity) {
      if (this is UpdatedTripEntity<T>) {
        return true;
      } else if ((this as UpdatedTripEntity).tripEntityModificationData
          is CollectionChangeMetadata<T>) {
        return true;
      }
    }
    return false;
  }
}

class NavigateToHome extends TripManagementState {}

class ActivatedTrip extends TripManagementState {}

class UpdatedTripEntity<T> extends TripManagementState {
  final CollectionChangeMetadata<T> tripEntityModificationData;
  final DataState dataState;
  final bool isOperationSuccess;

  UpdatedTripEntity.createdNewUiEntry(
      {required T tripEntity, required this.isOperationSuccess})
      : dataState = DataState.NewUiEntry,
        tripEntityModificationData = CollectionChangeMetadata(tripEntity, true);

  UpdatedTripEntity.created(
      {required this.tripEntityModificationData,
      required this.isOperationSuccess})
      : dataState = DataState.Create;

  UpdatedTripEntity.deleted(
      {required this.tripEntityModificationData,
      required this.isOperationSuccess})
      : dataState = DataState.Delete;

  UpdatedTripEntity.updated(
      {required this.tripEntityModificationData,
      required this.isOperationSuccess})
      : dataState = DataState.Update;

  UpdatedTripEntity.selected({
    required T tripEntity,
  })  : dataState = DataState.Select,
        isOperationSuccess = true,
        tripEntityModificationData = CollectionChangeMetadata(tripEntity, true);
}

class UpdatedLinkedExpense<T> extends UpdatedTripEntity<ExpenseFacade> {
  final T link;

  UpdatedLinkedExpense.updated(
      {required ExpenseFacade expense,
      required this.link,
      required bool isFromEvent,
      required bool isOperationSuccess})
      : super.updated(
            tripEntityModificationData:
                CollectionChangeMetadata(expense, isFromEvent),
            isOperationSuccess: isOperationSuccess);

  UpdatedLinkedExpense.selected(
      {required ExpenseFacade expense,
      required this.link,
      required bool isOperationSuccess})
      : super.selected(tripEntity: expense);
}

class ItineraryDataUpdated extends TripManagementState {
  final DateTime day;
  final bool isOperationSuccess;

  ItineraryDataUpdated({required this.day, required this.isOperationSuccess});
}
