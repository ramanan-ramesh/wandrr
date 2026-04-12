import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/time_range.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'conflict_result.dart';
import 'unified_conflict_scanner.dart';

// =============================================================================
// ENTITY CONFLICT DETECTOR - Unified interface following SOLID principles
// =============================================================================

/// Base class for entity-specific conflict detectors.
///
/// Each detector knows how to:
/// - Build exclusions for its entity type (to avoid self-conflicts)
/// - Build time ranges from entity data
/// - Aggregate conflicts from multiple sub-entities (e.g., journey legs)
///
/// The isNewEntity parameter is consistently used across all detectors to:
/// - Exclude the entity being edited from conflict scanning (when editing existing)
/// - Include all entities in scanning (when creating new, since no ID exists yet)
abstract class EntityConflictDetector<T> {
  final UnifiedConflictScanner scanner;

  const EntityConflictDetector({required this.scanner});

  /// Detects conflicts for the entity.
  /// Returns null if no conflicts found.
  AggregatedConflicts? detectConflicts();

  /// Helper to deduplicate conflicts by entity ID.
  ///
  /// When scanning multiple sub-entities (journey legs, itinerary sights),
  /// the same conflicting entity might be detected multiple times.
  /// This ensures each conflict is only reported once.
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
        // Entities without IDs (new entities) are always included
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
///
/// A stay has a single continuous time range (check-in to check-out).
/// Conflicts are detected against all transits, other stays, and sights
/// whose times overlap with this stay.
class StayConflictDetector extends EntityConflictDetector<LodgingFacade> {
  final LodgingFacade stay;

  /// Whether this is a new entity being created (no ID yet).
  ///
  /// When true: All entities are scanned (no exclusions needed).
  /// When false: The stay's ID is excluded to avoid self-conflict detection.
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

    final exclusions = ScanExclusions.forEntity(stay);

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
/// A journey consists of multiple transit legs. Each leg has its own time range.
/// We scan all legs and aggregate conflicts, deduplicating to avoid reporting
/// the same conflicting entity multiple times.
///
/// All journey legs are excluded from conflict detection since they can
/// overlap with each other (e.g., layovers).
class JourneyConflictDetector
    extends EntityConflictDetector<List<TransitFacade>> {
  final List<TransitFacade> legs;

  /// Whether this journey is newly created (no IDs yet).
  ///
  /// When true: All entities are scanned (no exclusions needed).
  /// When false: All leg IDs are excluded to avoid self-conflict detection.
  final bool isNewEntity;

  JourneyConflictDetector({
    required this.legs,
    required super.scanner,
    required this.isNewEntity,
  });

  @override
  AggregatedConflicts? detectConflicts() {
    if (legs.isEmpty) {
      return null;
    }

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
/// An itinerary contains multiple sights for a single day. Each sight
/// has an optional visit time. We scan all sights with times and aggregate
/// conflicts, deduplicating to avoid reporting the same entity multiple times.
///
/// All itinerary sights are excluded from conflict detection since they
/// belong to the same editing session.
class ItineraryConflictDetector
    extends EntityConflictDetector<List<SightFacade>> {
  final List<SightFacade> sights;

  /// Whether this itinerary is newly created (no IDs yet).
  ///
  /// When true: All entities are scanned (no exclusions needed).
  /// When false: All sight IDs are excluded to avoid self-conflict detection.
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

    // Deduplicate conflicts found across multiple sights
    final aggregated = AggregatedConflicts(
      transitConflicts: deduplicateConflicts(allTransitConflicts),
      stayConflicts: deduplicateConflicts(allStayConflicts),
      sightConflicts: deduplicateConflicts(allSightConflicts),
    );

    return aggregated.isEmpty ? null : aggregated;
  }
}
