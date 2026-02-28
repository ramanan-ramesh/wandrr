import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

// =============================================================================
// TRIP ENTITY EDITOR STATES
// =============================================================================
//
// State Hierarchy for Conflict Resolution:
//
// 1. [ConflictsAdded] - Emitted when first conflicts are detected
//    → UI Response: Show conflict resolution page, rebuild all sections
//
// 2. [ConflictsUpdated] - Emitted when conflict counts change (add/remove)
//    → UI Response: Sections rebuild only if their count changed
//
// 3. [ConflictItemUpdated] - Emitted for individual item updates (clamp/delete)
//    → UI Response: Only the specific item matching type+ID rebuilds
//
// 4. [ConflictsRemoved] - Emitted when all conflicts are resolved
//    → UI Response: Hide conflict resolution page
//
// This hierarchy enables localized rebuilds:
// - Sections use [ConflictSectionBuilder] → react to count changes only
// - Items use [ConflictItemBuilder] → react to their own updates only
// =============================================================================

abstract class TripEntityEditorState<T extends TripEntity> {
  final TripEntityUpdatePlan<T>? currentPlan;

  const TripEntityEditorState(this.currentPlan);
}

/// Initial state right after construction.
class TripEntityInitialized<T extends TripEntity>
    extends TripEntityEditorState<T> {
  final T editableEntity;

  const TripEntityInitialized(this.editableEntity,
      [TripEntityUpdatePlan<T>? currentPlan])
      : super(currentPlan);
}

/// Emitted after a successful compilation of conflict plan containing conflicts.
///
/// UI Response:
/// - Show conflict resolution page
/// - All conflict sections should rebuild to display their conflicts
class ConflictsAdded<T extends TripEntity> extends TripEntityEditorState<T> {
  const ConflictsAdded(TripEntityUpdatePlan<T> currentPlan)
      : super(currentPlan);
}

/// Emitted when time ranges are updated without yielding conflicts.
///
/// UI Response:
/// - Hide conflict resolution page
/// - All sections should collapse/hide
class ConflictsRemoved<T extends TripEntity> extends TripEntityEditorState<T> {
  const ConflictsRemoved() : super(null);
}

/// Emitted when the conflict plan is updated with count changes.
///
/// Used when:
/// - Editing a conflicted item creates new conflicts (inter-conflict)
/// - The editable entity's time range changes, re-scanning all conflicts
///
/// UI Response:
/// - Sections use [BlocSelector] on count to rebuild only when their count changes
/// - Individual items do NOT rebuild from this state
class ConflictsUpdated<T extends TripEntity> extends TripEntityEditorState<T> {
  const ConflictsUpdated(TripEntityUpdatePlan<T> currentPlan)
      : super(currentPlan);
}

/// Emitted when a specific conflict item is updated (e.g., time changed, deletion toggled).
/// Contains the specific change that was updated for localized rebuilds.
///
/// Used when:
/// - User edits time of a conflicted entity
/// - User toggles deletion status
/// - Clamping is applied to resolve inter-conflicts
///
/// UI Response:
/// - Only the [ConflictItemBuilder] matching [updatedChange] type+ID rebuilds
/// - Sections do NOT rebuild from this state (count unchanged)
class ConflictItemUpdated<T extends TripEntity>
    extends TripEntityEditorState<T> {
  final EntityChangeBase updatedChange;

  const ConflictItemUpdated(
      TripEntityUpdatePlan<T> currentPlan, this.updatedChange)
      : super(currentPlan);
}

/// Emitted when editing a conflicted entity results in an unresolvable conflict.
///
/// This happens when the new time range conflicts with the editable entity itself.
///
/// UI Response:
/// - Show error snackbar
/// - Revert the conflicted entity to its previous time values
class ConflictedEntityTimeRangeError<T extends TripEntity>
    extends TripEntityEditorState<T> {
  final EntityChangeBase change;
  final String errorMessage;
  final dynamic oldTimeValues;

  const ConflictedEntityTimeRangeError(this.change, this.errorMessage,
      this.oldTimeValues, TripEntityUpdatePlan<T>? currentPlan)
      : super(currentPlan);
}

/// Emitted when the user confirms the conflict plan.
class ConflictPlanConfirmed<T extends TripEntity>
    extends TripEntityEditorState<T> {
  const ConflictPlanConfirmed(TripEntityUpdatePlan<T> currentPlan)
      : super(currentPlan);
}

/// Emitted when final submission happens, dispatching to TripManagementBloc.
class EntitySubmitted<T extends TripEntity> extends TripEntityEditorState<T> {
  final T editableEntity;

  const EntitySubmitted(
      this.editableEntity, TripEntityUpdatePlan<T>? currentPlan)
      : super(currentPlan);
}
