import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/services/conflict_result.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

/// Converts raw conflict data to UI-ready EntityChange objects.
/// Creates TripEntityUpdatePlan for both conflict resolution and metadata updates.
class ConflictToEntityChangeAdapter {
  const ConflictToEntityChangeAdapter._();

  /// Converts aggregated conflicts to a TripEntityUpdatePlan for conflict resolution.
  static TripEntityUpdatePlan<T> toUpdatePlan<T extends TripEntity>({
    required T oldEntity,
    required T newEntity,
    required AggregatedConflicts conflicts,
    required DateTime tripStartDate,
    required DateTime endDate,
  }) {
    return TripEntityUpdatePlan<T>(
      tripStartDate: tripStartDate,
      tripEndDate: endDate,
      oldEntity: oldEntity,
      newEntity: newEntity,
      transitChanges: conflicts.transitConflicts.map(_toTransitChange).toList(),
      stayChanges: conflicts.stayConflicts.map(_toStayChange).toList(),
      sightChanges: conflicts.sightConflicts.map(_toSightChange).toList(),
    );
  }

  /// Converts MetadataUpdateConflicts to a TripEntityUpdatePlan for TripMetadata.
  static TripEntityUpdatePlan<TripMetadataFacade> toMetadataUpdatePlan(
    MetadataUpdateConflicts conflicts,
  ) {
    return TripEntityUpdatePlan<TripMetadataFacade>(
      oldEntity: conflicts.oldMetadata,
      newEntity: conflicts.newMetadata,
      tripStartDate: conflicts.newMetadata.startDate!,
      tripEndDate: conflicts.newMetadata.endDate!,
      transitChanges: conflicts.transitConflicts.map(_toTransitChange).toList(),
      stayChanges: conflicts.stayConflicts.map(_toStayChange).toList(),
      sightChanges: conflicts.sightConflicts.map(_toSightChange).toList(),
      expenseChanges: conflicts.expenseEntities.map(_toExpenseChange).toList(),
    );
  }

  static TransitChange _toTransitChange(TransitConflict conflict) {
    if (conflict.canBeClampedToResolve) {
      return TransitChange.forClamping(
        original: conflict.entity,
        modified: conflict.clampedEntity!,
        timelinePosition: conflict.position,
      );
    } else {
      return TransitChange.forDeletion(
        original: conflict.entity,
        timelinePosition: conflict.position,
      );
    }
  }

  static StayChange _toStayChange(StayConflict conflict) {
    if (conflict.canBeClampedToResolve) {
      return StayChange.forClamping(
        original: conflict.entity,
        modified: conflict.clampedEntity!,
        timelinePosition: conflict.position,
      );
    } else {
      return StayChange.forDeletion(
        original: conflict.entity,
        timelinePosition: conflict.position,
      );
    }
  }

  static SightChange _toSightChange(SightConflict conflict) {
    if (conflict.canBeClampedToResolve) {
      return SightChange.forClamping(
        original: conflict.entity,
        modified: conflict.clampedEntity!,
        timelinePosition: conflict.position,
      );
    } else {
      return SightChange.forDeletion(
        original: conflict.entity,
        timelinePosition: conflict.position,
      );
    }
  }

  static ExpenseSplitChange _toExpenseChange(ExpenseBearingTripEntity entity) {
    return ExpenseSplitChange(
      original: entity,
      modified: entity.clone(),
    );
  }
}
