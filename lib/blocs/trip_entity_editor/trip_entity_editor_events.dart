import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/time_range.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

abstract class TripEntityEditorEvent {
  const TripEntityEditorEvent();
}

/// Time range changed on the primary entity.
class UpdateEntityTimeRange<T extends TripEntity>
    extends TripEntityEditorEvent {
  final TimeRange range;

  const UpdateEntityTimeRange(this.range);
}

/// Time range changed on a transit journey (which has multiple legs).
class UpdateJourneyTimeRange extends TripEntityEditorEvent {
  final List<TransitFacade> legs;

  const UpdateJourneyTimeRange(this.legs);
}

/// Time range changed on a conflicted entity.
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
