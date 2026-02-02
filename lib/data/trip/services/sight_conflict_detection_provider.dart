import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_data_update_plan.dart';
import 'package:wandrr/data/trip/services/conflict_detection_provider.dart';
import 'package:wandrr/data/trip/services/timeline_conflict_detector.dart';

/// Conflict detection provider for sights.
/// Detects timeline conflicts when a sight's visit time is set/changed.
class SightConflictDetectionProvider implements ConflictDetectionProvider {
  final SightFacade _sight;

  SightConflictDetectionProvider({
    required SightFacade sight,
  }) : _sight = sight;

  @override
  bool get isNewEntity => _sight.id == null || _sight.id!.isEmpty;

  @override
  TripDataUpdatePlan? detectConflicts(TimelineConflictDetector detector) {
    // Sights without visit time cannot have conflicts
    if (_sight.visitTime == null) {
      return null;
    }

    return detector.detectSightConflicts(
      sight: _sight,
      isNewEntity: isNewEntity,
    );
  }
}
