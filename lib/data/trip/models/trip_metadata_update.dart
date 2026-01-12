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
/// Used by both the UI (AffectedEntitiesEditor) and the data layer (TripMetadataUpdateExecutor)
class EntityChange<T extends TripEntity> {
  final T originalEntity;
  T modifiedEntity;
  EntityChangeType changeType;

  /// For expenses: whether to add new contributors to splitBy
  bool includeInSplitBy;

  EntityChange({
    required this.originalEntity,
    required this.modifiedEntity,
    this.changeType = EntityChangeType.update,
    this.includeInSplitBy = false,
  });

  EntityChange.forDeletion({
    required this.originalEntity,
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

/// Encapsulates all changes resulting from a trip metadata update
/// This is the input to the batch update operation and is also used by the UI
class TripMetadataUpdatePlan {
  final TripMetadataFacade oldMetadata;
  final TripMetadataFacade newMetadata;

  /// Changes to stays (lodgings)
  final Iterable<EntityChange<LodgingFacade>> stayChanges;

  /// Changes to transits
  final Iterable<EntityChange<TransitFacade>> transitChanges;

  /// Changes to sights
  final Iterable<EntityChange<SightFacade>> sightChanges;

  /// All expenses (standalone + from transits/lodgings/sights) for contributor changes
  final Iterable<EntityChange<ExpenseBearingTripEntity>> expenseChanges;

  /// New contributors added to the trip
  final Iterable<String> addedContributors;

  /// Contributors removed from the trip
  final Iterable<String> removedContributors;

  TripMetadataUpdatePlan({
    required this.oldMetadata,
    required this.newMetadata,
    required this.stayChanges,
    required this.transitChanges,
    required this.sightChanges,
    required this.expenseChanges,
  })  : addedContributors = newMetadata.contributors.where(
            (contributor) => !oldMetadata.contributors.contains(contributor)),
        removedContributors = oldMetadata.contributors.where(
            (contributor) => !newMetadata.contributors.contains(contributor));

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

  /// Get stays marked for deletion
  Iterable<LodgingFacade> get deletedStays =>
      stayChanges.where((c) => c.isDelete).map((c) => c.originalEntity);

  /// Get transits marked for deletion
  Iterable<TransitFacade> get deletedTransits =>
      transitChanges.where((c) => c.isDelete).map((c) => c.originalEntity);

  /// Get stays to be updated
  Iterable<LodgingFacade> get updatedStays =>
      stayChanges.where((c) => c.isUpdate).map((c) => c.modifiedEntity);

  /// Get transits to be updated
  Iterable<TransitFacade> get updatedTransits =>
      transitChanges.where((c) => c.isUpdate).map((c) => c.modifiedEntity);

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
