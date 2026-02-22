import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

import 'conflict_result.dart';
import 'entity_change.dart';
import 'entity_timeline_position.dart';
import 'time_range.dart';
import 'trip_conflict_scanner.dart';

/// Unified plan for updating trip entities.
/// Works for both TripMetadata updates and conflict resolution.
class TripEntityUpdatePlan<T extends TripEntity> {
  /// The entity being edited (before changes)
  final T oldEntity;

  /// The entity being edited (after changes)
  final T newEntity;

  /// Date/time conflicts for stays
  final List<StayChange> stayChanges;

  /// Date/time conflicts for transits
  final List<TransitChange> transitChanges;

  /// Date/time conflicts for sights
  final List<SightChange> sightChanges;

  /// Expense split changes (for contributor updates)
  final List<ExpenseSplitChange> expenseChanges;

  /// Whether user has acknowledged/reviewed the conflicts
  bool _isConfirmed = false;

  final DateTime tripStartDate, tripEndDate;

  TripEntityUpdatePlan({
    required this.oldEntity,
    required this.newEntity,
    required this.tripStartDate,
    required this.tripEndDate,
    List<StayChange>? stayChanges,
    List<TransitChange>? transitChanges,
    List<SightChange>? sightChanges,
    List<ExpenseSplitChange>? expenseChanges,
  })  : stayChanges = stayChanges ?? [],
        transitChanges = transitChanges ?? [],
        sightChanges = sightChanges ?? [],
        expenseChanges = expenseChanges ?? [];

  /// Whether there are any conflicts at all
  bool get hasConflicts =>
      stayChanges.isNotEmpty ||
      transitChanges.isNotEmpty ||
      sightChanges.isNotEmpty ||
      expenseChanges.isNotEmpty;

  /// Total number of date/time conflicts (excluding expenses)
  int get conflictCount =>
      stayChanges.length + transitChanges.length + sightChanges.length;

// Removed properties: resolvedCount, pendingCount, allConflictsResolved

  /// Checks if the provided time range conflicts with the entity being edited.
  /// Used for validation when resolving conflicts.
  bool conflictsWithNewEntity(TimeRange editedRange) {
    if (newEntity is TripMetadataFacade) return false;

    TimeRange? referenceRange;
    if (newEntity is LodgingFacade) {
      final stay = newEntity as LodgingFacade;
      if (stay.checkinDateTime == null || stay.checkoutDateTime == null)
        return false;
      referenceRange =
          TimeRange(start: stay.checkinDateTime!, end: stay.checkoutDateTime!);
    } else if (newEntity is TransitFacade) {
      final transit = newEntity as TransitFacade;
      if (transit.departureDateTime == null || transit.arrivalDateTime == null)
        return false;
      referenceRange = TimeRange(
          start: transit.departureDateTime!, end: transit.arrivalDateTime!);
    } else if (newEntity is SightFacade) {
      final sight = newEntity as SightFacade;
      if (sight.visitTime == null) return false;
      referenceRange = TimeRange(
        start: sight.visitTime!,
        end: sight.visitTime!.add(const Duration(minutes: 1)),
      );
    }

    if (referenceRange == null) return false;

    final position = editedRange.analyzePosition(referenceRange);
    return position == EntityTimelinePosition.exactBoundaryMatch ||
        position == EntityTimelinePosition.containedIn ||
        position == EntityTimelinePosition.contains ||
        position == EntityTimelinePosition.startsDuringEndsAfter ||
        position == EntityTimelinePosition.startsBeforeEndsDuring;
  }

  /// Whether user has confirmed the plan
  bool get isConfirmed => _isConfirmed;

  /// Mark the plan as confirmed by user
  void confirm() => _isConfirmed = true;

  /// Reset confirmation
  void resetConfirmation() => _isConfirmed = false;

  /// Contributors added (only for TripMetadata)
  Iterable<String> get addedContributors {
    if (oldEntity is! TripMetadataFacade || newEntity is! TripMetadataFacade) {
      return const [];
    }
    final oldMeta = oldEntity as TripMetadataFacade;
    final newMeta = newEntity as TripMetadataFacade;
    return newMeta.contributors.where((c) => !oldMeta.contributors.contains(c));
  }

  /// Contributors removed (only for TripMetadata)
  Iterable<String> get removedContributors {
    if (oldEntity is! TripMetadataFacade || newEntity is! TripMetadataFacade) {
      return const [];
    }
    final oldMeta = oldEntity as TripMetadataFacade;
    final newMeta = newEntity as TripMetadataFacade;
    return oldMeta.contributors.where((c) => !newMeta.contributors.contains(c));
  }

  // =========================================================================
  // Expense Selection (Tri-State)
  // =========================================================================

  /// Tri-state for expense selection: null = some, true = all, false = none
  bool? get expenseSelectionState {
    if (expenseChanges.isEmpty) return false;
    final selectedCount =
        expenseChanges.where((e) => e.includeInSplitBy).length;
    if (selectedCount == 0) return false;
    if (selectedCount == expenseChanges.length) return true;
    return null;
  }

  void selectAllExpenses() {
    for (final c in expenseChanges) {
      c.includeInSplitBy = true;
    }
  }

  void deselectAllExpenses() {
    for (final c in expenseChanges) {
      c.includeInSplitBy = false;
    }
  }

  void toggleExpenseSelection() {
    if (expenseSelectionState == true) {
      deselectAllExpenses();
    } else {
      selectAllExpenses();
    }
  }

  /// Syncs expense deletion state when an ExpenseBearingTripEntity is deleted/restored
  void syncExpenseDeletionState(TripEntity entity, bool isDeleted) {
    for (final change in expenseChanges) {
      if (change.original.id == entity.id) {
        if (isDeleted) {
          change.markForDeletion();
        } else {
          change.restore();
        }
        break;
      }
    }
  }

  // =========================================================================
  // Live Conflict Detection
  // =========================================================================

  /// Refreshes conflicts when a conflicted entity's times change.
  /// Checks both TripRepo items and other items already in the plan.
  /// Returns true if new conflicts were added.
  bool tryRefreshConflictsOnResolution(
    EntityChangeBase change,
    TripConflictScanner scanner,
  ) {
    if (change.isMarkedForDeletion) return false;

    TimeRange modifiedRange;
    ConflictScanExclusions exclusions;

    // Get the time range of the modified entity
    if (change is StayChange) {
      final stay = change.modified;
      if (stay.checkinDateTime == null || stay.checkoutDateTime == null) {
        return false;
      }
      modifiedRange = TimeRange(
        start: stay.checkinDateTime!,
        end: stay.checkoutDateTime!,
      );
      exclusions = ConflictScanExclusions(
        stayIds: _getExistingStayIds()..add(stay.id!),
        transitIds: _getExistingTransitIds(),
        sightIds: _getExistingSightIds(),
      );
    } else if (change is TransitChange) {
      final transit = change.modified;
      if (transit.departureDateTime == null ||
          transit.arrivalDateTime == null) {
        return false;
      }
      modifiedRange = TimeRange(
        start: transit.departureDateTime!,
        end: transit.arrivalDateTime!,
      );
      exclusions = ConflictScanExclusions(
        transitIds: _getExistingTransitIds()..add(transit.id!),
        stayIds: _getExistingStayIds(),
        sightIds: _getExistingSightIds(),
      );
    } else if (change is SightChange) {
      final sight = change.modified;
      if (sight.visitTime == null) return false;
      modifiedRange = TimeRange(
        start: sight.visitTime!,
        end: sight.visitTime!.add(const Duration(minutes: 1)),
      );
      exclusions = ConflictScanExclusions(
        sightIds: _getExistingSightIds()..add(sight.id ?? ''),
        transitIds: _getExistingTransitIds(),
        stayIds: _getExistingStayIds(),
      );
    } else {
      return false;
    }

    // Scan for new conflicts from TripRepo
    final newConflicts = scanner.scanForConflicts(
      referenceRange: modifiedRange,
      tripEntity: change.modified,
      exclusions: exclusions,
    );

    bool hasNewConflicts = false;

    // Add new stay conflicts
    for (final conflict in newConflicts.stayConflicts) {
      if (!_hasStayChange(conflict.entity.id)) {
        stayChanges.add(_conflictToDateTimeChange<LodgingFacade>(
            conflict, ConflictSource.fromStay(conflict.entity)));
        hasNewConflicts = true;
      }
    }

    // Add new transit conflicts
    for (final conflict in newConflicts.transitConflicts) {
      if (!_hasTransitChange(conflict.entity.id)) {
        transitChanges.add(_conflictToDateTimeChange<TransitFacade>(
            conflict, ConflictSource.fromTransit(conflict.entity)));
        hasNewConflicts = true;
      }
    }

    // Add new sight conflicts
    for (final conflict in newConflicts.sightConflicts) {
      if (!_hasSightChange(conflict.entity.id)) {
        sightChanges.add(_conflictToDateTimeChange<SightFacade>(
            conflict, ConflictSource.fromSight(conflict.entity)));
        hasNewConflicts = true;
      }
    }

    if (hasNewConflicts) {
      _isConfirmed = false;
    }

    return hasNewConflicts;
  }

  Set<String> _getExistingStayIds() =>
      stayChanges.map((c) => c.original.id ?? '').toSet();

  Set<String> _getExistingTransitIds() =>
      transitChanges.map((c) => c.original.id ?? '').toSet();

  Set<String> _getExistingSightIds() =>
      sightChanges.map((c) => c.original.id ?? '').toSet();

  bool _hasStayChange(String? id) =>
      id != null && stayChanges.any((c) => c.original.id == id);

  bool _hasTransitChange(String? id) =>
      id != null && transitChanges.any((c) => c.original.id == id);

  bool _hasSightChange(String? id) =>
      id != null && sightChanges.any((c) => c.original.id == id);

  DateTimeChange<T> _conflictToDateTimeChange<T extends TripEntity>(
      ConflictResult<T> conflictResult, ConflictSource conflictSource) {
    if (conflictResult.clampedEntity != null) {
      return DateTimeChange<T>.forClamping(
        original: conflictResult.entity,
        modified: conflictResult.clampedEntity!,
        timelinePosition: conflictResult.position,
        conflictSource: conflictSource,
      );
    }
    return DateTimeChange<T>.forDeletion(
      original: conflictResult.entity,
      timelinePosition: conflictResult.position,
      conflictSource: conflictSource,
    );
  }
}

/// Backward-compatible type aliases
typedef TripDataUpdatePlan = TripEntityUpdatePlan<TripEntity>;
typedef TripMetadataUpdatePlan = TripEntityUpdatePlan<TripMetadataFacade>;
