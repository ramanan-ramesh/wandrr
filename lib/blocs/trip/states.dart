import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';

abstract class TripManagementState {
  bool isTripEntityUpdated<T>() {
    if (this is UpdatedTripEntity) {
      var isOperationSuccess = (this as UpdatedTripEntity).isOperationSuccess;
      if (this is UpdatedTripEntity<T>) {
        return isOperationSuccess;
      } else {
        var modifiedCollectionItem = (this as UpdatedTripEntity)
            .tripEntityModificationData
            .modifiedCollectionItem;
        if (modifiedCollectionItem is T) {
          return isOperationSuccess;
        } else if (modifiedCollectionItem is CollectionItemChangeSet &&
            modifiedCollectionItem.afterUpdate is T) {
          return isOperationSuccess;
        }
      }
    }
    return false;
  }

  const TripManagementState();
}

class LoadingTripManagement extends TripManagementState {
  const LoadingTripManagement();
}

class LoadingTrip extends TripManagementState {
  final TripMetadataFacade tripMetadataFacade;

  const LoadingTrip(this.tripMetadataFacade);
}

class LoadedRepository extends TripManagementState {
  final TripRepositoryFacade tripRepository;

  const LoadedRepository({required this.tripRepository});
}

class NavigateToHome extends TripManagementState {
  const NavigateToHome();
}

class ActivatedTrip extends TripManagementState {
  final ApiServicesRepositoryFacade apiServicesRepository;

  const ActivatedTrip({required this.apiServicesRepository});
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

  const UpdatedTripEntity.created(
      {required this.tripEntityModificationData,
      required this.isOperationSuccess})
      : dataState = DataState.create;

  const UpdatedTripEntity.deleted(
      {required this.tripEntityModificationData,
      required this.isOperationSuccess})
      : dataState = DataState.delete;

  const UpdatedTripEntity.updated(
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

class SelectedExpenseBearingTripEntity
    extends UpdatedTripEntity<ExpenseBearingTripEntity> {
  SelectedExpenseBearingTripEntity(
      {required ExpenseBearingTripEntity tripEntity})
      : super.selected(tripEntity: tripEntity);
}

class SelectedItineraryPlanData extends TripManagementState {
  final ItineraryPlanData planData;
  final ItineraryPlanDataEditorConfig planDataEditorConfig;

  const SelectedItineraryPlanData({
    required this.planData,
    required this.planDataEditorConfig,
  });
}
