import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/services/conflict_detection/entity_change.dart';
import 'package:wandrr/data/trip/services/conflict_detection/trip_entity_update_plan.dart';

// =============================================================================
// TRIP ENTITY EDITOR STATES
// =============================================================================
//
// State taxonomy:
//   [TripEntityInitialized]          – initial
//   [EntityValidationUpdated]        – validation errors changed (signal only)
//   [ConflictPlanUpdated]            – conflict plan changed (created/modified/cleared)
//   [ConflictPlanConfirmed]          – user confirmed plan
//   [ConflictedEntityTimeRangeError] – invalid time on a conflicted item
//   [EntitySubmitted]                – final submission
//
// Validation errors are NOT carried on states. Read them from
// `TripEntityEditorBloc.currentValidationErrors` whenever the UI needs them.
// =============================================================================

abstract class TripEntityEditorState<T extends TripEntity<Enum>> {
  const TripEntityEditorState();
}

// ---------------------------------------------------------------------------
// Non-conflict states
// ---------------------------------------------------------------------------

/// Initial state right after construction.
class TripEntityInitialized<T extends TripEntity<Enum>>
    extends TripEntityEditorState<T> {
  final T editableEntity;

  const TripEntityInitialized(this.editableEntity);
}

/// Signal state emitted when validation errors change.
/// Carries the current error set so the bloc can cache it and callers that
/// only listen to this state type don't need a separate getter call.
class EntityValidationUpdated<T extends TripEntity<Enum>>
    extends TripEntityEditorState<T> {
  final Iterable<Enum> validationErrors;

  const EntityValidationUpdated({this.validationErrors = const []});
}

/// Emitted when the user confirms the conflict plan.
class ConflictPlanConfirmed<T extends TripEntity<Enum>>
    extends TripEntityEditorState<T> {
  const ConflictPlanConfirmed();
}

/// Emitted when final submission happens.
class EntitySubmitted<T extends TripEntity<Enum>>
    extends TripEntityEditorState<T> {
  final T editableEntity;

  /// Plan at time of submission – carried here since submission consumes it once.
  final TripEntityUpdatePlan<T>? currentPlan;

  const EntitySubmitted(this.editableEntity, this.currentPlan);
}

/// Emitted when editing a conflicted entity results in an unresolvable conflict.
/// UI Response: show error snackbar; revert the conflicted entity's time values.
/// The UI is responsible for building the error message from [conflictingEntity]
/// (e.g. via its [toString] or a localised description based on its type).
class ConflictedEntityTimeRangeError<T extends TripEntity<Enum>>
    extends TripEntityEditorState<T> {
  final EntityChangeBase change;

  /// The entity that [change]'s modified time conflicts with.
  final TripEntity conflictingEntity;

  final dynamic oldTimeValues;

  const ConflictedEntityTimeRangeError(
      this.change, this.conflictingEntity, this.oldTimeValues);
}

// ---------------------------------------------------------------------------
// Conflict plan state
// ---------------------------------------------------------------------------

/// Unified state emitted whenever the conflict plan changes — whether items
/// are added, removed, modified in-place, or the plan is cleared entirely.
///
/// The UI reads the actual plan data from `bloc.currentPlan` /
/// `context.tripEntityUpdatePlan<T>()`. This state simply signals that the
/// plan reference has been updated.
class ConflictPlanUpdated<T extends TripEntity<Enum>>
    extends TripEntityEditorState<T> {
  const ConflictPlanUpdated();
}
