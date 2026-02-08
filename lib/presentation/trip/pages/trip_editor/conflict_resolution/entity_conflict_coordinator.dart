import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_conflict_detectors.dart';
import 'package:wandrr/data/trip/models/services/trip_conflict_scanner.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

import 'conflict_to_entity_change_adapter.dart';

/// Coordinates conflict detection for entity editors.
/// Uses TripConflictScanner for all conflict detection and converts results to UI-ready format.
///
/// This is the main entry point for conflict detection in the presentation layer.
class EntityConflictCoordinator {
  final TripConflictScanner _scanner;
  final TripDataFacade _tripData;

  EntityConflictCoordinator({required TripDataFacade tripData})
      : _tripData = tripData,
        _scanner = TripConflictScanner(tripData: tripData);

  /// Detects conflicts for trip metadata changes (dates/contributors).
  /// Uses TripConflictScanner.scanForMetadataUpdate() for consistency.
  TripEntityUpdatePlan<TripMetadataFacade>? detectTripMetadataConflicts(
    TripMetadataFacade editedMetadata,
  ) {
    final conflicts = _scanner.scanForMetadataUpdate(
      oldMetadata: _tripData.tripMetadata,
      newMetadata: editedMetadata,
    );
    if (conflicts == null) return null;

    return ConflictToEntityChangeAdapter.toMetadataUpdatePlan(conflicts);
  }

  /// Detects conflicts for a stay being added or edited.
  TripEntityUpdatePlan<LodgingFacade>? detectStayConflicts(
    LodgingFacade oldStay,
    LodgingFacade newStay, {
    required bool isNewEntity,
  }) {
    final detector = StayConflictDetector(
      stay: newStay,
      scanner: _scanner,
      isNewEntity: isNewEntity,
    );

    final conflicts = detector.detectConflicts(newStay);
    if (conflicts == null) return null;

    return ConflictToEntityChangeAdapter.toUpdatePlan<LodgingFacade>(
      oldEntity: oldStay,
      newEntity: newStay,
      conflicts: conflicts,
      tripStartDate: _tripData.tripMetadata.startDate!,
      endDate: _tripData.tripMetadata.endDate!,
    );
  }

  /// Detects conflicts for a multi-leg journey.
  TripEntityUpdatePlan<TransitFacade>? detectJourneyConflicts(
    TransitFacade oldTransit,
    List<TransitFacade> legs,
  ) {
    final detector = JourneyConflictDetector(legs: legs, scanner: _scanner);

    final conflicts = detector.detectConflicts(oldTransit);
    if (conflicts == null) return null;

    // Use first leg as the primary entity
    final newTransit = legs.isNotEmpty ? legs.first : oldTransit;
    return ConflictToEntityChangeAdapter.toUpdatePlan<TransitFacade>(
      oldEntity: oldTransit,
      newEntity: newTransit,
      conflicts: conflicts,
      tripStartDate: _tripData.tripMetadata.startDate!,
      endDate: _tripData.tripMetadata.endDate!,
    );
  }

  /// Detects conflicts for itinerary plan data (multiple sights).
  TripEntityUpdatePlan<ItineraryPlanData>? detectItineraryConflicts(
    ItineraryPlanData oldPlanData,
    ItineraryPlanData newPlanData, {
    Duration visitDuration = const Duration(hours: 2),
  }) {
    final detector = ItineraryConflictDetector(
      sights: newPlanData.sights,
      scanner: _scanner,
      visitDuration: visitDuration,
    );

    final conflicts = detector.detectConflicts(newPlanData);
    if (conflicts == null) return null;

    return ConflictToEntityChangeAdapter.toUpdatePlan<ItineraryPlanData>(
      oldEntity: oldPlanData,
      newEntity: newPlanData,
      conflicts: conflicts,
      tripStartDate: _tripData.tripMetadata.startDate!,
      endDate: _tripData.tripMetadata.endDate!,
    );
  }
}
