import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

abstract class TripEntityEditorEvent {
  const TripEntityEditorEvent();
}

/// Unified update event for Stay, Sights (ItineraryPlanData), and TripMetadata.
/// The bloc reads time ranges directly from `editableEntity` (already mutated
/// by the editor) and runs conflict detection. Also handles non-time field
/// changes (validation refresh).
class UpdateEntity<T extends TripEntity<Enum>> extends TripEntityEditorEvent {
  const UpdateEntity();
}

/// Unified update event for transit journeys.
/// Carries all current in-memory legs so the bloc can validate cross-leg
/// sequence and individual legs before running conflict detection.
/// The bloc instantiates the journey service internally from tripData.
///
/// [removedLegIds] — IDs of legs that have been staged for deletion in the
/// editor but not yet written to Firestore.  They must be excluded from the
/// conflict scanner so that a leg whose time now overlaps a *deleted* leg does
/// not produce a spurious conflict.
class UpdateJourney extends TripEntityEditorEvent {
  final List<TransitFacade> legs;

  /// IDs of legs removed in this editing session (staged, not yet persisted).
  final Set<String> removedLegIds;

  const UpdateJourney(this.legs, {this.removedLegIds = const {}});
}

class UpdateConflictedEntityTimeRange extends TripEntityEditorEvent {
  final EntityChangeBase change;

  const UpdateConflictedEntityTimeRange(this.change);
}

/// Toggle delete/restore on a conflicted entity.
class ToggleConflictedEntityDeletion extends TripEntityEditorEvent {
  final EntityChangeBase change;

  const ToggleConflictedEntityDeletion(this.change);
}

/// User confirmed the conflict plan.
class ConfirmConflictPlan extends TripEntityEditorEvent {
  const ConfirmConflictPlan();
}

/// User is submitting the final entity creation/edit.
class SubmitEntity extends TripEntityEditorEvent {
  const SubmitEntity();
}
