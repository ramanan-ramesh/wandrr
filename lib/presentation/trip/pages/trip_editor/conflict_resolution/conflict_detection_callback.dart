import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Callback for entity-specific conflict detection.
/// Returns null if no conflicts exist.
///
/// This replaces the deprecated ConflictDetectionProvider pattern.
typedef ConflictDetectionCallback<T extends TripEntity>
    = TripEntityUpdatePlan<T>? Function();
