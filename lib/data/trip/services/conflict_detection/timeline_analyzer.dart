import 'package:wandrr/data/trip/models/trip_entity_update/entity_timeline_position.dart';

import 'time_range.dart';

/// Pure logic for analyzing temporal relationships between time ranges.
/// Contains no UI-specific code or message building.
class TimelineAnalyzer {
  const TimelineAnalyzer._();

  /// Determines the temporal relationship between an entity's time range
  /// and a reference time range.
  static EntityTimelinePosition analyzePosition({
    required TimeRange entityRange,
    required TimeRange referenceRange,
  }) {
    // Check boundary matches first
    if (entityRange.hasBoundaryMatch(referenceRange)) {
      return EntityTimelinePosition.exactBoundaryMatch;
    }

    // Entity is completely within reference range
    if (entityRange.isContainedIn(referenceRange)) {
      return EntityTimelinePosition.duringEvent;
    }

    // Entity overlaps start boundary
    if (entityRange.overlapsStart(referenceRange)) {
      return EntityTimelinePosition.overlapWithStartBoundary;
    }

    // Entity overlaps end boundary
    if (entityRange.overlapsEnd(referenceRange)) {
      return EntityTimelinePosition.overlapWithEndBoundary;
    }

    // Entity is entirely before reference
    if (entityRange.isBefore(referenceRange)) {
      return EntityTimelinePosition.beforeEvent;
    }

    // Entity is entirely after reference
    if (entityRange.isAfter(referenceRange)) {
      return EntityTimelinePosition.afterEvent;
    }

    // Fallback - should not reach here with valid ranges
    return EntityTimelinePosition.overlapWithStartBoundary;
  }

  /// Checks if two time ranges have a conflict.
  /// A conflict is either an overlap or an exact boundary match.
  static bool hasConflict(TimeRange range1, TimeRange range2) {
    return range1.conflictsWith(range2);
  }
}
