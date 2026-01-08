import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

/// Action to take on an affected entity
enum AffectedEntityAction {
  /// Keep and update the entity with modified values
  update,

  /// Delete the entity
  delete,
}

/// Represents an entity that may need adjustment when trip metadata changes
class AffectedEntityItem<T extends TripEntity> {
  final T entity;
  T modifiedEntity;
  bool includeInSplitBy;
  AffectedEntityAction action;

  AffectedEntityItem({
    required this.entity,
    required this.modifiedEntity,
    this.includeInSplitBy = false,
    this.action = AffectedEntityAction.update,
  });

  bool get isMarkedForDeletion => action == AffectedEntityAction.delete;
}

/// Model to track all entities affected by trip metadata changes
class AffectedEntitiesModel {
  final TripMetadataFacade oldMetadata;
  final TripMetadataFacade newMetadata;

  final TripDataFacade tripData;

  final Iterable<AffectedEntityItem<LodgingFacade>> affectedStays;
  final Iterable<AffectedEntityItem<TransitFacade>> affectedTransits;
  final Iterable<AffectedEntityItem<SightFacade>> affectedSights;
  final Iterable<AffectedEntityItem<ExpenseLinkedTripEntity>> allExpenses;

  /// New contributors that were added
  Iterable<String> get addedContributors => newMetadata.contributors
      .where((c) => !oldMetadata.contributors.contains(c));

  /// Contributors that were removed
  Iterable<String> get removedContributors => oldMetadata.contributors
      .where((c) => !newMetadata.contributors.contains(c));

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
    required this.tripData,
  });

  /// Creates a list of bloc events for all the modifications
  List<TripManagementEvent> createUpdateEvents() {
    final events = <TripManagementEvent>[];

    // Handle stays - update or delete
    for (final stayItem in affectedStays) {
      if (stayItem.isMarkedForDeletion) {
        events.add(UpdateTripEntity<LodgingFacade>.delete(
          tripEntity: stayItem.entity,
        ));
      } else if (stayItem.modifiedEntity.checkinDateTime != null &&
          stayItem.modifiedEntity.checkoutDateTime != null) {
        events.add(UpdateTripEntity<LodgingFacade>.update(
          tripEntity: stayItem.modifiedEntity,
        ));
      }
    }

    // Handle transits - update or delete
    for (final transitItem in affectedTransits) {
      if (transitItem.isMarkedForDeletion) {
        events.add(UpdateTripEntity<TransitFacade>.delete(
          tripEntity: transitItem.entity,
        ));
      } else if (transitItem.modifiedEntity.departureDateTime != null &&
          transitItem.modifiedEntity.arrivalDateTime != null) {
        events.add(UpdateTripEntity<TransitFacade>.update(
          tripEntity: transitItem.modifiedEntity,
        ));
      }
    }

    // Handle sights - we need to handle these through itinerary updates
    for (final sightItem in affectedSights) {
      var originalSight = sightItem.entity;
      if (sightItem.isMarkedForDeletion) {
        var day = originalSight.day;
        var itineraryPlanData = tripData.itineraryCollection
            .firstWhere((itinerary) => itinerary.day.isOnSameDayAs(day))
            .planData;
        itineraryPlanData.sights.removeWhere((s) => s == originalSight);
        events.add(UpdateTripEntity<ItineraryPlanData>.update(
          tripEntity: itineraryPlanData,
        ));
      }
      //TODO: Handle sight updates, especially cases where date itself has changed
    }

    // Handle expenses - add new contributors to splitBy if selected
    for (final expenseItem in allExpenses) {
      final event = _createExpenseUpdateEvent(expenseItem);
      if (event != null) {
        events.add(event);
      }
    }

    return events;
  }

  UpdateTripEntity? _createExpenseUpdateEvent(
      AffectedEntityItem<ExpenseLinkedTripEntity> expenseItem) {
    if (expenseItem.isMarkedForDeletion) {
      var expenseLinkedTripEntity = expenseItem.entity;
      if (expenseLinkedTripEntity is ExpenseLinkedTripEntity<ExpenseFacade>) {
        return UpdateTripEntity<ExpenseFacade>.delete(
          tripEntity: expenseLinkedTripEntity as ExpenseFacade,
        );
      }
    } else if (expenseItem.includeInSplitBy) {
      var modifiedEntity = expenseItem.modifiedEntity;
      final expense = modifiedEntity.expense;
      for (final contributor in addedContributors) {
        if (!expense.splitBy.contains(contributor)) {
          expense.splitBy.add(contributor);
        }
      }
      if (modifiedEntity is ExpenseLinkedTripEntity<ExpenseFacade>) {
        return UpdateTripEntity<ExpenseFacade>.update(
          tripEntity: modifiedEntity as ExpenseFacade,
        );
      } else if (modifiedEntity is ExpenseLinkedTripEntity<TransitFacade> &&
          modifiedEntity is TransitFacade) {
        return UpdateTripEntity<TransitFacade>.update(
          tripEntity: modifiedEntity,
        );
      } else if (modifiedEntity is ExpenseLinkedTripEntity<LodgingFacade> &&
          modifiedEntity is LodgingFacade) {
        return UpdateTripEntity<LodgingFacade>.update(
          tripEntity: modifiedEntity,
        );
      } else if (modifiedEntity is ExpenseLinkedTripEntity<SightFacade> &&
          modifiedEntity is SightFacade) {
        var itineraryPlanData = tripData.itineraryCollection
            .firstWhere(
                (itinerary) => itinerary.day.isOnSameDayAs(modifiedEntity.day))
            .planData;
        var indexOfSight =
            itineraryPlanData.sights.indexOf(expenseItem.entity as SightFacade);
        itineraryPlanData.sights[indexOfSight] = modifiedEntity;
        return UpdateTripEntity<ItineraryPlanData>.update(
          tripEntity: itineraryPlanData,
        );
      }
    }
    return null;
  }
}
