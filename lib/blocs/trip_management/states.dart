import 'package:wandrr/contracts/data_states.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/model_collection.dart';

abstract class TripManagementState {
  bool isTripEntity<T>() {
    if (this is UpdatedTripEntity) {
      if (this is UpdatedTripEntity<T>) {
        return true;
      } else if ((this as UpdatedTripEntity).tripEntityModificationData
          is CollectionModificationData<T>) {
        return true;
      }
    }
    return false;
  }
}

class NavigateToHome extends TripManagementState {}

class ActivatedTrip extends TripManagementState {}

class UpdatedTripEntity<T> extends TripManagementState {
  final CollectionModificationData<T> tripEntityModificationData;
  final DataState dataState;
  final bool isOperationSuccess;

  UpdatedTripEntity.createdNewUiEntry(
      {required T tripEntity, required this.isOperationSuccess})
      : dataState = DataState.NewUiEntry,
        tripEntityModificationData =
            CollectionModificationData(tripEntity, true);

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
        tripEntityModificationData =
            CollectionModificationData(tripEntity, true);
}

class UpdatedLinkedExpense<T> extends UpdatedTripEntity<ExpenseModelFacade> {
  final T link;

  UpdatedLinkedExpense.updated(
      {required ExpenseModelFacade expense,
      required this.link,
      required bool isFromEvent,
      required bool isOperationSuccess})
      : super.updated(
            tripEntityModificationData:
                CollectionModificationData(expense, isFromEvent),
            isOperationSuccess: isOperationSuccess);

  UpdatedLinkedExpense.selected(
      {required ExpenseModelFacade expense,
      required this.link,
      required bool isOperationSuccess})
      : super.selected(tripEntity: expense);
}

class ItineraryDataUpdated extends TripManagementState {
  final DateTime day;
  final bool isOperationSuccess;

  ItineraryDataUpdated({required this.day, required this.isOperationSuccess});
}
