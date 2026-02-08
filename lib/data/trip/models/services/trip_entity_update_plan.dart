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
    this.stayChanges = const [],
    this.transitChanges = const [],
    this.sightChanges = const [],
    this.expenseChanges = const [],
  });

  /// Whether there are any conflicts at all
  bool get hasConflicts =>
      stayChanges.isNotEmpty ||
      transitChanges.isNotEmpty ||
      sightChanges.isNotEmpty ||
      expenseChanges.isNotEmpty;

  /// Total number of conflicts
  int get totalConflicts =>
      stayChanges.length +
      transitChanges.length +
      sightChanges.length +
      expenseChanges.length;

  /// Whether user has confirmed the plan
  bool get isConfirmed => _isConfirmed;

  /// Mark the plan as confirmed by user
  void confirm() => _isConfirmed = true;

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
  // Utility Methods
  // =========================================================================

  /// Syncs expense deletion state when an ExpenseBearingTripEntity is deleted/restored
  void syncExpenseDeletionState(dynamic entity, bool isDeleted) {
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
}

/// Backward-compatible type aliases
typedef TripDataUpdatePlan = TripEntityUpdatePlan<TripEntity>;
typedef TripMetadataUpdatePlan = TripEntityUpdatePlan<TripMetadataFacade>;
