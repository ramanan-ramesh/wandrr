import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_data_update_plan.dart';
import 'package:wandrr/data/trip/services/conflict_detection_provider.dart';
import 'package:wandrr/data/trip/services/timeline_conflict_detector.dart';

/// Conflict detection provider for multi-leg transit journeys.
/// Aggregates conflicts from all legs in the journey into a single plan.
class JourneyConflictDetectionProvider implements ConflictDetectionProvider {
  /// Callback to get current legs - allows dynamic leg retrieval
  final List<TransitFacade> Function() _legsProvider;

  /// Gets current legs from the provider
  List<TransitFacade> get _legs => _legsProvider();

  /// IDs of legs that already exist in the database
  Set<String> get _existingLegIds => _legs
      .where((l) => l.id != null && l.id!.isNotEmpty)
      .map((l) => l.id!)
      .toSet();

  /// Creates a provider with a static list of legs
  JourneyConflictDetectionProvider({
    required List<TransitFacade> legs,
  }) : _legsProvider = (() => legs);

  /// Creates a provider with a dynamic legs callback
  /// Use this when legs can change during editing (e.g., JourneyEditor)
  JourneyConflictDetectionProvider.dynamic({
    required List<TransitFacade> Function() legsProvider,
  }) : _legsProvider = legsProvider;

  @override
  bool get isNewEntity => _existingLegIds.isEmpty;

  @override
  TripDataUpdatePlan? detectConflicts(TimelineConflictDetector detector) {
    final legs = _legs;
    final allTransitChanges = <EntityChange<TransitFacade>>[];
    final allStayChanges = <EntityChange<LodgingFacade>>[];
    final allSightChanges = <EntityChange<SightFacade>>[];

    // Collect IDs of all legs in this journey to exclude from conflict detection
    final journeyLegIds = legs
        .where((l) => l.id != null && l.id!.isNotEmpty)
        .map((l) => l.id!)
        .toSet();

    for (final leg in legs) {
      if (leg.departureDateTime == null || leg.arrivalDateTime == null) {
        continue;
      }

      final isNewLeg = leg.id == null || leg.id!.isEmpty;
      final plan = detector.detectTransitConflicts(
        transit: leg,
        isNewEntity: isNewLeg,
      );

      if (plan != null) {
        // Filter out conflicts with other legs in the same journey
        final filteredTransitChanges = plan.transitChanges.where((change) {
          final transitId = change.originalEntity.id;
          return transitId == null || !journeyLegIds.contains(transitId);
        }).toList();

        allTransitChanges.addAll(filteredTransitChanges);
        allStayChanges.addAll(plan.stayChanges);
        allSightChanges.addAll(plan.sightChanges);
      }
    }

    // Deduplicate by entity ID
    final uniqueTransitChanges =
        _deduplicateChanges<TransitFacade>(allTransitChanges);
    final uniqueStayChanges =
        _deduplicateChanges<LodgingFacade>(allStayChanges);
    final uniqueSightChanges =
        _deduplicateChanges<SightFacade>(allSightChanges);

    if (uniqueTransitChanges.isEmpty &&
        uniqueStayChanges.isEmpty &&
        uniqueSightChanges.isEmpty) {
      return null;
    }

    // Get trip dates from the first leg
    final tripData = detector.tripData;
    return TripDataUpdatePlan(
      transitChanges: uniqueTransitChanges,
      stayChanges: uniqueStayChanges,
      sightChanges: uniqueSightChanges,
      tripStartDate: tripData.tripMetadata.startDate!,
      tripEndDate: tripData.tripMetadata.endDate!,
    );
  }

  List<EntityChange<T>> _deduplicateChanges<T extends TripEntity<T>>(
      List<EntityChange<T>> changes) {
    final seen = <String>{};
    final unique = <EntityChange<T>>[];

    for (final change in changes) {
      final id = change.originalEntity.id;
      if (id != null && !seen.contains(id)) {
        seen.add(id);
        unique.add(change);
      } else if (id == null) {
        unique.add(change);
      }
    }

    return unique;
  }
}
