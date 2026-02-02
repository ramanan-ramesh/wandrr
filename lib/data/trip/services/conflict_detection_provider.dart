import 'package:wandrr/data/trip/models/trip_entity_update/trip_data_update_plan.dart';
import 'package:wandrr/data/trip/services/timeline_conflict_detector.dart';

/// Interface for entity editors that can detect timeline conflicts.
/// Implementers provide the current state of the entity being edited
/// and return a TripEntityUpdatePlan if conflicts exist.
abstract class ConflictDetectionProvider {
  /// Detects conflicts based on the current state of the entity.
  /// Returns null if no conflicts exist.
  TripDataUpdatePlan? detectConflicts(TimelineConflictDetector detector);

  /// Whether this is a new entity (create) or existing (update)
  bool get isNewEntity;
}
