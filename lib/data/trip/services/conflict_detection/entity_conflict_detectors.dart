import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/services/conflict_detection/conflict_detection.dart';

/// Base interface for entity-specific conflict detection.
/// Each trip entity type (Transit, Stay, Sight) has its own implementation.
abstract class EntityConflictDetector<T> {
  /// Detects conflicts for the given entity
  AggregatedConflicts? detectConflicts();
}

/// Conflict detector for multi-leg journeys
class JourneyConflictDetector
    implements EntityConflictDetector<List<TransitFacade>> {
  final List<TransitFacade> legs;
  final TripConflictScanner scanner;

  JourneyConflictDetector({
    required this.legs,
    required this.scanner,
  });

  @override
  AggregatedConflicts? detectConflicts() {
    final allConflicts = <TransitConflict>[];
    final allStayConflicts = <StayConflict>[];
    final allSightConflicts = <SightConflict>[];

    // Collect IDs of all legs to exclude
    final legIds = legs
        .where((l) => l.id != null && l.id!.isNotEmpty)
        .map((l) => l.id!)
        .toSet();

    for (final leg in legs) {
      if (leg.departureDateTime == null || leg.arrivalDateTime == null) {
        continue;
      }

      final referenceRange = TimeRange(
        start: leg.departureDateTime!,
        end: leg.arrivalDateTime!,
      );

      final exclusions = ConflictScanExclusions.forTransits(legIds);

      final conflicts = scanner.scanForConflicts(
        referenceRange: referenceRange,
        exclusions: exclusions,
      );

      allConflicts.addAll(conflicts.transitConflicts);
      allStayConflicts.addAll(conflicts.stayConflicts);
      allSightConflicts.addAll(conflicts.sightConflicts);
    }

    // Deduplicate
    final uniqueTransitConflicts = _deduplicate(allConflicts);
    final uniqueStayConflicts = _deduplicate(allStayConflicts);
    final uniqueSightConflicts = _deduplicate(allSightConflicts);

    final aggregated = AggregatedConflicts(
      transitConflicts: uniqueTransitConflicts,
      stayConflicts: uniqueStayConflicts,
      sightConflicts: uniqueSightConflicts,
    );

    return aggregated.isEmpty ? null : aggregated;
  }

  List<ConflictResult<T>> _deduplicate<T extends TripEntity<T>>(
    List<ConflictResult<T>> conflicts,
  ) {
    final seen = <String>{};
    final unique = <ConflictResult<T>>[];

    for (final conflict in conflicts) {
      final id = conflict.entity.id;
      if (id != null && !seen.contains(id)) {
        seen.add(id);
        unique.add(conflict);
      } else if (id == null) {
        unique.add(conflict);
      }
    }

    return unique;
  }
}

/// Conflict detector for stays
class StayConflictDetector implements EntityConflictDetector<LodgingFacade> {
  final LodgingFacade stay;
  final TripConflictScanner scanner;
  final bool isNewEntity;

  StayConflictDetector({
    required this.stay,
    required this.scanner,
    required this.isNewEntity,
  });

  @override
  AggregatedConflicts? detectConflicts() {
    if (stay.checkinDateTime == null || stay.checkoutDateTime == null) {
      return null;
    }

    final referenceRange = TimeRange(
      start: stay.checkinDateTime!,
      end: stay.checkoutDateTime!,
    );

    final exclusions = ConflictScanExclusions.forStay(
      isNewEntity ? null : stay.id,
    );

    final conflicts = scanner.scanForConflicts(
      referenceRange: referenceRange,
      exclusions: exclusions,
    );

    return conflicts.isEmpty ? null : conflicts;
  }
}

/// Conflict detector for itinerary plan data (multiple sights)
class ItineraryConflictDetector
    implements EntityConflictDetector<Iterable<SightFacade>> {
  final Iterable<SightFacade> sights;
  final TripConflictScanner scanner;
  final Duration visitDuration;

  ItineraryConflictDetector({
    required this.sights,
    required this.scanner,
    this.visitDuration = const Duration(hours: 2),
  });

  @override
  AggregatedConflicts? detectConflicts() {
    final allConflicts = <TransitConflict>[];
    final allStayConflicts = <StayConflict>[];
    final allSightConflicts = <SightConflict>[];

    // Collect IDs of all sights to exclude
    final sightIds = sights
        .where((s) => s.id != null && s.id!.isNotEmpty)
        .map((s) => s.id!)
        .toSet();

    for (final sight in sights) {
      if (sight.visitTime == null) continue;

      final referenceRange = TimeRange(
        start: sight.visitTime!,
        end: sight.visitTime!.add(visitDuration),
      );

      final exclusions = ConflictScanExclusions.forSights(sightIds);

      final conflicts = scanner.scanForConflicts(
        referenceRange: referenceRange,
        exclusions: exclusions,
      );

      allConflicts.addAll(conflicts.transitConflicts);
      allStayConflicts.addAll(conflicts.stayConflicts);
      allSightConflicts.addAll(conflicts.sightConflicts);
    }

    // Deduplicate
    final uniqueTransitConflicts = _deduplicate(allConflicts);
    final uniqueStayConflicts = _deduplicate(allStayConflicts);
    final uniqueSightConflicts = _deduplicate(allSightConflicts);

    final aggregated = AggregatedConflicts(
      transitConflicts: uniqueTransitConflicts,
      stayConflicts: uniqueStayConflicts,
      sightConflicts: uniqueSightConflicts,
    );

    return aggregated.isEmpty ? null : aggregated;
  }

  List<ConflictResult<T>> _deduplicate<T extends TripEntity<T>>(
    List<ConflictResult<T>> conflicts,
  ) {
    final seen = <String>{};
    final unique = <ConflictResult<T>>[];

    for (final conflict in conflicts) {
      final id = conflict.entity.id;
      if (id != null && !seen.contains(id)) {
        seen.add(id);
        unique.add(conflict);
      } else if (id == null) {
        unique.add(conflict);
      }
    }

    return unique;
  }
}
