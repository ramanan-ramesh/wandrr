import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_timeline_position.dart';

import 'conflict_result.dart';
import 'entity_time_clamper.dart';
import 'time_range.dart';
import 'timeline_analyzer.dart';

/// Exclusion criteria for scanning conflicts.
/// Each entity type has its own exclusion list to avoid false positives.
class ConflictScanExclusions {
  final Set<String> transitIds;
  final Set<String> stayIds;
  final Set<String> sightIds;

  const ConflictScanExclusions({
    this.transitIds = const {},
    this.stayIds = const {},
    this.sightIds = const {},
  });

  /// Creates exclusions for a single transit
  factory ConflictScanExclusions.forTransit(String? transitId) {
    return ConflictScanExclusions(
      transitIds: transitId != null ? {transitId} : {},
    );
  }

  /// Creates exclusions for multiple transits (e.g., journey legs)
  factory ConflictScanExclusions.forTransits(Iterable<String> transitIds) {
    return ConflictScanExclusions(transitIds: transitIds.toSet());
  }

  /// Creates exclusions for a single stay
  factory ConflictScanExclusions.forStay(String? stayId) {
    return ConflictScanExclusions(
      stayIds: stayId != null ? {stayId} : {},
    );
  }

  /// Creates exclusions for multiple sights (e.g., in same itinerary)
  factory ConflictScanExclusions.forSights(Iterable<String> sightIds) {
    return ConflictScanExclusions(sightIds: sightIds.toSet());
  }

  /// Creates exclusions for a single sight
  factory ConflictScanExclusions.forSight(String? sightId) {
    return ConflictScanExclusions(
      sightIds: sightId != null ? {sightId} : {},
    );
  }

  /// Combines multiple exclusion sets
  ConflictScanExclusions merge(ConflictScanExclusions other) {
    return ConflictScanExclusions(
      transitIds: {...transitIds, ...other.transitIds},
      stayIds: {...stayIds, ...other.stayIds},
      sightIds: {...sightIds, ...other.sightIds},
    );
  }
}

/// Pure service for detecting timeline conflicts in trip data.
/// Contains only pure logic - no UI concerns or message building.
class TripConflictScanner {
  final TripDataFacade _tripData;

  /// Assumed duration for sight visits when checking conflicts
  static const _sightVisitDuration = Duration(minutes: 1);

  TripConflictScanner({required TripDataFacade tripData})
      : _tripData = tripData;

  /// Scans for all entities that conflict with the given time range.
  /// Uses type-specific exclusions to avoid false positives.
  AggregatedConflicts scanForConflicts({
    required TimeRange referenceRange,
    ConflictScanExclusions exclusions = const ConflictScanExclusions(),
  }) {
    return AggregatedConflicts(
      transitConflicts:
          _findTransitConflicts(referenceRange, exclusions.transitIds),
      stayConflicts: _findStayConflicts(referenceRange, exclusions.stayIds),
      sightConflicts: _findSightConflicts(referenceRange, exclusions.sightIds),
    );
  }

  /// Scans for transit conflicts only
  List<TransitConflict> scanTransitConflicts({
    required TimeRange referenceRange,
    Set<String> excludeTransitIds = const {},
  }) {
    return _findTransitConflicts(referenceRange, excludeTransitIds);
  }

  /// Scans for stay conflicts only
  List<StayConflict> scanStayConflicts({
    required TimeRange referenceRange,
    Set<String> excludeStayIds = const {},
  }) {
    return _findStayConflicts(referenceRange, excludeStayIds);
  }

  /// Scans for sight conflicts only
  List<SightConflict> scanSightConflicts({
    required TimeRange referenceRange,
    Set<String> excludeSightIds = const {},
  }) {
    return _findSightConflicts(referenceRange, excludeSightIds);
  }

  List<TransitConflict> _findTransitConflicts(
    TimeRange referenceRange,
    Set<String> excludeTransitIds,
  ) {
    final conflicts = <TransitConflict>[];

    for (final transit in _tripData.transitCollection.collectionItems) {
      // Skip if this transit is in the exclusion list
      if (transit.id != null && excludeTransitIds.contains(transit.id)) {
        continue;
      }
      if (transit.departureDateTime == null ||
          transit.arrivalDateTime == null) {
        continue;
      }

      final entityRange = TimeRange(
        start: transit.departureDateTime!,
        end: transit.arrivalDateTime!,
      );

      if (TimelineAnalyzer.hasConflict(referenceRange, entityRange)) {
        final position = TimelineAnalyzer.analyzePosition(
          entityRange: entityRange,
          referenceRange: referenceRange,
        );
        final clampedTransit =
            EntityTimeClamper.clampTransit(transit, referenceRange);

        conflicts.add(TransitConflict(
          entity: transit,
          entityTimeRange: entityRange,
          position: position,
          clampedEntity: clampedTransit,
        ));
      }
    }

    return conflicts;
  }

  List<StayConflict> _findStayConflicts(
    TimeRange referenceRange,
    Set<String> excludeStayIds,
  ) {
    final conflicts = <StayConflict>[];

    for (final stay in _tripData.lodgingCollection.collectionItems) {
      // Skip if this stay is in the exclusion list
      if (stay.id != null && excludeStayIds.contains(stay.id)) {
        continue;
      }
      if (stay.checkinDateTime == null || stay.checkoutDateTime == null) {
        continue;
      }

      final entityRange = TimeRange(
        start: stay.checkinDateTime!,
        end: stay.checkoutDateTime!,
      );

      // For stays, only check-in and check-out times are "blocked" points.
      // Activities (sights/transits) can happen DURING a stay (between check-in and check-out).
      // Only flag a conflict if the reference range's boundaries exactly match
      // the stay's check-in or check-out times.
      final hasCheckinConflict =
          _isTimeInRange(stay.checkinDateTime!, referenceRange);
      final hasCheckoutConflict =
          _isTimeInRange(stay.checkoutDateTime!, referenceRange);

      if (hasCheckinConflict || hasCheckoutConflict) {
        final position = TimelineAnalyzer.analyzePosition(
          entityRange: entityRange,
          referenceRange: referenceRange,
        );
        final clampedStay = EntityTimeClamper.clampStay(stay, referenceRange);

        conflicts.add(StayConflict(
          entity: stay,
          entityTimeRange: entityRange,
          position: position,
          clampedEntity: clampedStay,
        ));
      }
    }

    return conflicts;
  }

  /// Checks if a specific time falls within a range (exclusive of boundaries being during)
  /// or exactly matches a boundary of the range
  bool _isTimeInRange(DateTime time, TimeRange range) {
    return _isSameTime(time, range.start) ||
        _isSameTime(time, range.end) ||
        (time.isAfter(range.start) && time.isBefore(range.end));
  }

  static bool _isSameTime(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  List<SightConflict> _findSightConflicts(
    TimeRange referenceRange,
    Set<String> excludeSightIds,
  ) {
    final conflicts = <SightConflict>[];

    for (final itinerary in _tripData.itineraryCollection) {
      for (final sight in itinerary.planData.sights) {
        // Skip if this sight is in the exclusion list
        if (sight.id != null && excludeSightIds.contains(sight.id)) {
          continue;
        }
        if (sight.visitTime == null) continue;

        final entityRange = TimeRange(
          start: sight.visitTime!,
          end: sight.visitTime!.add(_sightVisitDuration),
        );

        if (TimelineAnalyzer.hasConflict(referenceRange, entityRange)) {
          final position = TimelineAnalyzer.analyzePosition(
            entityRange: entityRange,
            referenceRange: referenceRange,
          );
          if (position == EntityTimelinePosition.exactBoundaryMatch ||
              position == EntityTimelinePosition.overlapWithEndBoundary ||
              position == EntityTimelinePosition.overlapWithStartBoundary) {
            final clampedSight =
                EntityTimeClamper.clampSight(sight, referenceRange);

            conflicts.add(SightConflict(
              entity: sight,
              entityTimeRange: entityRange,
              position: position,
              clampedEntity: clampedSight,
            ));
          }
        }
      }
    }

    return conflicts;
  }
}
