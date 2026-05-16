import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/services/conflict_detection/conflict_result.dart';
import 'package:wandrr/data/trip/services/conflict_detection/conflict_scanner.dart';
import 'package:wandrr/data/trip/services/conflict_detection/time_range.dart';

// =============================================================================
// ENTITY CONFLICT DETECTOR CONTRACT
// =============================================================================

/// Abstract contract for entity-specific conflict detectors.
abstract class EntityConflictDetector<T> {
  AggregatedConflicts? detectConflicts();

  /// Removes duplicate conflict results for the same entity ID.
  List<ConflictResult<E>> deduplicateConflicts<E extends TripEntity>(
    List<ConflictResult<E>> conflicts,
  ) {
    final seen = <String>{};
    final unique = <ConflictResult<E>>[];
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

// =============================================================================
// STAY CONFLICT DETECTOR
// =============================================================================

class StayConflictDetector extends EntityConflictDetector<LodgingFacade> {
  final LodgingFacade stay;
  final UnifiedConflictScanner scanner;
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
    final conflicts = scanner.scanForConflicts(
      referenceRange: referenceRange,
      sourceEntity: stay,
      exclusions: ScanExclusions.forEntity(stay),
    );
    return conflicts.isEmpty ? null : conflicts;
  }
}

// =============================================================================
// JOURNEY CONFLICT DETECTOR
// =============================================================================

class JourneyConflictDetector
    extends EntityConflictDetector<List<TransitFacade>> {
  final List<TransitFacade> legs;
  final UnifiedConflictScanner scanner;
  final bool isNewEntity;
  final Set<String> removedLegIds;

  JourneyConflictDetector({
    required this.legs,
    required this.scanner,
    required this.isNewEntity,
    this.removedLegIds = const {},
  });

  @override
  AggregatedConflicts? detectConflicts() {
    if (legs.isEmpty) {
      return null;
    }

    final allTransitConflicts = <TransitConflict>[];
    final allStayConflicts = <StayConflict>[];
    final allSightConflicts = <SightConflict>[];

    final legIds = legs
        .where((leg) => leg.id != null && leg.id!.isNotEmpty)
        .map((leg) => leg.id!)
        .toSet()
      ..addAll(removedLegIds);

    final exclusions = isNewEntity
        ? ScanExclusions.forTransits(removedLegIds)
        : ScanExclusions.forTransits(legIds);

    for (final leg in legs) {
      if (leg.departureDateTime == null || leg.arrivalDateTime == null) {
        continue;
      }
      final referenceRange = TimeRange(
        start: leg.departureDateTime!,
        end: leg.arrivalDateTime!,
      );
      final conflicts = scanner.scanForConflicts(
        referenceRange: referenceRange,
        sourceEntity: leg,
        exclusions: exclusions,
      );
      allTransitConflicts.addAll(conflicts.transitConflicts);
      allStayConflicts.addAll(conflicts.stayConflicts);
      allSightConflicts.addAll(conflicts.sightConflicts);
    }

    final aggregated = AggregatedConflicts(
      transitConflicts: deduplicateConflicts(allTransitConflicts),
      stayConflicts: deduplicateConflicts(allStayConflicts),
      sightConflicts: deduplicateConflicts(allSightConflicts),
    );
    return aggregated.isEmpty ? null : aggregated;
  }
}

// =============================================================================
// ITINERARY CONFLICT DETECTOR
// =============================================================================

class ItineraryConflictDetector
    extends EntityConflictDetector<List<SightFacade>> {
  final List<SightFacade> sights;
  final UnifiedConflictScanner scanner;
  final bool isNewEntity;

  ItineraryConflictDetector({
    required this.sights,
    required this.scanner,
    required this.isNewEntity,
  });

  @override
  AggregatedConflicts? detectConflicts() {
    final allTransitConflicts = <TransitConflict>[];
    final allStayConflicts = <StayConflict>[];
    final allSightConflicts = <SightConflict>[];

    final sightIds = sights
        .where((sight) => sight.id != null && sight.id!.isNotEmpty)
        .map((sight) => sight.id!)
        .toSet();

    final exclusions = isNewEntity
        ? const ScanExclusions()
        : ScanExclusions.forSights(sightIds);

    for (final sight in sights) {
      if (sight.visitTime == null) {
        continue;
      }
      final referenceRange = TimeRange(
        start: sight.visitTime!,
        end: sight.visitTime!.add(const Duration(minutes: 1)),
      );
      final conflicts = scanner.scanForConflicts(
        referenceRange: referenceRange,
        sourceEntity: sight,
        exclusions: exclusions,
      );
      allTransitConflicts.addAll(conflicts.transitConflicts);
      allStayConflicts.addAll(conflicts.stayConflicts);
      allSightConflicts.addAll(conflicts.sightConflicts);
    }

    final aggregated = AggregatedConflicts(
      transitConflicts: deduplicateConflicts(allTransitConflicts),
      stayConflicts: deduplicateConflicts(allStayConflicts),
      sightConflicts: deduplicateConflicts(allSightConflicts),
    );
    return aggregated.isEmpty ? null : aggregated;
  }
}
