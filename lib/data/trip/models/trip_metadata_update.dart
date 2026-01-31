import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

/// Represents the type of change for a trip entity
enum EntityChangeType {
  /// Entity will be updated with new values
  update,

  /// Entity will be deleted
  delete,
}

/// Represents a pending change to a trip entity
/// Used by both the UI (AffectedEntitiesEditor) and the data layer
class EntityChange<T extends TripEntity> {
  final T originalEntity;
  T modifiedEntity;
  EntityChangeType changeType;

  /// For expenses: whether to add new contributors to splitBy
  bool includeInSplitBy;

  /// Optional: description of the conflict (for timeline conflict UI)
  final String? conflictDescription;

  /// Optional: original time description (for timeline conflict UI)
  final String? originalTimeDescription;

  EntityChange({
    required this.originalEntity,
    required this.modifiedEntity,
    this.changeType = EntityChangeType.update,
    this.includeInSplitBy = false,
    this.conflictDescription,
    this.originalTimeDescription,
  });

  EntityChange.forDeletion({
    required this.originalEntity,
    this.conflictDescription,
    this.originalTimeDescription,
  })  : modifiedEntity = originalEntity,
        changeType = EntityChangeType.delete,
        includeInSplitBy = false;

  bool get isUpdate => changeType == EntityChangeType.update;

  bool get isDelete => changeType == EntityChangeType.delete;

  bool get isMarkedForDeletion => changeType == EntityChangeType.delete;

  void markForDeletion() {
    changeType = EntityChangeType.delete;
  }

  void restore() {
    changeType = EntityChangeType.update;
  }
}

/// Base class for entity update plans (transits, stays, sights)
/// Used for timeline conflict resolution
class TripEntityUpdatePlan {
  /// Changes to stays (lodgings)
  final List<EntityChange<LodgingFacade>> stayChanges;

  /// Changes to transits
  final List<EntityChange<TransitFacade>> transitChanges;

  /// Changes to sights
  final List<EntityChange<SightFacade>> sightChanges;

  /// Trip start date for date validation
  final DateTime tripStartDate;

  /// Trip end date for date validation
  final DateTime tripEndDate;

  /// Whether user has acknowledged/reviewed the conflicts
  bool _isAcknowledged = false;

  TripEntityUpdatePlan({
    required this.stayChanges,
    required this.transitChanges,
    required this.sightChanges,
    required this.tripStartDate,
    required this.tripEndDate,
  });

  /// Factory to create from timeline conflict detection
  factory TripEntityUpdatePlan.forTimelineConflicts({
    required List<EntityChange<TransitFacade>> transitConflicts,
    required List<EntityChange<LodgingFacade>> stayConflicts,
    required List<EntityChange<SightFacade>> sightConflicts,
    required DateTime tripStartDate,
    required DateTime tripEndDate,
  }) {
    return TripEntityUpdatePlan(
      transitChanges: transitConflicts,
      stayChanges: stayConflicts,
      sightChanges: sightConflicts,
      tripStartDate: tripStartDate,
      tripEndDate: tripEndDate,
    );
  }

  /// Whether there are any conflicts
  bool get hasConflicts =>
      stayChanges.isNotEmpty ||
      transitChanges.isNotEmpty ||
      sightChanges.isNotEmpty;

  /// Total number of conflicts
  int get totalConflicts =>
      stayChanges.length + transitChanges.length + sightChanges.length;

  /// Whether user has acknowledged the conflicts
  bool get isAcknowledged => _isAcknowledged;

  /// Mark the plan as acknowledged by user
  void acknowledge() {
    _isAcknowledged = true;
  }

  /// Get stays marked for deletion
  Iterable<LodgingFacade> get deletedStays =>
      stayChanges.where((c) => c.isDelete).map((c) => c.originalEntity);

  /// Get transits marked for deletion
  Iterable<TransitFacade> get deletedTransits =>
      transitChanges.where((c) => c.isDelete).map((c) => c.originalEntity);

  /// Get sights marked for deletion
  Iterable<SightFacade> get deletedSights =>
      sightChanges.where((c) => c.isDelete).map((c) => c.originalEntity);

  /// Get stays to be updated
  Iterable<LodgingFacade> get updatedStays =>
      stayChanges.where((c) => c.isUpdate).map((c) => c.modifiedEntity);

  /// Get transits to be updated
  Iterable<TransitFacade> get updatedTransits =>
      transitChanges.where((c) => c.isUpdate).map((c) => c.modifiedEntity);

  /// Get sights to be updated
  Iterable<SightFacade> get updatedSights =>
      sightChanges.where((c) => c.isUpdate).map((c) => c.modifiedEntity);
}

/// Encapsulates all changes resulting from a trip metadata update
/// Extends TripEntityUpdatePlan to add contributor-related changes
class TripMetadataUpdatePlan extends TripEntityUpdatePlan {
  final TripMetadataFacade oldMetadata;
  final TripMetadataFacade newMetadata;

  /// All expenses (standalone + from transits/lodgings/sights) for contributor changes
  final Iterable<EntityChange<ExpenseBearingTripEntity>> expenseChanges;

  /// New contributors added to the trip
  final Iterable<String> addedContributors;

  /// Contributors removed from the trip
  final Iterable<String> removedContributors;

  TripMetadataUpdatePlan({
    required this.oldMetadata,
    required this.newMetadata,
    required List<EntityChange<LodgingFacade>> stayChanges,
    required List<EntityChange<TransitFacade>> transitChanges,
    required List<EntityChange<SightFacade>> sightChanges,
    required this.expenseChanges,
  })  : addedContributors = newMetadata.contributors.where(
            (contributor) => !oldMetadata.contributors.contains(contributor)),
        removedContributors = oldMetadata.contributors.where(
            (contributor) => !newMetadata.contributors.contains(contributor)),
        super(
          stayChanges: stayChanges,
          transitChanges: transitChanges,
          sightChanges: sightChanges,
          tripStartDate: newMetadata.startDate!,
          tripEndDate: newMetadata.endDate!,
        );

  /// Whether trip dates changed
  bool get hasDateChanges =>
      !oldMetadata.startDate!.isOnSameDayAs(newMetadata.startDate!) ||
      !oldMetadata.endDate!.isOnSameDayAs(newMetadata.endDate!);

  /// Whether contributors changed
  bool get hasContributorChanges =>
      addedContributors.isNotEmpty || removedContributors.isNotEmpty;

  /// Whether currency changed
  bool get hasCurrencyChange =>
      oldMetadata.budget.currency != newMetadata.budget.currency;

  /// Whether there are any entity changes to apply
  bool get hasEntityChanges =>
      stayChanges.isNotEmpty ||
      transitChanges.isNotEmpty ||
      sightChanges.isNotEmpty ||
      expenseChanges.any((e) => e.includeInSplitBy);

  /// Whether there are any affected entities that need user review
  bool get hasAffectedEntities =>
      stayChanges.isNotEmpty ||
      transitChanges.isNotEmpty ||
      sightChanges.isNotEmpty ||
      (hasContributorChanges && expenseChanges.isNotEmpty);

  /// Syncs expense deletion state when an ExpenseBearingTripEntity is deleted/restored
  void syncExpenseDeletionState(
      ExpenseBearingTripEntity entity, bool isDeleted) {
    for (final expenseChange in expenseChanges) {
      if (expenseChange.originalEntity.id == entity.id) {
        if (isDeleted) {
          expenseChange.markForDeletion();
        } else {
          expenseChange.restore();
        }
        break;
      }
    }
  }
}
