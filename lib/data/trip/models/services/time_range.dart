import 'package:wandrr/data/trip/models/services/entity_timeline_position.dart';

/// Represents a time range with start and end bounds
class TimeRange {
  final DateTime start;
  final DateTime end;

  const TimeRange({required this.start, required this.end});

  EntityTimelinePosition analyzePosition(TimeRange other) {
    if (_hasBoundaryMatch(other)) {
      return EntityTimelinePosition.exactBoundaryMatch;
    }

    if (_areTimesSorted([start, other.start, other.end, end])) {
      return EntityTimelinePosition.contains;
    }

    if (_areTimesSorted([other.start, start, end, other.end])) {
      return EntityTimelinePosition.containedIn;
    }

    if (_areTimesSorted([start, other.start, end, other.end])) {
      return EntityTimelinePosition.startsBeforeEndsDuring;
    }

    if (_areTimesSorted([other.start, start, other.end, end])) {
      return EntityTimelinePosition.startsDuringEndsAfter;
    }

    if (_areTimesSorted([start, end, other.start, other.end])) {
      return EntityTimelinePosition.beforeEvent;
    }

    return EntityTimelinePosition.afterEvent;
  }

  static bool _isSameTime(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  /// Whether any boundary exactly matches another range's boundary
  bool _hasBoundaryMatch(TimeRange other) {
    return _isSameTime(start, other.start) ||
        _isSameTime(start, other.end) ||
        _isSameTime(end, other.start) ||
        _isSameTime(end, other.end);
  }

  bool _areTimesSorted(List<DateTime> dateTimes) {
    if (dateTimes.length <= 1) {
      return true;
    }

    for (int i = 1; i < dateTimes.length; i++) {
      if (dateTimes[i].isBefore(dateTimes[i - 1])) {
        return false;
      }
    }
    return true;
  }

  bool overlapsWith(TimeRange other) {
    return start.isBefore(other.end) && other.start.isBefore(end);
  }
}
