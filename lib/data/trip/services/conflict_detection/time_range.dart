import 'package:wandrr/data/trip/services/conflict_detection/entity_timeline_position.dart';

/// Represents a time range with start and end bounds.
class TimeRange {
  final DateTime start;
  final DateTime end;

  const TimeRange({required this.start, required this.end});

  /// Returns true when [a] and [b] fall in the same clock minute.
  ///
  /// All temporal comparisons in conflict detection use minute-level precision
  /// because entity times (check-in, departure, visit) are always set at
  /// minute granularity via time pickers.
  static bool isSameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  /// Returns the temporal relationship of this range relative to [other].
  ///
  /// **Adjacent events** (this.end == other.start, or this.start == other.end)
  /// are [EntityTimelinePosition.beforeEvent] / [EntityTimelinePosition.afterEvent],
  /// never overlapping. Shared start **or** shared end times are a genuine
  /// [EntityTimelinePosition.exactBoundaryMatch].
  EntityTimelinePosition analyzePosition(TimeRange other) {
    // Shared start/end → true overlap at boundary.
    if (isSameMinute(start, other.start) || isSameMinute(end, other.end)) {
      return EntityTimelinePosition.exactBoundaryMatch;
    }
    // Adjacent: this ends when other starts, or vice-versa.
    if (isSameMinute(end, other.start)) {
      return EntityTimelinePosition.beforeEvent;
    }
    if (isSameMinute(start, other.end)) {
      return EntityTimelinePosition.afterEvent;
    }

    // All four boundary equalities are handled above, so strict
    // isBefore / isAfter comparisons are safe for the remaining cases.
    if (start.isBefore(other.start)) {
      if (end.isAfter(other.end)) {
        return EntityTimelinePosition.contains;
      }
      if (end.isAfter(other.start)) {
        return EntityTimelinePosition.startsBeforeEndsDuring;
      }
      return EntityTimelinePosition.beforeEvent;
    }

    // start > other.start
    if (end.isBefore(other.end)) {
      return EntityTimelinePosition.containedIn;
    }
    if (start.isBefore(other.end)) {
      return EntityTimelinePosition.startsDuringEndsAfter;
    }
    return EntityTimelinePosition.afterEvent;
  }
}
