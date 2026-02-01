import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_metadata_update.dart';
import 'package:wandrr/data/trip/services/conflict_detection_provider.dart';
import 'package:wandrr/data/trip/services/timeline_conflict_detector.dart';

/// Conflict detection provider for itinerary plan data.
/// Aggregates conflicts from all sights within the itinerary day.
class ItineraryPlanDataConflictDetectionProvider
    implements ConflictDetectionProvider {
  final ItineraryPlanData _planData;

  ItineraryPlanDataConflictDetectionProvider({
    required ItineraryPlanData planData,
  }) : _planData = planData;

  @override
  bool get isNewEntity => _planData.id == null || _planData.id!.isEmpty;

  @override
  TripEntityUpdatePlan? detectConflicts(TimelineConflictDetector detector) {
    final allTransitChanges = <EntityChange<TransitFacade>>[];
    final allStayChanges = <EntityChange<LodgingFacade>>[];
    final allSightChanges = <EntityChange<SightFacade>>[];

    // Check each sight in the plan data for conflicts
    for (final sight in _planData.sights) {
      // Only check sights that have a visit time
      if (sight.visitTime == null) {
        continue;
      }

      final isNewSight = sight.id == null || sight.id!.isEmpty;
      final plan = detector.detectSightConflicts(
        sight: sight,
        isNewEntity: isNewSight,
      );

      if (plan != null) {
        // Filter out conflicts with other sights in the same itinerary
        final sightIdsInPlanData = _planData.sights
            .where((s) => s.id != null && s.id!.isNotEmpty)
            .map((s) => s.id!)
            .toSet();

        final filteredSightChanges = plan.sightChanges.where((change) {
          final sightId = change.originalEntity.id;
          return sightId == null || !sightIdsInPlanData.contains(sightId);
        }).toList();

        allTransitChanges.addAll(plan.transitChanges);
        allStayChanges.addAll(plan.stayChanges);
        allSightChanges.addAll(filteredSightChanges);
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

    final tripData = detector.tripData;
    return TripEntityUpdatePlan(
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
      final entity = change.originalEntity;
      final id = entity.id;

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
