import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/services/conflict_detection/clamping_strategies.dart';
import 'package:wandrr/data/trip/services/conflict_detection/conflict_result.dart';
import 'package:wandrr/data/trip/services/conflict_detection/entity_change.dart';
import 'package:wandrr/data/trip/services/conflict_detection/entity_timeline_position.dart';
import 'package:wandrr/data/trip/services/conflict_detection/time_range.dart';

// =============================================================================
// EXCLUSION CONFIGURATION
// =============================================================================

/// Configuration for excluding entities from conflict scanning.
/// Prevents false positives when comparing an entity against itself
/// or related entities (e.g., journey legs, itinerary sights).
class ScanExclusions {
  final Set<String> transitIds;
  final Set<String> stayIds;
  final Set<String> sightIds;

  const ScanExclusions({
    this.transitIds = const {},
    this.stayIds = const {},
    this.sightIds = const {},
  });

  /// Creates exclusions for a single entity
  factory ScanExclusions.forEntity(TripEntity entity) {
    if (entity.id == null || entity.id!.isEmpty) {
      return const ScanExclusions();
    }

    if (entity is TransitFacade) {
      return ScanExclusions(transitIds: {entity.id!});
    } else if (entity is LodgingFacade) {
      return ScanExclusions(stayIds: {entity.id!});
    } else if (entity is SightFacade) {
      return ScanExclusions(sightIds: {entity.id!});
    }
    return const ScanExclusions();
  }

  /// Creates exclusions for multiple transits (journey legs)
  factory ScanExclusions.forTransits(Iterable<String> ids) {
    return ScanExclusions(transitIds: ids.toSet());
  }

  /// Creates exclusions for multiple sights (itinerary sights)
  factory ScanExclusions.forSights(Iterable<String> ids) {
    return ScanExclusions(sightIds: ids.toSet());
  }

  /// Merges two exclusion sets
  ScanExclusions merge(ScanExclusions other) {
    return ScanExclusions(
      transitIds: {...transitIds, ...other.transitIds},
      stayIds: {...stayIds, ...other.stayIds},
      sightIds: {...sightIds, ...other.sightIds},
    );
  }
}

// =============================================================================
// TRIP DATA SNAPSHOT
// =============================================================================

/// A lightweight snapshot of trip models used as input for conflict scanning.
class TripConflictDataSnapshot {
  final Iterable<TransitFacade> transits;
  final Iterable<LodgingFacade> stays;
  final Iterable<ItineraryPlanData> itineraries;
  final Iterable<ExpenseBearingTripEntity> expenses;

  const TripConflictDataSnapshot({
    required this.transits,
    required this.stays,
    required this.itineraries,
    required this.expenses,
  });

  factory TripConflictDataSnapshot.fromTripData(TripDataFacade tripData) {
    return TripConflictDataSnapshot(
      transits: tripData.transitCollection.items,
      stays: tripData.lodgingCollection.items,
      itineraries: tripData.itineraryCollection.map((e) => e.planData),
      expenses: tripData.expenseCollection.items,
    );
  }
}

// =============================================================================
// CONFLICT RESOLUTION RESULT
// =============================================================================

/// Result of validating/resolving a conflicted entity time change.
///
/// The UI is responsible for constructing an appropriate message from
/// [conflictingEntity] (e.g. via its [toString] or a localised description).
class ConflictResolutionResult {
  /// Whether the time change is valid.
  final bool isValid;

  /// The trip entity that the modified change conflicts with, when [isValid]
  /// is false.
  final TripEntity? conflictingEntity;

  /// The original change that was modified.
  final EntityChangeBase? modifiedChange;

  /// Changes that were affected (clamped or marked for deletion) due to
  /// inter-conflicts.
  final List<EntityChangeBase> affectedChanges;

  /// New conflicts discovered from the trip repository.
  final List<EntityChangeBase> newConflicts;

  const ConflictResolutionResult._({
    required this.isValid,
    this.conflictingEntity,
    this.modifiedChange,
    this.affectedChanges = const [],
    this.newConflicts = const [],
  });

  factory ConflictResolutionResult.invalid(TripEntity conflictingEntity) {
    return ConflictResolutionResult._(
        isValid: false, conflictingEntity: conflictingEntity);
  }

  factory ConflictResolutionResult.valid({
    required EntityChangeBase modifiedChange,
    List<EntityChangeBase> affectedChanges = const [],
    List<EntityChangeBase> newConflicts = const [],
  }) {
    return ConflictResolutionResult._(
      isValid: true,
      modifiedChange: modifiedChange,
      affectedChanges: affectedChanges,
      newConflicts: newConflicts,
    );
  }

  /// All changes that need UI updates (modified + affected + new).
  Iterable<EntityChangeBase> get allUpdatedChanges sync* {
    if (modifiedChange != null) {
      yield modifiedChange!;
    }
    yield* affectedChanges;
    yield* newConflicts;
  }
}

// =============================================================================
// CONFLICT POSITION RULES
// =============================================================================

/// Determines which timeline positions constitute conflicts.
/// Different entity combinations have different conflict semantics.
///
/// Core domain rules:
/// - Transits/sights CAN happen during a stay (between checkin and checkout)
///   without conflict. Only overlapping at exact checkin/checkout times or
///   crossing those boundaries is a conflict.
/// - Two stays, two transits, or a transit and a sight that overlap are
///   conflicts.
/// - Adjacent events (one ends when another starts) are never conflicts.
class ConflictRules {
  const ConflictRules._();

  /// Check if position is a conflict for standard entity editing
  /// (Transit or Sight being edited against another Transit or Sight).
  static bool isStandardConflict(EntityTimelinePosition position) {
    return position == EntityTimelinePosition.exactBoundaryMatch ||
        position == EntityTimelinePosition.containedIn ||
        position == EntityTimelinePosition.contains ||
        position == EntityTimelinePosition.startsDuringEndsAfter ||
        position == EntityTimelinePosition.startsBeforeEndsDuring;
  }

  /// Unified conflict check based on source/target entity types.
  static bool isConflicting(
    EntityTimelinePosition position,
    TripEntity sourceEntity,
    TripEntity targetEntity,
  ) {
    if (sourceEntity is TripMetadataFacade) {
      return _isMetadataConflict(position);
    }

    // Stay vs Transit/Sight (or Transit/Sight vs Stay): only boundary
    // overlaps and partial boundary crossings are conflicts.
    // Transits and sights that are fully *contained within* a stay are allowed.
    final involvesMixedStayAndMovement = (sourceEntity is LodgingFacade &&
            (targetEntity is TransitFacade || targetEntity is SightFacade)) ||
        ((sourceEntity is TransitFacade || sourceEntity is SightFacade) &&
            targetEntity is LodgingFacade);

    if (involvesMixedStayAndMovement) {
      return _isStayBoundaryConflict(position);
    }

    return isStandardConflict(position);
  }

  static bool _isMetadataConflict(EntityTimelinePosition position) {
    return position == EntityTimelinePosition.beforeEvent ||
        position == EntityTimelinePosition.afterEvent ||
        position == EntityTimelinePosition.startsBeforeEndsDuring ||
        position == EntityTimelinePosition.startsDuringEndsAfter ||
        position == EntityTimelinePosition.contains;
  }

  /// A stay-vs-transit/sight (or vice-versa) conflict: only boundary matches
  /// and partial crossings count. Containment is not a conflict (travellers
  /// can visit sights and take transits while checked in to a stay).
  static bool _isStayBoundaryConflict(EntityTimelinePosition position) {
    return position == EntityTimelinePosition.exactBoundaryMatch ||
        position == EntityTimelinePosition.startsDuringEndsAfter ||
        position == EntityTimelinePosition.startsBeforeEndsDuring;
  }
}

// =============================================================================
// UNIFIED CONFLICT SCANNER
// =============================================================================

/// Service for detecting timeline conflicts in trip data.
///
/// Responsibilities:
/// - Scan trip data for entities that conflict with a given time range
/// - Apply clamping strategies to resolve conflicts where possible
/// - Support inter-conflict detection (conflicts between conflicted items)
/// - Detect new conflicts from trip repository when editing conflicted items
class UnifiedConflictScanner {
  final TripConflictDataSnapshot _tripData;

  static const _sightDuration = Duration(minutes: 1);

  UnifiedConflictScanner({required TripConflictDataSnapshot tripData})
      : _tripData = tripData;

  // ===========================================================================
  // PRIMARY SCAN METHODS
  // ===========================================================================

  AggregatedConflicts scanForConflicts({
    required TimeRange referenceRange,
    required TripEntity sourceEntity,
    ScanExclusions exclusions = const ScanExclusions(),
  }) {
    return AggregatedConflicts(
      transitConflicts: _scanTransits(referenceRange, sourceEntity, exclusions),
      stayConflicts: _scanStays(referenceRange, sourceEntity, exclusions),
      sightConflicts: _scanSights(referenceRange, sourceEntity, exclusions),
    );
  }

  MetadataUpdateConflicts? scanForMetadataUpdate({
    required TripMetadataFacade oldMetadata,
    required TripMetadataFacade newMetadata,
  }) {
    final datesChanged =
        !oldMetadata.startDate!.isOnSameDayAs(newMetadata.startDate!) ||
            !oldMetadata.endDate!.isOnSameDayAs(newMetadata.endDate!);
    final contributorsChanged =
        _haveContributorsChanged(oldMetadata, newMetadata);

    if (!datesChanged && !contributorsChanged) {
      return null;
    }

    final newTripRange = TimeRange(
      start: newMetadata.startDate!,
      end: DateTime(
        newMetadata.endDate!.year,
        newMetadata.endDate!.month,
        newMetadata.endDate!.day,
        23,
        59,
      ),
    );

    final stayConflicts = datesChanged
        ? _findStaysOutsideDateRange(newTripRange)
        : <StayConflict>[];
    final transitConflicts = datesChanged
        ? _findTransitsOutsideDateRange(newTripRange)
        : <TransitConflict>[];
    final sightConflicts = datesChanged
        ? _findSightsOutsideDateRange(newTripRange)
        : <SightConflict>[];
    final expenseEntities = contributorsChanged
        ? _collectExpenseBearingEntities()
        : <ExpenseBearingTripEntity>[];

    if (stayConflicts.isEmpty &&
        transitConflicts.isEmpty &&
        sightConflicts.isEmpty &&
        expenseEntities.isEmpty) {
      return null;
    }

    return MetadataUpdateConflicts(
      stayConflicts: stayConflicts,
      transitConflicts: transitConflicts,
      sightConflicts: sightConflicts,
      expenseEntities: expenseEntities,
      oldMetadata: oldMetadata,
      newMetadata: newMetadata,
    );
  }

  // ===========================================================================
  // COMPREHENSIVE CONFLICT RESOLUTION
  // ===========================================================================

  /// Validates and resolves all conflicts when a conflicted entity's time is
  /// changed.
  ///
  /// For journey (multi-leg transit) editing, pass all current legs via
  /// [editingJourneyLegs]. When non-empty, each leg is checked individually
  /// against the modified entity; [editableEntityRange] is ignored in that case.
  ConflictResolutionResult resolveConflictedEntityTimeChange({
    required EntityChangeBase modifiedChange,
    required TimeRange? editableEntityRange,
    required TripEntity editableEntity,
    required List<StayChange> existingStayChanges,
    required List<TransitChange> existingTransitChanges,
    required List<SightChange> existingSightChanges,
    List<TransitFacade> editingJourneyLegs = const [],
  }) {
    final modifiedRange = _getTimeRangeFromChange(modifiedChange);
    if (modifiedRange == null) {
      return ConflictResolutionResult.valid(modifiedChange: modifiedChange);
    }

    // Step 1: Check conflict with editable entity / journey legs.
    if (editingJourneyLegs.isNotEmpty) {
      for (final leg in editingJourneyLegs) {
        if (leg.departureDateTime == null || leg.arrivalDateTime == null) {
          continue;
        }
        final legRange = TimeRange(
          start: leg.departureDateTime!,
          end: leg.arrivalDateTime!,
        );
        if (ConflictRules.isConflicting(modifiedRange.analyzePosition(legRange),
            leg, modifiedChange.modified)) {
          return ConflictResolutionResult.invalid(leg);
        }
      }
    } else if (editableEntityRange != null) {
      final position = modifiedRange.analyzePosition(editableEntityRange);
      final isConflicting = editableEntity is TripMetadataFacade
          ? ConflictRules._isMetadataConflict(position)
          : ConflictRules.isStandardConflict(position);

      if (isConflicting) {
        return ConflictResolutionResult.invalid(editableEntity);
      }
    }

    final affectedChanges = <EntityChangeBase>[];
    final newConflicts = <EntityChangeBase>[];

    // Step 2: Check and resolve inter-conflicts with existing plan items.
    _processInterConflictsInList(
        modifiedChange: modifiedChange,
        modifiedRange: modifiedRange,
        editableEntity: editableEntity,
        changes: existingStayChanges,
        affectedChanges: affectedChanges);
    _processInterConflictsInList(
        modifiedChange: modifiedChange,
        modifiedRange: modifiedRange,
        editableEntity: editableEntity,
        changes: existingTransitChanges,
        affectedChanges: affectedChanges);
    _processInterConflictsInList(
        modifiedChange: modifiedChange,
        modifiedRange: modifiedRange,
        editableEntity: editableEntity,
        changes: existingSightChanges,
        affectedChanges: affectedChanges);

    // Step 3: Check for new conflicts in trip repository.
    _findAndResolveRepoConflicts(
      modifiedChange: modifiedChange,
      modifiedRange: modifiedRange,
      editableEntity: editableEntity,
      existingStayChanges: existingStayChanges,
      existingTransitChanges: existingTransitChanges,
      existingSightChanges: existingSightChanges,
      newConflicts: newConflicts,
    );

    modifiedChange.markAsResolved();

    return ConflictResolutionResult.valid(
      modifiedChange: modifiedChange,
      affectedChanges: affectedChanges,
      newConflicts: newConflicts,
    );
  }

  void _processInterConflictsInList<T extends EntityChangeBase>({
    required EntityChangeBase modifiedChange,
    required TimeRange modifiedRange,
    required TripEntity editableEntity,
    required List<T> changes,
    required List<EntityChangeBase> affectedChanges,
  }) {
    for (final change in changes) {
      if (_isSameChange(change, modifiedChange)) {
        continue;
      }
      if (change.isMarkedForDeletion) {
        continue;
      }

      final otherRange = _getTimeRangeFromChange(change);
      if (otherRange == null) {
        continue;
      }

      final position = otherRange.analyzePosition(modifiedRange);
      if (!ConflictRules.isConflicting(
          position, editableEntity, change.modified)) {
        continue;
      }

      final clamped = _tryClampChange(change, modifiedRange, position);
      if (clamped) {
        affectedChanges.add(change);
      } else {
        change.markForDeletion();
        affectedChanges.add(change);
      }
    }
  }

  void _findAndResolveRepoConflicts({
    required EntityChangeBase modifiedChange,
    required TimeRange modifiedRange,
    required TripEntity editableEntity,
    required List<StayChange> existingStayChanges,
    required List<TransitChange> existingTransitChanges,
    required List<SightChange> existingSightChanges,
    required List<EntityChangeBase> newConflicts,
  }) {
    final existingIds = _collectExistingIds(
      modifiedChange,
      existingStayChanges,
      existingTransitChanges,
      existingSightChanges,
    );
    final exclusions =
        existingIds.merge(ScanExclusions.forEntity(editableEntity));

    final repoConflicts = scanForConflicts(
      referenceRange: modifiedRange,
      sourceEntity: modifiedChange.modified,
      exclusions: exclusions,
    );

    for (final c in repoConflicts.transitConflicts) {
      newConflicts.add(_toEntityChange(c));
    }
    for (final c in repoConflicts.stayConflicts) {
      newConflicts.add(_toEntityChange(c));
    }
    for (final c in repoConflicts.sightConflicts) {
      newConflicts.add(_toEntityChange(c));
    }
  }

  ScanExclusions _collectExistingIds(
    EntityChangeBase modifiedChange,
    List<StayChange> stayChanges,
    List<TransitChange> transitChanges,
    List<SightChange> sightChanges,
  ) {
    final transitIds = <String>{};
    final stayIds = <String>{};
    final sightIds = <String>{};

    // Exclude the entity being resolved (the modified change itself).
    final modifiedExclusion = ScanExclusions.forEntity(modifiedChange.original);
    transitIds.addAll(modifiedExclusion.transitIds);
    stayIds.addAll(modifiedExclusion.stayIds);
    sightIds.addAll(modifiedExclusion.sightIds);

    // Exclude entities already tracked in existing conflict lists.
    for (final c in transitChanges) {
      if (c.original.id != null) {
        transitIds.add(c.original.id!);
      }
    }
    for (final c in stayChanges) {
      if (c.original.id != null) {
        stayIds.add(c.original.id!);
      }
    }
    for (final c in sightChanges) {
      if (c.original.id != null) {
        sightIds.add(c.original.id!);
      }
    }

    return ScanExclusions(
        transitIds: transitIds, stayIds: stayIds, sightIds: sightIds);
  }

  bool _tryClampChange(EntityChangeBase change, TimeRange conflictRange,
      EntityTimelinePosition position) {
    final entity = change.modified;
    if (entity is TransitFacade) {
      final clamped =
          EntityClamper.clampTransit(entity, conflictRange, position);
      if (clamped != null) {
        change.modified = clamped;
        change.isClamped = true;
        return true;
      }
    } else if (entity is LodgingFacade) {
      final clamped = EntityClamper.clampStay(entity, conflictRange, position);
      if (clamped != null) {
        change.modified = clamped;
        change.isClamped = true;
        return true;
      }
    } else if (entity is SightFacade) {
      final clamped = EntityClamper.clampSight(entity, conflictRange, position);
      if (clamped != null) {
        change.modified = clamped;
        change.isClamped = true;
        return true;
      }
    }
    return false;
  }

  // ===========================================================================
  // CHANGE CONVERSION HELPERS
  // ===========================================================================

  DateTimeChange<T> _toEntityChange<T extends TripEntity>(
      ConflictResult<T> conflict) {
    return conflict.canBeClampedToResolve
        ? DateTimeChange<T>.forClamping(
            original: conflict.entity,
            modified: conflict.clampedEntity!,
            timelinePosition: conflict.position,
          )
        : DateTimeChange<T>.forDeletion(
            original: conflict.entity,
            timelinePosition: conflict.position,
          );
  }

  // ===========================================================================
  // PRIVATE SCAN METHODS
  // ===========================================================================

  List<TransitConflict> _scanTransits(
    TimeRange referenceRange,
    TripEntity sourceEntity,
    ScanExclusions exclusions,
  ) {
    final conflicts = <TransitConflict>[];
    for (final transit in _tripData.transits) {
      if (exclusions.transitIds.contains(transit.id)) {
        continue;
      }
      if (transit.departureDateTime == null ||
          transit.arrivalDateTime == null) {
        continue;
      }
      final entityRange = TimeRange(
        start: transit.departureDateTime!,
        end: transit.arrivalDateTime!,
      );
      final position = entityRange.analyzePosition(referenceRange);
      if (!ConflictRules.isConflicting(position, sourceEntity, transit)) {
        continue;
      }
      conflicts.add(TransitConflict(
        entity: transit,
        entityTimeRange: entityRange,
        position: position,
        clampedEntity:
            EntityClamper.clampTransit(transit, referenceRange, position),
      ));
    }
    return conflicts;
  }

  List<StayConflict> _scanStays(
    TimeRange referenceRange,
    TripEntity sourceEntity,
    ScanExclusions exclusions,
  ) {
    final conflicts = <StayConflict>[];
    for (final stay in _tripData.stays) {
      if (exclusions.stayIds.contains(stay.id)) {
        continue;
      }
      if (stay.checkinDateTime == null || stay.checkoutDateTime == null) {
        continue;
      }
      final entityRange = TimeRange(
        start: stay.checkinDateTime!,
        end: stay.checkoutDateTime!,
      );
      final position = entityRange.analyzePosition(referenceRange);
      if (!ConflictRules.isConflicting(position, sourceEntity, stay)) {
        continue;
      }
      conflicts.add(StayConflict(
        entity: stay,
        entityTimeRange: entityRange,
        position: position,
        clampedEntity: EntityClamper.clampStay(stay, referenceRange, position),
      ));
    }
    return conflicts;
  }

  List<SightConflict> _scanSights(
    TimeRange referenceRange,
    TripEntity sourceEntity,
    ScanExclusions exclusions,
  ) {
    final conflicts = <SightConflict>[];
    for (final itineraryPlanData in _tripData.itineraries) {
      for (final sight in itineraryPlanData.sights) {
        if (exclusions.sightIds.contains(sight.id)) {
          continue;
        }
        if (sight.visitTime == null) {
          continue;
        }
        final entityRange = TimeRange(
          start: sight.visitTime!,
          end: sight.visitTime!.add(_sightDuration),
        );
        final position = entityRange.analyzePosition(referenceRange);
        if (!ConflictRules.isConflicting(position, sourceEntity, sight)) {
          continue;
        }
        conflicts.add(SightConflict(
          entity: sight,
          entityTimeRange: entityRange,
          position: position,
          clampedEntity:
              EntityClamper.clampSight(sight, referenceRange, position),
        ));
      }
    }
    return conflicts;
  }

  // ===========================================================================
  // METADATA UPDATE HELPERS
  // ===========================================================================

  List<StayConflict> _findStaysOutsideDateRange(TimeRange newTripRange) {
    final conflicts = <StayConflict>[];
    for (final stay in _tripData.stays) {
      final stayRange = TimeRange(
        start: stay.checkinDateTime!,
        end: stay.checkoutDateTime!,
      );
      final position = stayRange.analyzePosition(newTripRange);
      if (!ConflictRules._isMetadataConflict(position)) {
        continue;
      }
      conflicts.add(StayConflict(
        entity: stay,
        entityTimeRange: stayRange,
        position: position,
        clampedEntity: EntityClamper.clampStayToDateRange(stay, newTripRange),
      ));
    }
    return conflicts;
  }

  List<TransitConflict> _findTransitsOutsideDateRange(TimeRange newTripRange) {
    final conflicts = <TransitConflict>[];
    for (final transit in _tripData.transits) {
      final transitRange = TimeRange(
          start: transit.departureDateTime!, end: transit.arrivalDateTime!);
      final position = transitRange.analyzePosition(newTripRange);
      if (!ConflictRules._isMetadataConflict(position)) {
        continue;
      }
      final modified = transit.clone()
        ..departureDateTime = null
        ..arrivalDateTime = null;
      conflicts.add(TransitConflict(
        entity: transit,
        entityTimeRange: transitRange,
        position: position,
        clampedEntity: modified,
      ));
    }
    return conflicts;
  }

  List<SightConflict> _findSightsOutsideDateRange(TimeRange newTripRange) {
    final conflicts = <SightConflict>[];
    for (final itineraryPlanData in _tripData.itineraries) {
      for (final sight in itineraryPlanData.sights) {
        if (sight.visitTime == null) {
          continue;
        }
        final sightRange = TimeRange(
          start: sight.visitTime!,
          end: sight.visitTime!.add(_sightDuration),
        );
        final position = sightRange.analyzePosition(newTripRange);
        if (!ConflictRules._isMetadataConflict(position)) {
          continue;
        }
        final modified = sight.clone()..visitTime = null;
        conflicts.add(SightConflict(
          entity: sight,
          entityTimeRange: sightRange,
          position: position,
          clampedEntity: modified,
        ));
      }
    }
    return conflicts;
  }

  bool _haveContributorsChanged(
      TripMetadataFacade oldMeta, TripMetadataFacade newMeta) {
    final oldSet = oldMeta.contributors.toSet();
    final newSet = newMeta.contributors.toSet();
    return oldSet.difference(newSet).isNotEmpty ||
        newSet.difference(oldSet).isNotEmpty;
  }

  List<ExpenseBearingTripEntity> _collectExpenseBearingEntities() {
    final entities = <ExpenseBearingTripEntity>[];
    entities.addAll(_tripData.expenses);
    entities.addAll(_tripData.transits);
    entities.addAll(_tripData.stays);
    for (final itineraryPlanData in _tripData.itineraries) {
      entities.addAll(itineraryPlanData.sights);
    }
    return entities;
  }

  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================

  TimeRange? _getTimeRangeFromChange(EntityChangeBase change) {
    final entity = change.modified;
    if (entity is TransitFacade) {
      if (entity.departureDateTime != null && entity.arrivalDateTime != null) {
        return TimeRange(
            start: entity.departureDateTime!, end: entity.arrivalDateTime!);
      }
    } else if (entity is LodgingFacade) {
      if (entity.checkinDateTime != null && entity.checkoutDateTime != null) {
        return TimeRange(
            start: entity.checkinDateTime!, end: entity.checkoutDateTime!);
      }
    } else if (entity is SightFacade) {
      if (entity.visitTime != null) {
        return TimeRange(
          start: entity.visitTime!,
          end: entity.visitTime!.add(_sightDuration),
        );
      }
    }
    return null;
  }

  bool _isSameChange(EntityChangeBase a, EntityChangeBase b) =>
      a.original.id == b.original.id;
}
