import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/time_range.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'conflict_result.dart';
import 'unified_conflict_scanner.dart';

// =============================================================================
// ENTITY CONFLICT DETECTOR - Unified interface
// =============================================================================

/// Base class for entity-specific conflict detectors.
///
/// Each detector knows how to:
/// - Build exclusions for its entity type
/// - Build time ranges from entity data
/// - Aggregate conflicts from multiple sub-entities (e.g., journey legs)
abstract class EntityConflictDetector<T> {
  final UnifiedConflictScanner scanner;

  const EntityConflictDetector({required this.scanner});

  /// Detects conflicts for the entity.
  /// Returns null if no conflicts found.
  AggregatedConflicts? detectConflicts();

  /// Helper to deduplicate conflicts by entity ID
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

/// Detects conflicts when editing a stay (lodging).
class StayConflictDetector extends EntityConflictDetector<LodgingFacade> {
  final LodgingFacade stay;
  final bool isNewEntity;

  StayConflictDetector({
    required this.stay,
    required super.scanner,
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

    // Exclude the stay being edited (unless it's new)
    final exclusions = ScanExclusions.forStay(isNewEntity ? null : stay.id);

    final conflicts = scanner.scanForConflicts(
      referenceRange: referenceRange,
      sourceEntity: stay,
      exclusions: exclusions,
    );

    return conflicts.isEmpty ? null : conflicts;
  }
}

// =============================================================================
// JOURNEY CONFLICT DETECTOR
// =============================================================================

/// Detects conflicts when editing a multi-leg journey (transits).
///
/// A journey consists of multiple transit legs. We need to:
/// - Check each leg's time range for conflicts
/// - Exclude all legs from conflict detection (they can overlap each other)
/// - Deduplicate conflicts found across multiple legs
class JourneyConflictDetector
    extends EntityConflictDetector<List<TransitFacade>> {
  final List<TransitFacade> legs;
  final bool isNewEntity;

  JourneyConflictDetector({
    required this.legs,
    required super.scanner,
    required this.isNewEntity,
  });

  @override
  AggregatedConflicts? detectConflicts() {
    if (legs.isEmpty) return null;

    final allTransitConflicts = <TransitConflict>[];
    final allStayConflicts = <StayConflict>[];
    final allSightConflicts = <SightConflict>[];

    // Collect IDs of all legs to exclude from conflict detection
    final legIds = legs
        .where((leg) => leg.id != null && leg.id!.isNotEmpty)
        .map((leg) => leg.id!)
        .toSet();

    // For new entities, we don't have IDs yet, so no exclusions
    final exclusions = isNewEntity
        ? const ScanExclusions()
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

    // Deduplicate conflicts found across multiple legs
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

/// Detects conflicts when editing an itinerary (multiple sights).
///
/// An itinerary contains multiple sights. We need to:
/// - Check each sight's visit time for conflicts
/// - Exclude all sights in the itinerary from conflict detection
/// - Deduplicate conflicts found across multiple sights
class ItineraryConflictDetector
    extends EntityConflictDetector<List<SightFacade>> {
  final List<SightFacade> sights;
  final bool isNewEntity;

  ItineraryConflictDetector({
    required this.sights,
    required super.scanner,
    required this.isNewEntity,
  });

  @override
  AggregatedConflicts? detectConflicts() {
    final allTransitConflicts = <TransitConflict>[];
    final allStayConflicts = <StayConflict>[];
    final allSightConflicts = <SightConflict>[];

    // Collect IDs of all sights to exclude from conflict detection
    final sightIds = sights
        .where((sight) => sight.id != null && sight.id!.isNotEmpty)
        .map((sight) => sight.id!)
        .toSet();

    // For new entities, we don't have IDs yet, so no exclusions
    final exclusions = isNewEntity
        ? const ScanExclusions()
        : ScanExclusions.forSights(sightIds);

    for (final sight in sights) {
      if (sight.visitTime == null) continue;

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

    // Deduplicate conflicts found across multiple sights
    final aggregated = AggregatedConflicts(
      transitConflicts: deduplicateConflicts(allTransitConflicts),
      stayConflicts: deduplicateConflicts(allStayConflicts),
      sightConflicts: deduplicateConflicts(allSightConflicts),
    );

    return aggregated.isEmpty ? null : aggregated;
  }
}
