import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/entity_timeline_position.dart';
import 'package:wandrr/data/trip/models/services/time_range.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

import 'clamping_strategies.dart';
import 'conflict_result.dart';

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

  /// Creates exclusions for a stay (new or existing)
  factory ScanExclusions.forStay(String? id) {
    return ScanExclusions(stayIds: id != null ? {id} : {});
  }

  /// Merges two exclusion sets
  ScanExclusions merge(ScanExclusions other) {
    return ScanExclusions(
      transitIds: {...transitIds, ...other.transitIds},
      stayIds: {...stayIds, ...other.stayIds},
      sightIds: {...sightIds, ...other.sightIds},
    );
  }

  bool excludesTransit(String? id) => id != null && transitIds.contains(id);

  bool excludesStay(String? id) => id != null && stayIds.contains(id);

  bool excludesSight(String? id) => id != null && sightIds.contains(id);
}

// =============================================================================
// CONFLICT POSITION RULES
// =============================================================================

/// Determines which timeline positions constitute conflicts.
/// Different entity combinations have different conflict semantics.
class ConflictRules {
  const ConflictRules._();

  /// Check if position is a conflict for standard entity editing
  /// (Transit or Sight being edited)
  static bool isStandardConflict(EntityTimelinePosition position) {
    return position == EntityTimelinePosition.exactBoundaryMatch ||
        position == EntityTimelinePosition.containedIn ||
        position == EntityTimelinePosition.contains ||
        position == EntityTimelinePosition.startsDuringEndsAfter ||
        position == EntityTimelinePosition.startsBeforeEndsDuring;
  }

  /// Check if position is a conflict when source is Stay
  /// Target can be contained in a stay without conflict for transits/sights
  static bool isStaySourceConflict(
    EntityTimelinePosition position,
    TripEntity targetEntity,
  ) {
    // Stays allow transits to be fully contained
    if (targetEntity is TransitFacade || targetEntity is SightFacade) {
      return position == EntityTimelinePosition.exactBoundaryMatch ||
          position == EntityTimelinePosition.containedIn ||
          position == EntityTimelinePosition.startsDuringEndsAfter ||
          position == EntityTimelinePosition.startsBeforeEndsDuring;
    }
    return isStandardConflict(position);
  }

  /// Check if position is a conflict for metadata updates
  /// Entities must be fully within the new date range
  static bool isMetadataConflict(EntityTimelinePosition position) {
    return position == EntityTimelinePosition.beforeEvent ||
        position == EntityTimelinePosition.afterEvent ||
        position == EntityTimelinePosition.startsBeforeEndsDuring ||
        position == EntityTimelinePosition.startsDuringEndsAfter ||
        position == EntityTimelinePosition.contains;
  }

  /// Unified conflict check based on source entity type
  static bool isConflicting(
    EntityTimelinePosition position,
    TripEntity sourceEntity,
    TripEntity targetEntity,
  ) {
    if (sourceEntity is TripMetadataFacade) {
      return isMetadataConflict(position);
    } else if (sourceEntity is LodgingFacade) {
      return isStaySourceConflict(position, targetEntity);
    } else {
      return isStandardConflict(position);
    }
  }
}

// =============================================================================
// CONFLICT RESOLUTION RESULT
// =============================================================================

/// Result of validating/resolving a conflicted entity time change.
///
/// Contains all affected changes that need UI updates.
class ConflictResolutionResult {
  /// Whether the time change is valid (no unresolvable conflict with editable entity)
  final bool isValid;

  /// Error message if invalid
  final String? errorMessage;

  /// The original change that was modified
  final EntityChangeBase? modifiedChange;

  /// Changes that were affected (clamped or marked for deletion) due to inter-conflicts
  final List<EntityChangeBase> affectedChanges;

  /// New conflicts discovered from the trip repository
  final List<EntityChangeBase> newConflicts;

  const ConflictResolutionResult._({
    required this.isValid,
    this.errorMessage,
    this.modifiedChange,
    this.affectedChanges = const [],
    this.newConflicts = const [],
  });

  factory ConflictResolutionResult.invalid(String message) {
    return ConflictResolutionResult._(isValid: false, errorMessage: message);
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

  /// All changes that need UI updates (modified + affected + new)
  Iterable<EntityChangeBase> get allUpdatedChanges sync* {
    if (modifiedChange != null) yield modifiedChange!;
    yield* affectedChanges;
    yield* newConflicts;
  }
}

// =============================================================================
// UNIFIED CONFLICT SCANNER
// =============================================================================

/// Pure service for detecting timeline conflicts in trip data.
///
/// Responsibilities:
/// - Scan trip data for entities that conflict with a given time range
/// - Apply clamping strategies to resolve conflicts where possible
/// - Support inter-conflict detection (conflicts between conflicted items)
/// - Detect new conflicts from trip repository when editing conflicted items
class UnifiedConflictScanner {
  final TripDataFacade _tripData;

  /// Assumed duration for sight visits when checking conflicts
  static const _sightDuration = Duration(minutes: 1);

  UnifiedConflictScanner({required TripDataFacade tripData})
      : _tripData = tripData;

  // ===========================================================================
  // PRIMARY SCAN METHODS
  // ===========================================================================

  /// Scans trip data for conflicts with the given time range.
  ///
  /// [referenceRange] - The time range to check against
  /// [sourceEntity] - The entity being edited (determines conflict rules)
  /// [exclusions] - Entities to exclude from scanning
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

  /// Scans for entities affected by trip metadata date changes.
  MetadataUpdateConflicts? scanForMetadataUpdate({
    required TripMetadataFacade oldMetadata,
    required TripMetadataFacade newMetadata,
  }) {
    final datesChanged =
        !oldMetadata.startDate!.isOnSameDayAs(newMetadata.startDate!) ||
            !oldMetadata.endDate!.isOnSameDayAs(newMetadata.endDate!);
    final contributorsChanged =
        _haveContributorsChanged(oldMetadata, newMetadata);

    if (!datesChanged && !contributorsChanged) return null;

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

  /// Validates and resolves all conflicts when a conflicted entity's time is changed.
  ///
  /// This method handles three types of conflicts:
  /// 1. Conflict with the editable entity (the primary entity being edited)
  /// 2. Inter-conflicts with other items already in the conflict plan
  /// 3. New conflicts with entities in the trip repository
  ///
  /// For each conflict found, it attempts to clamp the conflicting entity.
  /// If clamping fails, the entity is marked for deletion.
  ///
  /// Returns a [ConflictResolutionResult] containing all affected changes.
  ConflictResolutionResult resolveConflictedEntityTimeChange({
    required EntityChangeBase modifiedChange,
    required TimeRange? editableEntityRange,
    required TripEntity editableEntity,
    required List<StayChange> existingStayChanges,
    required List<TransitChange> existingTransitChanges,
    required List<SightChange> existingSightChanges,
  }) {
    final modifiedRange = _getTimeRangeFromChange(modifiedChange);
    if (modifiedRange == null) {
      return ConflictResolutionResult.valid(modifiedChange: modifiedChange);
    }

    // Step 1: Check conflict with editable entity
    if (editableEntityRange != null) {
      final position = modifiedRange.analyzePosition(editableEntityRange);
      final isConflicting = editableEntity is TripMetadataFacade
          ? ConflictRules.isMetadataConflict(position)
          : ConflictRules.isStandardConflict(position);

      if (isConflicting) {
        return ConflictResolutionResult.invalid(
          "Cannot conflict with the entity being edited",
        );
      }
    }

    final affectedChanges = <EntityChangeBase>[];
    final newConflicts = <EntityChangeBase>[];

    // Step 2: Check and resolve inter-conflicts with existing plan items
    _resolveInterConflicts(
      modifiedChange: modifiedChange,
      modifiedRange: modifiedRange,
      editableEntity: editableEntity,
      stayChanges: existingStayChanges,
      transitChanges: existingTransitChanges,
      sightChanges: existingSightChanges,
      affectedChanges: affectedChanges,
    );

    // Step 3: Check for new conflicts in trip repository
    _findAndResolveRepoConflicts(
      modifiedChange: modifiedChange,
      modifiedRange: modifiedRange,
      editableEntity: editableEntity,
      existingStayChanges: existingStayChanges,
      existingTransitChanges: existingTransitChanges,
      existingSightChanges: existingSightChanges,
      newConflicts: newConflicts,
    );

    // Mark the modified change as resolved
    modifiedChange.markAsResolved();

    return ConflictResolutionResult.valid(
      modifiedChange: modifiedChange,
      affectedChanges: affectedChanges,
      newConflicts: newConflicts,
    );
  }

  /// Resolves inter-conflicts between the modified change and other plan items.
  void _resolveInterConflicts({
    required EntityChangeBase modifiedChange,
    required TimeRange modifiedRange,
    required TripEntity editableEntity,
    required List<StayChange> stayChanges,
    required List<TransitChange> transitChanges,
    required List<SightChange> sightChanges,
    required List<EntityChangeBase> affectedChanges,
  }) {
    // Process all change lists
    _processInterConflictsInList(
      modifiedChange: modifiedChange,
      modifiedRange: modifiedRange,
      editableEntity: editableEntity,
      changes: stayChanges,
      affectedChanges: affectedChanges,
    );

    _processInterConflictsInList(
      modifiedChange: modifiedChange,
      modifiedRange: modifiedRange,
      editableEntity: editableEntity,
      changes: transitChanges,
      affectedChanges: affectedChanges,
    );

    _processInterConflictsInList(
      modifiedChange: modifiedChange,
      modifiedRange: modifiedRange,
      editableEntity: editableEntity,
      changes: sightChanges,
      affectedChanges: affectedChanges,
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
      if (_isSameChange(change, modifiedChange)) continue;
      if (change.isMarkedForDeletion) continue;

      final otherRange = _getTimeRangeFromChange(change);
      if (otherRange == null) continue;

      final position = otherRange.analyzePosition(modifiedRange);
      if (!ConflictRules.isConflicting(
          position, editableEntity, change.modified)) {
        continue;
      }

      // Try to clamp
      final clamped = _tryClampChange(change, modifiedRange, position);
      if (clamped) {
        affectedChanges.add(change);
      } else {
        // Cannot clamp - mark for deletion
        change.markForDeletion();
        affectedChanges.add(change);
      }
    }
  }

  /// Finds new conflicts in the trip repository and adds them to the plan.
  void _findAndResolveRepoConflicts({
    required EntityChangeBase modifiedChange,
    required TimeRange modifiedRange,
    required TripEntity editableEntity,
    required List<StayChange> existingStayChanges,
    required List<TransitChange> existingTransitChanges,
    required List<SightChange> existingSightChanges,
    required List<EntityChangeBase> newConflicts,
  }) {
    // Build exclusions: exclude the modified entity + all entities already in plan + editable entity
    final existingIds = _collectExistingIds(
      modifiedChange,
      existingStayChanges,
      existingTransitChanges,
      existingSightChanges,
    );

    // Also exclude the editable entity itself
    final editableExclusion = ScanExclusions.forEntity(editableEntity);
    final exclusions = existingIds.merge(editableExclusion);

    // Scan for new conflicts
    final repoConflicts = scanForConflicts(
      referenceRange: modifiedRange,
      sourceEntity: modifiedChange.modified,
      exclusions: exclusions,
    );

    // Convert new conflicts to changes and try to clamp them
    for (final conflict in repoConflicts.transitConflicts) {
      final change = _toTransitChange(conflict);
      newConflicts.add(change);
    }

    for (final conflict in repoConflicts.stayConflicts) {
      final change = _toStayChange(conflict);
      newConflicts.add(change);
    }

    for (final conflict in repoConflicts.sightConflicts) {
      final change = _toSightChange(conflict);
      newConflicts.add(change);
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

    // Add modified change's original ID
    final modifiedId = modifiedChange.original.id;
    if (modifiedId != null) {
      if (modifiedChange.modified is TransitFacade) {
        transitIds.add(modifiedId);
      } else if (modifiedChange.modified is LodgingFacade) {
        stayIds.add(modifiedId);
      } else if (modifiedChange.modified is SightFacade) {
        sightIds.add(modifiedId);
      }
    }

    // Add all existing change IDs
    for (final c in transitChanges) {
      if (c.original.id != null) transitIds.add(c.original.id!);
    }
    for (final c in stayChanges) {
      if (c.original.id != null) stayIds.add(c.original.id!);
    }
    for (final c in sightChanges) {
      if (c.original.id != null) sightIds.add(c.original.id!);
    }

    return ScanExclusions(
      transitIds: transitIds,
      stayIds: stayIds,
      sightIds: sightIds,
    );
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
  // LEGACY INTER-CONFLICT METHODS (kept for backward compatibility)
  // ===========================================================================

  /// Checks if a modified conflicted entity now conflicts with another conflicted entity.
  /// @deprecated Use [resolveConflictedEntityTimeChange] for comprehensive resolution.
  EntityChangeBase? findInterConflict({
    required EntityChangeBase modifiedChange,
    required List<StayChange> stayChanges,
    required List<TransitChange> transitChanges,
    required List<SightChange> sightChanges,
    required TripEntity sourceEntity,
  }) {
    final modifiedRange = _getTimeRangeFromChange(modifiedChange);
    if (modifiedRange == null) return null;

    // Check against other stay changes
    for (final change in stayChanges) {
      if (_isSameChange(change, modifiedChange)) continue;
      if (change.isMarkedForDeletion) continue;

      final otherRange = _getTimeRangeFromChange(change);
      if (otherRange == null) continue;

      final position = modifiedRange.analyzePosition(otherRange);
      if (ConflictRules.isConflicting(
          position, sourceEntity, change.modified)) {
        return change;
      }
    }

    // Check against other transit changes
    for (final change in transitChanges) {
      if (_isSameChange(change, modifiedChange)) continue;
      if (change.isMarkedForDeletion) continue;

      final otherRange = _getTimeRangeFromChange(change);
      if (otherRange == null) continue;

      final position = modifiedRange.analyzePosition(otherRange);
      if (ConflictRules.isConflicting(
          position, sourceEntity, change.modified)) {
        return change;
      }
    }

    // Check against other sight changes
    for (final change in sightChanges) {
      if (_isSameChange(change, modifiedChange)) continue;
      if (change.isMarkedForDeletion) continue;

      final otherRange = _getTimeRangeFromChange(change);
      if (otherRange == null) continue;

      final position = modifiedRange.analyzePosition(otherRange);
      if (ConflictRules.isConflicting(
          position, sourceEntity, change.modified)) {
        return change;
      }
    }

    return null;
  }

  /// Attempts to clamp an inter-conflict.
  /// @deprecated Use [resolveConflictedEntityTimeChange] for comprehensive resolution.
  bool tryClampInterConflict({
    required EntityChangeBase modifiedChange,
    required EntityChangeBase conflictingChange,
  }) {
    final modifiedRange = _getTimeRangeFromChange(modifiedChange);
    if (modifiedRange == null) return false;

    final conflictingRange = _getTimeRangeFromChange(conflictingChange);
    if (conflictingRange == null) return false;

    final position = conflictingRange.analyzePosition(modifiedRange);
    return _tryClampChange(conflictingChange, modifiedRange, position);
  }

  // ===========================================================================
  // CHANGE CONVERSION HELPERS
  // ===========================================================================

  TransitChange _toTransitChange(TransitConflict conflict) {
    return conflict.canBeClampedToResolve
        ? TransitChange.forClamping(
            original: conflict.entity,
            modified: conflict.clampedEntity!,
            timelinePosition: conflict.position,
          )
        : TransitChange.forDeletion(
            original: conflict.entity,
            timelinePosition: conflict.position,
          );
  }

  StayChange _toStayChange(StayConflict conflict) {
    return conflict.canBeClampedToResolve
        ? StayChange.forClamping(
            original: conflict.entity,
            modified: conflict.clampedEntity!,
            timelinePosition: conflict.position,
          )
        : StayChange.forDeletion(
            original: conflict.entity,
            timelinePosition: conflict.position,
          );
  }

  SightChange _toSightChange(SightConflict conflict) {
    return conflict.canBeClampedToResolve
        ? SightChange.forClamping(
            original: conflict.entity,
            modified: conflict.clampedEntity!,
            timelinePosition: conflict.position,
          )
        : SightChange.forDeletion(
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

    for (final transit in _tripData.transitCollection.collectionItems) {
      if (exclusions.excludesTransit(transit.id)) continue;

      final entityRange = TimeRange(
        start: transit.departureDateTime!,
        end: transit.arrivalDateTime!,
      );

      final position = entityRange.analyzePosition(referenceRange);
      if (!ConflictRules.isConflicting(position, sourceEntity, transit))
        continue;

      final clamped =
          EntityClamper.clampTransit(transit, referenceRange, position);

      conflicts.add(TransitConflict(
        entity: transit,
        entityTimeRange: entityRange,
        position: position,
        clampedEntity: clamped,
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

    for (final stay in _tripData.lodgingCollection.collectionItems) {
      if (exclusions.excludesStay(stay.id)) continue;
      if (stay.checkinDateTime == null || stay.checkoutDateTime == null)
        continue;

      final entityRange = TimeRange(
        start: stay.checkinDateTime!,
        end: stay.checkoutDateTime!,
      );

      final position = entityRange.analyzePosition(referenceRange);
      if (!ConflictRules.isConflicting(position, sourceEntity, stay)) continue;

      final clamped = EntityClamper.clampStay(stay, referenceRange, position);

      conflicts.add(StayConflict(
        entity: stay,
        entityTimeRange: entityRange,
        position: position,
        clampedEntity: clamped,
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

    for (final itinerary in _tripData.itineraryCollection) {
      for (final sight in itinerary.planData.sights) {
        if (exclusions.excludesSight(sight.id)) continue;
        if (sight.visitTime == null) continue;

        final entityRange = TimeRange(
          start: sight.visitTime!,
          end: sight.visitTime!.add(_sightDuration),
        );

        final position = entityRange.analyzePosition(referenceRange);
        if (!ConflictRules.isConflicting(position, sourceEntity, sight))
          continue;

        final clamped =
            EntityClamper.clampSight(sight, referenceRange, position);

        conflicts.add(SightConflict(
          entity: sight,
          entityTimeRange: entityRange,
          position: position,
          clampedEntity: clamped,
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

    for (final stay in _tripData.lodgingCollection.collectionItems) {
      final stayRange = TimeRange(
        start: stay.checkinDateTime!,
        end: stay.checkoutDateTime!,
      );

      final position = stayRange.analyzePosition(newTripRange);
      if (!ConflictRules.isMetadataConflict(position)) continue;

      final clamped = EntityClamper.clampStayToDateRange(stay, newTripRange);

      conflicts.add(StayConflict(
        entity: stay,
        entityTimeRange: stayRange,
        position: position,
        clampedEntity: clamped,
      ));
    }

    return conflicts;
  }

  List<TransitConflict> _findTransitsOutsideDateRange(TimeRange newTripRange) {
    final conflicts = <TransitConflict>[];

    for (final transit in _tripData.transitCollection.collectionItems) {
      final dep = transit.departureDateTime!;
      final arr = transit.arrivalDateTime!;
      final transitRange = TimeRange(start: dep, end: arr);

      final position = transitRange.analyzePosition(newTripRange);
      if (!ConflictRules.isMetadataConflict(position)) continue;

      // Transits outside date range cannot be clamped - clear times
      final modified = transit.clone();
      modified.departureDateTime = null;
      modified.arrivalDateTime = null;

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

    for (final itinerary in _tripData.itineraryCollection) {
      for (final sight in itinerary.planData.sights) {
        if (sight.visitTime == null) continue;

        final sightRange = TimeRange(
          start: sight.visitTime!,
          end: sight.visitTime!.add(_sightDuration),
        );

        final position = sightRange.analyzePosition(newTripRange);
        if (!ConflictRules.isMetadataConflict(position)) continue;

        // Sights outside date range - clear visit time
        final modified = sight.clone();
        modified.visitTime = null;

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
    TripMetadataFacade oldMeta,
    TripMetadataFacade newMeta,
  ) {
    final oldSet = oldMeta.contributors.toSet();
    final newSet = newMeta.contributors.toSet();
    return oldSet.difference(newSet).isNotEmpty ||
        newSet.difference(oldSet).isNotEmpty;
  }

  List<ExpenseBearingTripEntity> _collectExpenseBearingEntities() {
    final entities = <ExpenseBearingTripEntity>[];
    entities.addAll(_tripData.expenseCollection.collectionItems);
    entities.addAll(_tripData.transitCollection.collectionItems);
    entities.addAll(_tripData.lodgingCollection.collectionItems);
    for (final itinerary in _tripData.itineraryCollection) {
      entities.addAll(itinerary.planData.sights);
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
          start: entity.departureDateTime!,
          end: entity.arrivalDateTime!,
        );
      }
    } else if (entity is LodgingFacade) {
      if (entity.checkinDateTime != null && entity.checkoutDateTime != null) {
        return TimeRange(
          start: entity.checkinDateTime!,
          end: entity.checkoutDateTime!,
        );
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

  bool _isSameChange(EntityChangeBase a, EntityChangeBase b) {
    return a.original.id == b.original.id;
  }
}
