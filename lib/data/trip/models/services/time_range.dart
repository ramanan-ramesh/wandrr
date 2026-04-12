import 'package:wandrr/data/trip/models/services/entity_timeline_position.dart';

/// Represents a time range with start and end bounds
class TimeRange {
  final DateTime start;
  final DateTime end;

  const TimeRange({required this.start, required this.end});

  /// Analyzes the temporal position of this range relative to [other].
  ///
  /// Note: Adjacent events (this.end == other.start or this.start == other.end)
  /// are classified as beforeEvent or afterEvent, NOT as overlapping.
  /// Only truly overlapping boundaries (start==start or end==end) are
  /// classified as exactBoundaryMatch.
  EntityTimelinePosition analyzePosition(TimeRange other) {
    // Check for exact overlapping boundaries (NOT adjacent events).
    // start==other.start or end==other.end means true overlap.
    // start==other.end or end==other.start means adjacent (no overlap).
    if (_hasOverlappingBoundary(other)) {
      return EntityTimelinePosition.exactBoundaryMatch;
    }

    // Adjacent events: this ends when other starts → this is before other
    if (_isSameTime(end, other.start)) {
      return EntityTimelinePosition.beforeEvent;
    }

    // Adjacent events: other ends when this starts → this is after other
    if (_isSameTime(start, other.end)) {
      return EntityTimelinePosition.afterEvent;
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

  /// Whether boundaries overlap in a way that indicates true temporal overlap.
  /// Only start==start or end==end counts. Adjacent (end==start or start==end)
  /// does NOT count as overlapping.
  bool _hasOverlappingBoundary(TimeRange other) {
    return _isSameTime(start, other.start) || _isSameTime(end, other.end);
  }

  bool _areTimesSorted(List<DateTime> dateTimes) {
    if (dateTimes.length <= 1) {
      return true;
    }

    for (var i = 1; i < dateTimes.length; i++) {
      if (dateTimes[i].isBefore(dateTimes[i - 1])) {
        return false;
      }
    }
    return true;
  }

  //TODO: Use analyzePosition API
  bool overlapsWith(TimeRange other) {
    return start.isBefore(other.end) && other.start.isBefore(end);
  }
}
