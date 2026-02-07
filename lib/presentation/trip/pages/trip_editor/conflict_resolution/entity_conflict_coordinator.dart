import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change_context.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_data_update_plan.dart';
import 'package:wandrr/data/trip/services/conflict_detection/conflict_detection.dart';

import 'conflict_to_entity_change_adapter.dart';

/// Coordinates conflict detection for entity editors.
/// Uses entity-specific detectors and converts results to UI-ready format.
///
/// This is the main entry point for conflict detection in the presentation layer.
class EntityConflictCoordinator {
  final TripConflictScanner _scanner;
  final TripDataFacade _tripData;

  EntityConflictCoordinator({required TripDataFacade tripData})
      : _tripData = tripData,
        _scanner = TripConflictScanner(tripData: tripData);

  /// Detects conflicts for a transit being added or edited.
  TripDataUpdatePlan? detectTransitConflicts(
    TransitFacade transit, {
    required bool isNewEntity,
  }) {
    final detector = TransitConflictDetector(
      transit: transit,
      scanner: _scanner,
      isNewEntity: isNewEntity,
    );

    final conflicts = detector.detectConflicts();
    if (conflicts == null) return null;

    return ConflictToEntityChangeAdapter.toUpdatePlan(
      conflicts: conflicts,
      tripStartDate: _tripData.tripMetadata.startDate!,
      tripEndDate: _tripData.tripMetadata.endDate!,
      context: EntityChangeContext.timelineConflict,
    );
  }

  /// Detects conflicts for a stay being added or edited.
  TripDataUpdatePlan? detectStayConflicts(
    LodgingFacade stay, {
    required bool isNewEntity,
  }) {
    final detector = StayConflictDetector(
      stay: stay,
      scanner: _scanner,
      isNewEntity: isNewEntity,
    );

    final conflicts = detector.detectConflicts();
    if (conflicts == null) return null;

    return ConflictToEntityChangeAdapter.toUpdatePlan(
      conflicts: conflicts,
      tripStartDate: _tripData.tripMetadata.startDate!,
      tripEndDate: _tripData.tripMetadata.endDate!,
      context: EntityChangeContext.timelineConflict,
    );
  }

  /// Detects conflicts for a sight being added or edited.
  TripDataUpdatePlan? detectSightConflicts(
    SightFacade sight, {
    required bool isNewEntity,
    Duration visitDuration = const Duration(hours: 2),
  }) {
    final detector = SightConflictDetector(
      sight: sight,
      scanner: _scanner,
      isNewEntity: isNewEntity,
      visitDuration: visitDuration,
    );

    final conflicts = detector.detectConflicts();
    if (conflicts == null) return null;

    return ConflictToEntityChangeAdapter.toUpdatePlan(
      conflicts: conflicts,
      tripStartDate: _tripData.tripMetadata.startDate!,
      tripEndDate: _tripData.tripMetadata.endDate!,
      context: EntityChangeContext.timelineConflict,
    );
  }

  /// Detects conflicts for a multi-leg journey.
  TripDataUpdatePlan? detectJourneyConflicts(List<TransitFacade> legs) {
    final detector = JourneyConflictDetector(
      legs: legs,
      scanner: _scanner,
    );

    final conflicts = detector.detectConflicts();
    if (conflicts == null) return null;

    return ConflictToEntityChangeAdapter.toUpdatePlan(
      conflicts: conflicts,
      tripStartDate: _tripData.tripMetadata.startDate!,
      tripEndDate: _tripData.tripMetadata.endDate!,
      context: EntityChangeContext.timelineConflict,
    );
  }

  /// Detects conflicts for itinerary plan data (multiple sights).
  TripDataUpdatePlan? detectItineraryConflicts(
    ItineraryPlanData planData, {
    Duration visitDuration = const Duration(hours: 2),
  }) {
    final detector = ItineraryConflictDetector(
      sights: planData.sights,
      scanner: _scanner,
      visitDuration: visitDuration,
    );

    final conflicts = detector.detectConflicts();
    if (conflicts == null) return null;

    return ConflictToEntityChangeAdapter.toUpdatePlan(
      conflicts: conflicts,
      tripStartDate: _tripData.tripMetadata.startDate!,
      tripEndDate: _tripData.tripMetadata.endDate!,
      context: EntityChangeContext.timelineConflict,
    );
  }
}
