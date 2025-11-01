import 'package:wandrr/blocs/trip/plan_data_edit_context.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

abstract class TripManagementEvent {}

class GoToHome extends TripManagementEvent {}

class UpdateTripEntity<T extends TripEntity> extends TripManagementEvent {
  T? tripEntity;
  final DataState dataState;

  UpdateTripEntity.createNewUiEntry({this.tripEntity})
      : dataState = DataState.newUiEntry;

  UpdateTripEntity.create({required this.tripEntity})
      : dataState = DataState.create;

  UpdateTripEntity.delete({required this.tripEntity})
      : dataState = DataState.delete;

  UpdateTripEntity.update({required this.tripEntity})
      : dataState = DataState.update;

  UpdateTripEntity.select({required this.tripEntity})
      : dataState = DataState.select;
}

class SelectExpenseLinkedTripEntity
    extends UpdateTripEntity<ExpenseLinkedTripEntity> {
  SelectExpenseLinkedTripEntity({required ExpenseLinkedTripEntity tripEntity})
      : super.select(tripEntity: tripEntity);
}

class LoadTrip extends TripManagementEvent {
  final TripMetadataFacade tripMetadata;

  LoadTrip({required this.tripMetadata});
}

class EditItineraryPlanData extends TripManagementEvent {
  final DateTime day;
  final ItineraryPlanDataEditorConfig planDataEditorConfig;

  EditItineraryPlanData({
    required this.day,
    required this.planDataEditorConfig,
  });
}
