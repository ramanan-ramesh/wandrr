import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change_context.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_data_update_plan.dart';
import 'package:wandrr/data/trip/services/conflict_detection/conflict_detection.dart';

/// Converts raw conflict data to UI-ready EntityChange objects.
/// This is the bridge between the pure data layer and the presentation layer.
class ConflictToEntityChangeAdapter {
  const ConflictToEntityChangeAdapter._();

  /// Converts aggregated conflicts to a TripDataUpdatePlan with EntityChange objects.
  static TripDataUpdatePlan toUpdatePlan({
    required AggregatedConflicts conflicts,
    required DateTime tripStartDate,
    required DateTime tripEndDate,
    EntityChangeContext context = EntityChangeContext.timelineConflict,
  }) {
    return TripDataUpdatePlan(
      transitChanges: conflicts.transitConflicts
          .map((c) => _toEntityChange(c, context))
          .toList(),
      stayChanges: conflicts.stayConflicts
          .map((c) => _toEntityChange(c, context))
          .toList(),
      sightChanges: conflicts.sightConflicts
          .map((c) => _toEntityChange(c, context))
          .toList(),
      tripStartDate: tripStartDate,
      tripEndDate: tripEndDate,
    );
  }

  /// Converts a single ConflictResult to an EntityChange.
  static EntityChange<T> _toEntityChange<T extends TripEntity<T>>(
    ConflictResult<T> conflict,
    EntityChangeContext context,
  ) {
    if (conflict.canBeClampedToResolve) {
      return EntityChange<T>.forClamping(
        originalEntity: conflict.entity,
        modifiedEntity: conflict.clampedEntity as T,
        conflictDescription: _getDescription(conflict.entity),
        originalTimeDescription: _getTimeDescription(conflict),
        timelinePosition: conflict.position,
        context: context,
      );
    } else {
      return EntityChange<T>.forDeletion(
        originalEntity: conflict.entity,
        conflictDescription: _getDescription(conflict.entity),
        originalTimeDescription: _getTimeDescription(conflict),
        timelinePosition: conflict.position,
        context: context,
      );
    }
  }

  /// Gets a short description for the entity (used in UI)
  static String _getDescription<T extends TripEntity>(T entity) {
    if (entity is TransitFacade) {
      final from = entity.departureLocation?.context.name ?? '?';
      final to = entity.arrivalLocation?.context.name ?? '?';
      return '$from → $to';
    } else if (entity is LodgingFacade) {
      return entity.location?.context.name ?? 'Unknown location';
    } else if (entity is SightFacade) {
      return entity.name.isNotEmpty ? entity.name : 'Unnamed sight';
    }
    return 'Unknown entity';
  }

  /// Gets the original time description for the entity
  static String _getTimeDescription<T extends TripEntity<T>>(
    ConflictResult<T> conflict,
  ) {
    final range = conflict.entityTimeRange;
    // Format: "Mon, Jan 15 10:30 AM → Mon, Jan 15 2:30 PM"
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
