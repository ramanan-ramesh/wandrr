import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

// =============================================================================
// TRIP ENTITY EDITOR STATES
// =============================================================================
//
// State taxonomy:
//   [TripEntityInitialized]          – initial
//   [EntityValidationUpdated]        – validation errors changed
//   [ConflictPlanUpdated]            – conflict plan changed (created/modified/cleared)
//   [ConflictPlanConfirmed]          – user confirmed plan
//   [ConflictedEntityTimeRangeError] – invalid time on a conflicted item
//   [EntitySubmitted]                – final submission
// =============================================================================

abstract class TripEntityEditorState<T extends TripEntity<Enum>> {
  final Iterable<Enum> validationErrors;
  const TripEntityEditorState({this.validationErrors = const []});
}

// ---------------------------------------------------------------------------
// Non-conflict states
// ---------------------------------------------------------------------------

/// Initial state right after construction.
class TripEntityInitialized<T extends TripEntity<Enum>>
    extends TripEntityEditorState<T> {
  final T editableEntity;
  const TripEntityInitialized(this.editableEntity,
      {Iterable<Enum> validationErrors = const []})
      : super(validationErrors: validationErrors);
}

/// Emitted when entity content is updated to reflect new validation errors.
class EntityValidationUpdated<T extends TripEntity<Enum>>
    extends TripEntityEditorState<T> {
  const EntityValidationUpdated({Iterable<Enum> validationErrors = const []})
      : super(validationErrors: validationErrors);
}

/// Emitted when the user confirms the conflict plan.
class ConflictPlanConfirmed<T extends TripEntity<Enum>>
    extends TripEntityEditorState<T> {
  const ConflictPlanConfirmed({Iterable<Enum> validationErrors = const []})
      : super(validationErrors: validationErrors);
}

/// Emitted when final submission happens.
class EntitySubmitted<T extends TripEntity<Enum>>
    extends TripEntityEditorState<T> {
  final T editableEntity;

  /// Plan at time of submission – carried here since submission consumes it once.
  final TripEntityUpdatePlan<T>? currentPlan;

  const EntitySubmitted(this.editableEntity, this.currentPlan,
      {Iterable<Enum> validationErrors = const []})
      : super(validationErrors: validationErrors);
}

/// Emitted when editing a conflicted entity results in an unresolvable conflict.
/// UI Response: show error snackbar; revert the conflicted entity's time values.
class ConflictedEntityTimeRangeError<T extends TripEntity<Enum>>
    extends TripEntityEditorState<T> {
  final EntityChangeBase change;
  final String errorMessage;
  final dynamic oldTimeValues;
  const ConflictedEntityTimeRangeError(
      this.change, this.errorMessage, this.oldTimeValues,
      {Iterable<Enum> validationErrors = const []})
      : super(validationErrors: validationErrors);
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
  const ConflictPlanUpdated({Iterable<Enum> validationErrors = const []})
      : super(validationErrors: validationErrors);
}
