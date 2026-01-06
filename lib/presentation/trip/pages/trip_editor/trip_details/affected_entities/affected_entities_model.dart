import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

/// Represents an entity that may need adjustment when trip metadata changes
class AffectedEntityItem<T> {
  final T entity;
  T modifiedEntity;
  bool includeInSplitBy;

  AffectedEntityItem({
    required this.entity,
    required this.modifiedEntity,
    this.includeInSplitBy = false,
  });
}

/// Model to track all entities affected by trip metadata changes
class AffectedEntitiesModel {
  final TripMetadataFacade oldMetadata;
  final TripMetadataFacade newMetadata;

  final List<AffectedEntityItem<LodgingFacade>> affectedStays;
  final List<AffectedEntityItem<TransitFacade>> affectedTransits;
  final List<AffectedEntityItem<SightFacade>> affectedSights;
  final List<AffectedEntityItem<ExpenseFacade>> allExpenses;

  /// New contributors that were added
  List<String> get addedContributors => newMetadata.contributors
      .where((c) => !oldMetadata.contributors.contains(c))
      .toList();

  /// Contributors that were removed
  List<String> get removedContributors => oldMetadata.contributors
      .where((c) => !newMetadata.contributors.contains(c))
      .toList();

  bool get hasContributorChanges =>
      addedContributors.isNotEmpty || removedContributors.isNotEmpty;

  bool get hasDateChanges =>
      oldMetadata.startDate != newMetadata.startDate ||
      oldMetadata.endDate != newMetadata.endDate;

  bool get hasAffectedEntities =>
      affectedStays.isNotEmpty ||
      affectedTransits.isNotEmpty ||
      affectedSights.isNotEmpty ||
      (hasContributorChanges && allExpenses.isNotEmpty);

  AffectedEntitiesModel({
    required this.oldMetadata,
    required this.newMetadata,
    required this.affectedStays,
    required this.affectedTransits,
    required this.affectedSights,
    required this.allExpenses,
  });

  /// Creates a list of bloc events for all the modifications
  List<TripManagementEvent> createUpdateEvents() {
    final events = <TripManagementEvent>[];

    // Update stays
    for (final stayItem in affectedStays) {
      if (stayItem.modifiedEntity.checkinDateTime != null &&
          stayItem.modifiedEntity.checkoutDateTime != null) {
        events.add(UpdateTripEntity<LodgingFacade>.update(
          tripEntity: stayItem.modifiedEntity,
        ));
      }
    }

    // Update transits
    for (final transitItem in affectedTransits) {
      if (transitItem.modifiedEntity.departureDateTime != null &&
          transitItem.modifiedEntity.arrivalDateTime != null) {
        events.add(UpdateTripEntity<TransitFacade>.update(
          tripEntity: transitItem.modifiedEntity,
        ));
      }
    }

    // Update expenses with new contributors in splitBy
    for (final expenseItem in allExpenses) {
      if (expenseItem.includeInSplitBy) {
        final expense = expenseItem.modifiedEntity;
        for (final contributor in addedContributors) {
          if (!expense.splitBy.contains(contributor)) {
            expense.splitBy.add(contributor);
          }
        }
        events.add(UpdateTripEntity<ExpenseFacade>.update(
          tripEntity: expense,
        ));
      }
    }

    return events;
  }
}
