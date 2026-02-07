import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_timeline_position.dart';

import 'entity_change_type.dart';

/// Pure data representation of a pending change to a trip entity.
/// Contains NO UI concerns - no messages, no descriptions.
/// This is suitable for both backend and frontend use.
class EntityChangeData<T extends TripEntity> {
  final T originalEntity;
  T modifiedEntity;
  EntityChangeType changeType;

  /// For expenses: whether to add new contributors to splitBy
  bool includeInSplitBy;

  /// The temporal relationship between this entity and the reference time range
  /// Used for conflict resolution logic (not presentation)
  final EntityTimelinePosition? timelinePosition;

  /// Whether this change was auto-clamped (times adjusted to resolve conflict)
  final bool isClamped;

  EntityChangeData({
    required this.originalEntity,
    required this.modifiedEntity,
    this.changeType = EntityChangeType.update,
    this.includeInSplitBy = false,
    this.timelinePosition,
    this.isClamped = false,
  });

  EntityChangeData.forDeletion({
    required this.originalEntity,
    this.timelinePosition,
  })  : modifiedEntity = originalEntity,
        changeType = EntityChangeType.delete,
        includeInSplitBy = false,
        isClamped = false;

  EntityChangeData.forClamping({
    required this.originalEntity,
    required this.modifiedEntity,
    this.timelinePosition,
  })  : changeType = EntityChangeType.update,
        includeInSplitBy = false,
        isClamped = true;

  bool get isUpdate => changeType == EntityChangeType.update;

  bool get isDelete => changeType == EntityChangeType.delete;

  bool get isMarkedForDeletion => changeType == EntityChangeType.delete;

  void markForDeletion() {
    changeType = EntityChangeType.delete;
  }

  void restore() {
    changeType = EntityChangeType.update;
  }
}
