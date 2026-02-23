import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

abstract class TripEntityEditorState<T extends TripEntity> {
  const TripEntityEditorState();
}

/// Initial state right after construction.
class TripEntityInitialized<T extends TripEntity>
    extends TripEntityEditorState<T> {
  final T editableEntity;

  const TripEntityInitialized(this.editableEntity);
}

/// Emitted after a successful compilation of conflict plan containing conflicts.
class ConflictsAdded<T extends TripEntity> extends TripEntityEditorState<T> {
  const ConflictsAdded();
}

/// Emitted when time ranges are updated without yielding conflicts.
class ConflictsRemoved<T extends TripEntity> extends TripEntityEditorState<T> {
  const ConflictsRemoved();
}

/// Emitted when the existing conflict plan is updated.
class ConflictsUpdated<T extends TripEntity> extends TripEntityEditorState<T> {
  const ConflictsUpdated();
}

/// Emitted when a conflicted entity is legitimately updated.
class ConflictedEntityTimeRangeUpdated<T extends TripEntity>
    extends TripEntityEditorState<T> {
  final EntityChangeBase change;

  const ConflictedEntityTimeRangeUpdated(this.change);
}

/// Emitted when editing a conflicted entity results in another unresolvable conflict.
class ConflictedEntityTimeRangeError<T extends TripEntity>
    extends TripEntityEditorState<T> {
  final EntityChangeBase change;
  final String errorMessage;

  const ConflictedEntityTimeRangeError(this.change, this.errorMessage);
}

/// Emitted when a conflicted entity's deletion status is toggled.
class ConflictedEntityDeletionToggled<T extends TripEntity>
    extends TripEntityEditorState<T> {
  final EntityChangeBase change;
  final bool isDeleted;

  const ConflictedEntityDeletionToggled(this.change, this.isDeleted);
}

/// Emitted when the user confirms the conflict plan.
class ConflictPlanConfirmed<T extends TripEntity>
    extends TripEntityEditorState<T> {
  const ConflictPlanConfirmed();
}

/// Emitted when final submission happens, dispatching to TripManagementBloc.
class EntitySubmitted<T extends TripEntity> extends TripEntityEditorState<T> {
  final T editableEntity;

  const EntitySubmitted(this.editableEntity);
}
