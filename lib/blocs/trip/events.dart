import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/services/conflict_detection/trip_entity_update_plan.dart';

abstract class TripManagementEvent {
  const TripManagementEvent();
}

class GoToHome extends TripManagementEvent {
  const GoToHome();
}

class UpdateTripEntity<T extends TripEntity<Enum>> extends TripManagementEvent {
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

/// Dispatched when the user taps an [ExpenseBearingTripEntity] inside the
/// BudgetingPage (expense list).  Using a dedicated event (not a generic
/// [UpdateTripEntity]) avoids Dart's covariant generic subtyping issue that
/// would otherwise cause the timeline's type-specific handlers
/// (e.g. [UpdateTripEntity<TransitFacade>]) to also fire when a transit / stay
/// is tapped on the timeline, producing two bottom sheets simultaneously.
class SelectExpenseForDetails extends TripManagementEvent {
  final ExpenseBearingTripEntity tripEntity;

  const SelectExpenseForDetails({required this.tripEntity});
}

/// Event to apply a pre-computed update plan for trip metadata changes.
/// This is the preferred way to handle trip metadata changes as it uses batch writes.
class ApplyTripDataUpdatePlan extends TripManagementEvent {
  final TripEntityUpdatePlan updatePlan;

  const ApplyTripDataUpdatePlan({required this.updatePlan});
}

class LoadTrip extends TripManagementEvent {
  final TripMetadataFacade tripMetadata;
  final bool shouldActivateTrip;

  const LoadTrip(
      {required this.tripMetadata, required this.shouldActivateTrip});
}

class EditItineraryPlanData extends TripManagementEvent {
  final DateTime day;
  final ItineraryPlanDataEditorConfig planDataEditorConfig;

  const EditItineraryPlanData({
    required this.day,
    required this.planDataEditorConfig,
  });
}

class CopyTrip extends TripManagementEvent {
  final TripMetadataFacade sourceTripMetadata;
  final String newName;
  final DateTime newStartDate;
  final List<String> contributors;
  final Money budget;
  final String thumbnailTag;

  const CopyTrip({
    required this.sourceTripMetadata,
    required this.newName,
    required this.newStartDate,
    required this.contributors,
    required this.budget,
    required this.thumbnailTag,
  });
}
