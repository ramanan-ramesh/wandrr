import 'package:collection/collection.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_entities_model.dart';

/// Factory to create AffectedEntitiesModel from trip data
class AffectedEntitiesModelFactory {
  /// Creates an AffectedEntitiesModel by analyzing what changed between old and new metadata
  static AffectedEntitiesModel? create({
    required TripMetadataFacade oldMetadata,
    required TripMetadataFacade newMetadata,
    required TripDataFacade tripData,
  }) {
    final haveTripDatesChanged =
        _haveTripDatesChanged(oldMetadata, newMetadata);
    final haveContributorsChanged =
        _haveContributorsChanged(oldMetadata, newMetadata);

    if (!haveTripDatesChanged && !haveContributorsChanged) {
      return null;
    }

    // Collect affected stays
    final affectedStays = <AffectedEntityItem<LodgingFacade>>[];
    if (haveTripDatesChanged) {
      affectedStays.addAll(_findAffectedStays(
        tripData.lodgingCollection.collectionItems,
        oldMetadata,
        newMetadata,
      ));
    }

    // Collect affected transits
    final affectedTransits = <AffectedEntityItem<TransitFacade>>[];
    if (haveTripDatesChanged) {
      affectedTransits.addAll(_findAffectedTransits(
        tripData.transitCollection.collectionItems,
        oldMetadata,
        newMetadata,
      ));
    }

    // Collect affected sights
    final affectedSights = <AffectedEntityItem<SightFacade>>[];
    if (haveTripDatesChanged) {
      for (final itinerary in tripData.itineraryCollection) {
        affectedSights.addAll(_findAffectedSights(
          itinerary.planData.sights,
          oldMetadata,
          newMetadata,
        ));
      }
    }

    // Collect all expenses for contributor changes
    final allExpenses = <AffectedEntityItem<ExpenseBearingTripEntity>>[];
    if (haveContributorsChanged) {
      allExpenses.addAll(_collectAllExpenses(tripData));
    }

    // Only return model if there are affected entities or contributor changes with expenses
    if (affectedStays.isEmpty &&
        affectedTransits.isEmpty &&
        affectedSights.isEmpty &&
        allExpenses.isEmpty) {
      return null;
    }

    return AffectedEntitiesModel(
      oldMetadata: oldMetadata,
      newMetadata: newMetadata,
      affectedStays: affectedStays,
      affectedTransits: affectedTransits,
      affectedSights: affectedSights,
      allExpenses: allExpenses,
      tripData: tripData,
    );
  }

  static bool _haveTripDatesChanged(
      TripMetadataFacade oldMeta, TripMetadataFacade newMeta) {
    var oldStartDate = oldMeta.startDate!;
    var oldEndDate = oldMeta.endDate!;
    var newStartDate = newMeta.startDate!;
    var newEndDate = newMeta.endDate!;
    return !oldStartDate.isOnSameDayAs(newStartDate) ||
        !oldEndDate.isOnSameDayAs(newEndDate);
  }

  static bool _haveContributorsChanged(
      TripMetadataFacade oldMeta, TripMetadataFacade newMeta) {
    return !const ListEquality()
        .equals(oldMeta.contributors, newMeta.contributors);
  }

  /// Find stays that fall outside the new trip dates
  /// Clamps stays where possible to fit within new dates
  static Iterable<AffectedEntityItem<LodgingFacade>> _findAffectedStays(
    Iterable<LodgingFacade> lodgings,
    TripMetadataFacade oldMetadata,
    TripMetadataFacade newMetadata,
  ) {
    final affectedStays = <AffectedEntityItem<LodgingFacade>>[];
    final newStart = newMetadata.startDate!;
    final newEnd = DateTime(newMetadata.endDate!.year,
        newMetadata.endDate!.month, newMetadata.endDate!.day, 23, 59);

    for (final lodging in lodgings) {
      final checkin = lodging.checkinDateTime!;
      final checkout = lodging.checkoutDateTime!;

      // Check if stay needs adjustment
      final isCheckinOutsideNewRange =
          checkin.isBefore(newStart) || checkin.isAfter(newEnd);
      final isCheckoutOutsideNewRange =
          checkout.isBefore(newStart) || checkout.isAfter(newEnd);

      if (isCheckinOutsideNewRange || isCheckoutOutsideNewRange) {
        // Create a modified copy with clamped dates
        final modifiedLodging = lodging.clone();

        // Try to clamp dates to fit within new range
        DateTime? clampedCheckin = checkin;
        DateTime? clampedCheckout = checkout;

        // Clamp checkin
        if (checkin.isBefore(newStart)) {
          clampedCheckin = DateTime(
            newStart.year,
            newStart.month,
            newStart.day,
            checkin.hour,
            checkin.minute,
          );
        } else if (checkin.isAfter(newEnd)) {
          clampedCheckin = null;
        }

        // Clamp checkout
        if (checkout.isAfter(newEnd)) {
          clampedCheckout = DateTime(
            newEnd.year,
            newEnd.month,
            newEnd.day,
            checkout.hour,
            checkout.minute,
          );
        } else if (checkout.isBefore(newStart)) {
          clampedCheckout = null;
        }

        // Validate the clamped dates make sense
        if (clampedCheckin != null &&
            clampedCheckout != null &&
            !clampedCheckin.isBefore(clampedCheckout)) {
          clampedCheckin = null;
          clampedCheckout = null;
        }

        modifiedLodging.checkinDateTime = clampedCheckin;
        modifiedLodging.checkoutDateTime = clampedCheckout;

        affectedStays.add(AffectedEntityItem(
          entity: lodging,
          modifiedEntity: modifiedLodging,
        ));
      }
    }

    return affectedStays;
  }

  /// Find transits that fall outside the new trip dates
  static Iterable<AffectedEntityItem<TransitFacade>> _findAffectedTransits(
    Iterable<TransitFacade> transits,
    TripMetadataFacade oldMetadata,
    TripMetadataFacade newMetadata,
  ) {
    final affectedTransits = <AffectedEntityItem<TransitFacade>>[];
    final newStart = newMetadata.startDate!;
    final newEnd = newMetadata.endDate!;

    for (final transit in transits) {
      final departure = transit.departureDateTime!;
      final arrival = transit.arrivalDateTime!;

      final isDepartureOutside =
          departure.isBefore(newStart) || departure.isAfter(newEnd);
      final isArrivalOutside =
          arrival.isBefore(newStart) || arrival.isAfter(newEnd);

      if (isDepartureOutside || isArrivalOutside) {
        final modifiedTransit = transit.clone();
        modifiedTransit.departureDateTime = null;
        modifiedTransit.arrivalDateTime = null;

        affectedTransits.add(AffectedEntityItem(
          entity: transit,
          modifiedEntity: modifiedTransit,
        ));
      }
    }

    return affectedTransits;
  }

  /// Find sights that fall outside the new trip dates
  static Iterable<AffectedEntityItem<SightFacade>> _findAffectedSights(
    Iterable<SightFacade> sights,
    TripMetadataFacade oldMetadata,
    TripMetadataFacade newMetadata,
  ) {
    final affectedSights = <AffectedEntityItem<SightFacade>>[];
    final newStart = newMetadata.startDate!;
    final newEnd = newMetadata.endDate!;

    for (final sight in sights) {
      final sightDay = sight.day;
      final isDayOutside =
          sightDay.isBefore(newStart) || sightDay.isAfter(newEnd);

      if (isDayOutside) {
        final modifiedSight = sight.clone();
        modifiedSight.visitTime = null;

        affectedSights.add(AffectedEntityItem(
          entity: sight,
          modifiedEntity: modifiedSight,
        ));
      }
    }

    return affectedSights;
  }

  /// Collect all expenses from transit, lodging, standalone expenses, and sights
  static Iterable<AffectedEntityItem<ExpenseBearingTripEntity>>
      _collectAllExpenses(
    TripDataFacade tripData,
  ) {
    final allExpenses = <AffectedEntityItem<ExpenseBearingTripEntity>>[];

    // Collect standalone expenses (not linked to any entity)
    for (final expense in tripData.expenseCollection.collectionItems) {
      allExpenses.add(AffectedEntityItem(
        entity: expense,
        modifiedEntity: expense.clone(),
      ));
    }

    // Collect transit expenses and link them
    for (final transit in tripData.transitCollection.collectionItems) {
      allExpenses.add(AffectedEntityItem(
        entity: transit,
        modifiedEntity: transit.clone(),
      ));
    }

    // Collect lodging expenses and link them
    for (final lodging in tripData.lodgingCollection.collectionItems) {
      allExpenses.add(AffectedEntityItem(
        entity: lodging,
        modifiedEntity: lodging,
      ));
    }

    // Collect sight expenses and link them
    for (final itinerary in tripData.itineraryCollection) {
      for (final sight in itinerary.planData.sights) {
        allExpenses.add(AffectedEntityItem(
          entity: sight,
          modifiedEntity: sight.clone(),
        ));
      }
    }

    return allExpenses;
  }
}
