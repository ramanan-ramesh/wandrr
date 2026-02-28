import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

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
class ConflictsAdded<T extends TripEntity> extends TripEntityEditorState<T> {
  const ConflictsAdded(TripEntityUpdatePlan<T> currentPlan)
      : super(currentPlan);
}

/// Emitted when time ranges are updated without yielding conflicts.
class ConflictsRemoved<T extends TripEntity> extends TripEntityEditorState<T> {
  const ConflictsRemoved() : super(null);
}

/// Emitted when the existing conflict plan is updated.
class ConflictsUpdated<T extends TripEntity> extends TripEntityEditorState<T> {
  const ConflictsUpdated(TripEntityUpdatePlan<T> currentPlan)
      : super(currentPlan);
}

/// Emitted when a specific conflict item is updated (e.g., time changed, deletion toggled).
/// Contains the specific change that was updated for localized rebuilds.
class ConflictItemUpdated<T extends TripEntity>
    extends TripEntityEditorState<T> {
  final EntityChangeBase updatedChange;

  const ConflictItemUpdated(
      TripEntityUpdatePlan<T> currentPlan, this.updatedChange)
      : super(currentPlan);
}

/// Emitted when editing a conflicted entity results in another unresolvable conflict.
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
