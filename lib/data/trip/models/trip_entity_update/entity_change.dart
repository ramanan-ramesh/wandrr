import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'entity_change_context.dart';
import 'entity_change_data.dart';
import 'entity_change_type.dart';

/// Represents a pending change to a trip entity WITH UI-specific metadata.
/// This extends EntityChangeData with presentation-layer concerns.
/// Use EntityChangeData for backend/pure logic, and this for UI.
class EntityChange<T extends TripEntity> extends EntityChangeData<T> {
  /// UI-specific description of the conflict
  final String? conflictDescription;

  /// UI-specific original time description
  final String? originalTimeDescription;

  /// User-friendly message explaining the conflict
  final String? conflictMessage;

  /// The context in which this change is being applied
  final EntityChangeContext context;

  EntityChange({
    required super.originalEntity,
    required super.modifiedEntity,
    super.changeType = EntityChangeType.update,
    super.includeInSplitBy = false,
    this.conflictDescription,
    this.originalTimeDescription,
    this.conflictMessage,
    super.timelinePosition,
    this.context = EntityChangeContext.tripMetadataUpdate,
    super.isClamped = false,
  });

  EntityChange.forDeletion({
    required super.originalEntity,
    this.conflictDescription,
    this.originalTimeDescription,
    this.conflictMessage,
    super.timelinePosition,
    this.context = EntityChangeContext.tripMetadataUpdate,
  }) : super.forDeletion();

  /// Creates an EntityChange with clamped times to resolve the conflict
  EntityChange.forClamping({
    required super.originalEntity,
    required super.modifiedEntity,
    this.conflictDescription,
    this.originalTimeDescription,
    this.conflictMessage,
    super.timelinePosition,
    this.context = EntityChangeContext.tripMetadataUpdate,
  }) : super.forClamping();
}
