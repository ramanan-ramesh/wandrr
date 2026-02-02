import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_data_update_plan.dart';
import 'package:wandrr/data/trip/services/conflict_detection_provider.dart';
import 'package:wandrr/data/trip/services/timeline_conflict_detector.dart';

/// Conflict detection provider for stays/lodgings.
/// Detects timeline conflicts when a stay's check-in/checkout times are set/changed.
class StayConflictDetectionProvider implements ConflictDetectionProvider {
  final LodgingFacade _stay;

  StayConflictDetectionProvider({
    required LodgingFacade stay,
  }) : _stay = stay;

  @override
  bool get isNewEntity => _stay.id == null || _stay.id!.isEmpty;

  @override
  TripDataUpdatePlan? detectConflicts(TimelineConflictDetector detector) {
    // Stays without check-in/checkout times cannot have conflicts
    if (_stay.checkinDateTime == null || _stay.checkoutDateTime == null) {
      return null;
    }

    return detector.detectStayConflicts(
      stay: _stay,
      isNewEntity: isNewEntity,
    );
  }
}
