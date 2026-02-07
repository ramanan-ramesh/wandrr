import 'package:wandrr/data/trip/models/trip_entity_update/trip_data_update_plan.dart';

/// Callback for entity-specific conflict detection.
/// Returns null if no conflicts exist.
///
/// This replaces the deprecated ConflictDetectionProvider pattern.
typedef ConflictDetectionCallback = TripDataUpdatePlan? Function();
