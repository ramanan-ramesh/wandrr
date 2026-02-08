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
        originalTimeDescription: _getTimeDescription(conflict),
      );
    } else {
      return TransitChange.forDeletion(
        original: conflict.entity,
        timelinePosition: conflict.position,
        originalTimeDescription: _getTimeDescription(conflict),
      );
    }
  }

  static StayChange _toStayChange(StayConflict conflict) {
    if (conflict.canBeClampedToResolve) {
      return StayChange.forClamping(
        original: conflict.entity,
        modified: conflict.clampedEntity!,
        timelinePosition: conflict.position,
        originalTimeDescription: _getTimeDescription(conflict),
      );
    } else {
      return StayChange.forDeletion(
        original: conflict.entity,
        timelinePosition: conflict.position,
        originalTimeDescription: _getTimeDescription(conflict),
      );
    }
  }

  static SightChange _toSightChange(SightConflict conflict) {
    if (conflict.canBeClampedToResolve) {
      return SightChange.forClamping(
        original: conflict.entity,
        modified: conflict.clampedEntity!,
        timelinePosition: conflict.position,
        originalTimeDescription: _getTimeDescription(conflict),
      );
    } else {
      return SightChange.forDeletion(
        original: conflict.entity,
        timelinePosition: conflict.position,
        originalTimeDescription: _getTimeDescription(conflict),
      );
    }
  }

  static ExpenseSplitChange _toExpenseChange(ExpenseBearingTripEntity entity) {
    return ExpenseSplitChange(
      original: entity,
      modified: entity.clone(),
    );
  }

  static String _getTimeDescription<T extends TripEntity<T>>(
    ConflictResult<T> conflict,
  ) {
    final range = conflict.entityTimeRange;
    return '${_formatDateTime(range.start)} → ${_formatDateTime(range.end)}';
  }

  static String _formatDateTime(DateTime dt) {
    final weekday = _weekdayShort(dt.weekday);
    final month = _monthShort(dt.month);
    final day = dt.day;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month $day $hour:$minute $amPm';
  }

  static String _weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  static String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
