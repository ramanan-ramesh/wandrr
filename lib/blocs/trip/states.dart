import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';

abstract class TripManagementState {
  bool isTripEntityUpdated<T>() {
    if (this is UpdatedTripEntity) {
      if (this is UpdatedTripEntity<T> &&
          (this as UpdatedTripEntity<T>).isOperationSuccess) {
        return true;
      } else if ((this as UpdatedTripEntity).tripEntityModificationData
              is CollectionItemChangeMetadata<T> &&
          (this as UpdatedTripEntity).isOperationSuccess) {
        return true;
      }
    }
    return false;
  }
}

class LoadingTripManagement extends TripManagementState {}

class LoadingTrip extends TripManagementState {
  TripMetadataFacade tripMetadataFacade;

  LoadingTrip(this.tripMetadataFacade);
}

class LoadedRepository extends TripManagementState {
  final TripRepositoryFacade tripRepository;

  LoadedRepository({required this.tripRepository});
}

class NavigateToHome extends TripManagementState {}

class ActivatedTrip extends TripManagementState {
  final ApiServicesRepositoryFacade apiServicesRepository;

  ActivatedTrip({required this.apiServicesRepository});
}

class UpdatedTripEntity<T> extends TripManagementState {
  final CollectionItemChangeMetadata<T> tripEntityModificationData;
  final DataState dataState;
  final bool isOperationSuccess;

  UpdatedTripEntity.createdNewUiEntry(
      {required T tripEntity, required this.isOperationSuccess})
      : dataState = DataState.newUiEntry,
        tripEntityModificationData = CollectionItemChangeMetadata(tripEntity,
            isFromExplicitAction: true);

  UpdatedTripEntity.created(
      {required this.tripEntityModificationData,
      required this.isOperationSuccess})
      : dataState = DataState.create;

  UpdatedTripEntity.deleted(
      {required this.tripEntityModificationData,
      required this.isOperationSuccess})
      : dataState = DataState.delete;

  UpdatedTripEntity.updated(
      {required this.tripEntityModificationData,
      required this.isOperationSuccess})
      : dataState = DataState.update;

  UpdatedTripEntity.selected({
    required T tripEntity,
  })  : dataState = DataState.select,
        isOperationSuccess = true,
        tripEntityModificationData = CollectionItemChangeMetadata(tripEntity,
            isFromExplicitAction: true);
}

class UpdatedLinkedExpense<T> extends UpdatedTripEntity<ExpenseFacade> {
  final T link;

  UpdatedLinkedExpense.updated(
      {required ExpenseFacade expense,
      required this.link,
      required bool isFromEvent,
      required bool isOperationSuccess})
      : super.updated(
            tripEntityModificationData: CollectionItemChangeMetadata(expense,
                isFromExplicitAction: isFromEvent),
            isOperationSuccess: isOperationSuccess);

  UpdatedLinkedExpense.selected(
      {required ExpenseFacade expense, required this.link})
      : super.selected(tripEntity: expense);
}

class ItineraryDataUpdated extends TripManagementState {
  final DateTime day;
  final bool isOperationSuccess;

  ItineraryDataUpdated({required this.day, required this.isOperationSuccess});
}

class ProcessSectionNavigation extends TripManagementState {
  DateTime? dateTime;
  final String section;

  ProcessSectionNavigation({required this.section, this.dateTime});
}
