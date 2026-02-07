/// Represents a time range with start and end bounds
class TimeRange {
  final DateTime start;
  final DateTime end;

  const TimeRange({required this.start, required this.end});

  /// Duration of the time range
  Duration get duration => end.difference(start);

  /// Whether this range overlaps with another range
  bool overlaps(TimeRange other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  /// Whether any boundary exactly matches another range's boundary
  bool hasBoundaryMatch(TimeRange other) {
    return _isSameTime(start, other.start) ||
        _isSameTime(start, other.end) ||
        _isSameTime(end, other.start) ||
        _isSameTime(end, other.end);
  }

  /// Whether this range has a conflict with another range
  /// A conflict is either an overlap or an exact boundary match
  bool conflictsWith(TimeRange other) {
    return hasBoundaryMatch(other) || overlaps(other);
  }

  /// Whether this range is completely contained within another range
  bool isContainedIn(TimeRange other) {
    return start.isAfter(other.start) && end.isBefore(other.end);
  }

  /// Whether another range is completely contained within this range
  bool contains(TimeRange other) {
    return other.start.isAfter(start) && other.end.isBefore(end);
  }

  /// Whether this range starts before another and ends during it
  bool overlapsStart(TimeRange other) {
    return start.isBefore(other.start) &&
        end.isAfter(other.start) &&
        end.isBefore(other.end);
  }

  /// Whether this range starts during another and ends after it
  bool overlapsEnd(TimeRange other) {
    return start.isAfter(other.start) &&
        start.isBefore(other.end) &&
        end.isAfter(other.end);
  }

  /// Whether this range is entirely before another
  bool isBefore(TimeRange other) => end.isBefore(other.start);

  /// Whether this range is entirely after another
  bool isAfter(TimeRange other) => start.isAfter(other.end);

  static bool _isSameTime(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }
}
