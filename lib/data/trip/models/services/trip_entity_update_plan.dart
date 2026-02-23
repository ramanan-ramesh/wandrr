import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

import 'entity_change.dart';

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

  /// Updates the conflict lists in-place.
  void updateConflicts({
    List<StayChange>? stays,
    List<TransitChange>? transits,
    List<SightChange>? sights,
    List<ExpenseSplitChange>? expenses,
  }) {
    if (stays != null) {
      stayChanges.clear();
      stayChanges.addAll(stays);
    }
    if (transits != null) {
      transitChanges.clear();
      transitChanges.addAll(transits);
    }
    if (sights != null) {
      sightChanges.clear();
      sightChanges.addAll(sights);
    }
    if (expenses != null) {
      expenseChanges.clear();
      expenseChanges.addAll(expenses);
    }
    _isConfirmed = false;
  }
}

/// Backward-compatible type aliases
typedef TripDataUpdatePlan = TripEntityUpdatePlan<TripEntity>;
typedef TripMetadataUpdatePlan = TripEntityUpdatePlan<TripMetadataFacade>;
