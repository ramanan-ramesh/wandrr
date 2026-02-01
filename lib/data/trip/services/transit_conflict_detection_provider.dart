import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_metadata_update.dart';
import 'package:wandrr/data/trip/services/conflict_detection_provider.dart';
import 'package:wandrr/data/trip/services/timeline_conflict_detector.dart';

/// Conflict detection provider for single transit legs.
/// For multi-leg journeys, use JourneyConflictDetectionProvider instead.
class TransitConflictDetectionProvider implements ConflictDetectionProvider {
  final TransitFacade _transit;

  TransitConflictDetectionProvider({
    required TransitFacade transit,
  }) : _transit = transit;

  @override
  bool get isNewEntity => _transit.id == null || _transit.id!.isEmpty;

  @override
  TripEntityUpdatePlan? detectConflicts(TimelineConflictDetector detector) {
    // Transits without departure/arrival times cannot have conflicts
    if (_transit.departureDateTime == null ||
        _transit.arrivalDateTime == null) {
      return null;
    }

    return detector.detectTransitConflicts(
      transit: _transit,
      isNewEntity: isNewEntity,
    );
  }
}
