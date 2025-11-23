import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

abstract class TripManagementEvent {
  const TripManagementEvent();
}

class GoToHome extends TripManagementEvent {
  const GoToHome();
}

class UpdateTripEntity<T extends TripEntity> extends TripManagementEvent {
  final T? tripEntity;
  final DataState dataState;

  const UpdateTripEntity.createNewUiEntry({this.tripEntity})
      : dataState = DataState.newUiEntry;

  const UpdateTripEntity.create({required this.tripEntity})
      : dataState = DataState.create;

  const UpdateTripEntity.delete({required this.tripEntity})
      : dataState = DataState.delete;

  const UpdateTripEntity.update({required this.tripEntity})
      : dataState = DataState.update;

  const UpdateTripEntity.select({required this.tripEntity})
      : dataState = DataState.select;
}

class SelectExpenseLinkedTripEntity
    extends UpdateTripEntity<ExpenseLinkedTripEntity> {
  const SelectExpenseLinkedTripEntity(
      {required ExpenseLinkedTripEntity tripEntity})
      : super.select(tripEntity: tripEntity);
}

class LoadTrip extends TripManagementEvent {
  final TripMetadataFacade tripMetadata;

  const LoadTrip({required this.tripMetadata});
}

class EditItineraryPlanData extends TripManagementEvent {
  final DateTime day;
  final ItineraryPlanDataEditorConfig planDataEditorConfig;

  const EditItineraryPlanData({
    required this.day,
    required this.planDataEditorConfig,
  });
}
