import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_timeline_position.dart';

import 'time_range.dart';

/// Raw conflict data without UI-specific information.
/// This is pure data - no messages or formatting.
class ConflictResult<T extends TripEntity> {
  /// The entity that has a conflict
  final T entity;

  /// The time range of the conflicting entity
  final TimeRange entityTimeRange;

  /// The temporal position relative to the reference range
  final EntityTimelinePosition position;

  /// The clamped entity if clamping was possible, null otherwise
  final T? clampedEntity;

  /// Whether the entity can be clamped to resolve the conflict
  bool get canBeClampedToResolve => clampedEntity != null;

  /// Whether the entity must be deleted (cannot be clamped)
  bool get mustBeDeleted => clampedEntity == null;

  const ConflictResult({
    required this.entity,
    required this.entityTimeRange,
    required this.position,
    this.clampedEntity,
  });
}

/// Type alias for transit conflicts
typedef TransitConflict = ConflictResult<TransitFacade>;

/// Type alias for stay conflicts
typedef StayConflict = ConflictResult<LodgingFacade>;

/// Type alias for sight conflicts
typedef SightConflict = ConflictResult<SightFacade>;

/// Aggregated conflict results from analyzing a time range against trip data
class AggregatedConflicts {
  final List<TransitConflict> transitConflicts;
  final List<StayConflict> stayConflicts;
  final List<SightConflict> sightConflicts;

  const AggregatedConflicts({
    this.transitConflicts = const [],
    this.stayConflicts = const [],
    this.sightConflicts = const [],
  });

  /// Whether all conflicts have been resolved (no conflicts)
  bool get isEmpty =>
      transitConflicts.isEmpty &&
      stayConflicts.isEmpty &&
      sightConflicts.isEmpty;
}
