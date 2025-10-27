import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';

abstract class TripManagementState {
  bool isTripEntityUpdated<T>() {
    if (this is UpdatedTripEntity) {
      if (this is UpdatedTripEntity<T> &&
          (this as UpdatedTripEntity<T>).isOperationSuccess) {
        return true;
      } else {
        var collectionItemChangeMetadata =
            (this as UpdatedTripEntity).tripEntityModificationData;
        if (collectionItemChangeMetadata is CollectionItemChangeMetadata<T> ||
            collectionItemChangeMetadata.modifiedCollectionItem is T) {
          return (this as UpdatedTripEntity).isOperationSuccess;
        }
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

class ProcessSectionNavigation extends TripManagementState {
  DateTime? dateTime;
  final String section;

  ProcessSectionNavigation({required this.section, this.dateTime});
}
