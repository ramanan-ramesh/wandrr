import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_timeline_position.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

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

/// Conflicts from trip metadata changes (date range or contributor changes).
/// This is similar to AggregatedConflicts but also includes expense entities
/// for contributor change handling.
class MetadataUpdateConflicts extends AggregatedConflicts {
  /// All expense-bearing entities (for contributor split updates)
  final List<ExpenseBearingTripEntity> expenseEntities;

  /// The old metadata before the update
  final TripMetadataFacade oldMetadata;

  /// The new metadata after the update
  final TripMetadataFacade newMetadata;

  const MetadataUpdateConflicts({
    super.transitConflicts = const [],
    super.stayConflicts = const [],
    super.sightConflicts = const [],
    this.expenseEntities = const [],
    required this.oldMetadata,
    required this.newMetadata,
  });

  /// Whether all conflicts have been resolved (no conflicts)
  @override
  bool get isEmpty => super.isEmpty && expenseEntities.isEmpty;
}
