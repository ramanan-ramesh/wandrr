import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'entity_change_context.dart';
import 'entity_change_type.dart';
import 'entity_timeline_position.dart';

/// Represents a pending change to a trip entity
/// Used by both the UI (AffectedEntitiesEditor) and the data layer
class EntityChange<T extends TripEntity> {
  final T originalEntity;
  T modifiedEntity;
  EntityChangeType changeType;

  /// For expenses: whether to add new contributors to splitBy
  bool includeInSplitBy;

  /// Optional: description of the conflict (for timeline conflict UI)
  final String? conflictDescription;

  /// Optional: original time description (for timeline conflict UI)
  final String? originalTimeDescription;

  /// User-friendly message explaining the conflict
  final String? conflictMessage;

  /// The temporal relationship between this entity and the reference time range
  final EntityTimelinePosition? timelinePosition;

  /// The context in which this change is being applied
  final EntityChangeContext context;

  /// Whether this change was auto-clamped (times adjusted to resolve conflict)
  bool isClamped;

  EntityChange({
    required this.originalEntity,
    required this.modifiedEntity,
    this.changeType = EntityChangeType.update,
    this.includeInSplitBy = false,
    this.conflictDescription,
    this.originalTimeDescription,
    this.conflictMessage,
    this.timelinePosition,
    this.context = EntityChangeContext.tripMetadataUpdate,
    this.isClamped = false,
  });

  EntityChange.forDeletion({
    required this.originalEntity,
    this.conflictDescription,
    this.originalTimeDescription,
    this.conflictMessage,
    this.timelinePosition,
    this.context = EntityChangeContext.tripMetadataUpdate,
  })  : modifiedEntity = originalEntity,
        changeType = EntityChangeType.delete,
        includeInSplitBy = false,
        isClamped = false;

  /// Creates an EntityChange with clamped times to resolve the conflict
  /// The modifiedEntity has adjusted times that don't conflict
  EntityChange.forClamping({
    required this.originalEntity,
    required this.modifiedEntity,
    this.conflictDescription,
    this.originalTimeDescription,
    this.conflictMessage,
    this.timelinePosition,
    this.context = EntityChangeContext.tripMetadataUpdate,
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
