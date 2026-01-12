import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';

abstract class TripManagementEvent {
  const TripManagementEvent();
}

class GoToHome extends TripManagementEvent {
  const GoToHome();
}

class UpdateTripEntity<T extends TripEntity> extends TripManagementEvent {
  final T tripEntity;
  final DataState dataState;

  const UpdateTripEntity.create({required this.tripEntity})
      : dataState = DataState.create;

  const UpdateTripEntity.delete({required this.tripEntity})
      : dataState = DataState.delete;

  const UpdateTripEntity.update({required this.tripEntity})
      : dataState = DataState.update;

  const UpdateTripEntity.select({required this.tripEntity})
      : dataState = DataState.select;
}

class SelectExpenseBearingTripEntity
    extends UpdateTripEntity<ExpenseBearingTripEntity> {
  const SelectExpenseBearingTripEntity(
      {required ExpenseBearingTripEntity tripEntity})
      : super.select(tripEntity: tripEntity);
}

/// Event to apply a pre-computed update plan for trip metadata changes
/// This is the preferred way to handle trip metadata changes as it uses batch writes
class ApplyTripMetadataUpdatePlan extends TripManagementEvent {
  final TripMetadataUpdatePlan updatePlan;

  const ApplyTripMetadataUpdatePlan({required this.updatePlan});
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
