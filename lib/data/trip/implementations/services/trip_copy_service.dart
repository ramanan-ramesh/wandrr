import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary/itinerary_plan_data_implementation.dart';
import 'package:wandrr/data/trip/implementations/trip_metadata.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

/// Service that copies an entire trip (metadata + all sub-entities) into a new
/// trip using a single Firestore batch write for atomicity.
class TripCopyService {
  /// Copies a trip from an already-loaded TripData, by shifting trip start and end dates.
  ///
  /// [sourceTripData] - The trip to copy.
  /// [targetTripMetadata] - The trip metadata to use for the new trip.
  /// [apiServicesRepository] - The API services repository to use for the new trip.
  /// Returns the new [TripMetadataFacade] with its Firestore-generated ID.
  static Future<TripMetadataFacade> copyTrip({
    required TripDataModelEventHandler sourceTripData,
    required TripMetadataFacade targetTripMetadata,
    required ApiServicesRepositoryFacade apiServicesRepository,
  }) async {
    final sourceTripMetadata = sourceTripData.tripMetadata;
    final dateOffset =
        targetTripMetadata.startDate!.difference(sourceTripMetadata.startDate!);
    final batch = FirebaseFirestore.instance.batch();

    // Wait for trip data to be fully loaded
    if (!sourceTripData.isFullyLoadedValue) {
      await sourceTripData.isFullyLoaded.lastWhere((isLoaded) => isLoaded);
    }

    // Create new trip metadata document to get the new trip ID
    final newTripMetadataRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripMetadataCollectionName)
        .doc();
    final newTripId = newTripMetadataRef.id;
    targetTripMetadata.id = newTripId;

    // 1. Write trip metadata
    final newTripMetadata = TripMetadataModelImplementation.fromModelFacade(
        tripMetadataModelFacade: targetTripMetadata);
    batch.set(newTripMetadataRef, newTripMetadata.toJson());

    // 2. Copy transits with shifted dates
    _writeTripEntityCollectionToBatch(
        sourceTripData.transitCollection,
        dateOffset,
        _shiftTransitDates,
        newTripId,
        FirestoreCollections.transitCollectionName,
        batch);

    // 3. Copy lodgings with shifted dates
    _writeTripEntityCollectionToBatch(
        sourceTripData.lodgingCollection,
        dateOffset,
        _shiftLodgingDates,
        newTripId,
        FirestoreCollections.lodgingCollectionName,
        batch);

    // 4. Copy standalone expenses
    _writeTripEntityCollectionToBatch(
        sourceTripData.expenseCollection,
        dateOffset,
        _shiftExpenseDates,
        newTripId,
        FirestoreCollections.expenseCollectionName,
        batch);

    // 5. Copy itinerary plan data with shifted days
    _shiftItineraryPlanDataDates(
        sourceTripData.itineraryCollection, dateOffset, newTripId, batch);

    await batch.commit();

    return newTripMetadata;
  }

  static void _shiftItineraryPlanDataDates(
      ItineraryFacadeCollectionEventHandler itineraryCollection,
      Duration dateOffset,
      String newTripId,
      WriteBatch batch) {
    for (final itineraryPlanData
        in itineraryCollection.map((e) => e.planData)) {
      if (itineraryPlanData.getValidationResult() ==
          ItineraryPlanDataValidationResult.noContent) {
        continue;
      }
      final shiftedDay = _shiftDate(itineraryPlanData.day, dateOffset);

      // Shift sight visitTimes
      final shiftedSights = itineraryPlanData.sights.map((sight) {
        return SightFacade(
          tripId: newTripId,
          name: sight.name,
          day: shiftedDay,
          expense: sight.expense,
          id: sight.id,
          location: sight.location,
          visitTime: sight.visitTime != null
              ? _shiftDateTime(sight.visitTime!, dateOffset)
              : null,
          description: sight.description,
        );
      }).toList();

      final shiftedPlanData = ItineraryPlanDataModelImplementation(
        tripId: newTripId,
        id: shiftedDay.itineraryDateFormat,
        day: shiftedDay,
        sights: shiftedSights,
        notes: itineraryPlanData.notes.toList(),
        checkLists: itineraryPlanData.checkLists.toList(),
      );

      final newDocRef = FirebaseFirestore.instance
          .collection(FirestoreCollections.tripCollectionName)
          .doc(newTripId)
          .collection(FirestoreCollections.itineraryDataCollectionName)
          .doc(shiftedDay.itineraryDateFormat);
      batch.set(newDocRef, shiftedPlanData.toJson());
    }
  }

  static void _writeTripEntityCollectionToBatch<T extends TripEntity>(
      ModelCollectionModifier<T> tripEntityCollection,
      Duration dateOffset,
      void Function(T source, Duration dateOffset) tripEntityTransformer,
      String newTripId,
      String collectionName,
      WriteBatch batch) {
    for (final tripEntity in tripEntityCollection.collectionItems) {
      tripEntityTransformer(tripEntity, dateOffset);
      final newDocRef = FirebaseFirestore.instance
          .collection(FirestoreCollections.tripCollectionName)
          .doc(newTripId)
          .collection(collectionName)
          .doc();
      final tripEntityRepositoryItem =
          tripEntityCollection.repositoryItemCreator(tripEntity);
      batch.set(newDocRef, tripEntityRepositoryItem.toJson());
    }
  }

  /// Shifts a DateTime by [offset] while preserving the time-of-day.
  static DateTime _shiftDateTime(DateTime original, Duration offset) {
    final shifted = original.add(offset);
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      original.hour,
      original.minute,
      original.second,
    );
  }

  static void _shiftTransitDates(TransitFacade transit, Duration offset) {
    transit.departureDateTime = transit.departureDateTime != null
        ? _shiftDateTime(transit.departureDateTime!, offset)
        : null;
    transit.arrivalDateTime = transit.arrivalDateTime != null
        ? _shiftDateTime(transit.arrivalDateTime!, offset)
        : null;
  }

  static void _shiftLodgingDates(LodgingFacade lodging, Duration offset) {
    lodging.checkinDateTime = lodging.checkinDateTime != null
        ? _shiftDateTime(lodging.checkinDateTime!, offset)
        : null;
    lodging.checkoutDateTime = lodging.checkoutDateTime != null
        ? _shiftDateTime(lodging.checkoutDateTime!, offset)
        : null;
  }

  static void _shiftExpenseDates(StandaloneExpense expense, Duration offset) {
    expense.expense.dateTime = expense.expense.dateTime != null
        ? _shiftDateTime(expense.expense.dateTime!, offset)
        : null;
  }

  /// Shifts just the date part (no time component).
  static DateTime _shiftDate(DateTime original, Duration offset) {
    final shifted =
        DateTime(original.year, original.month, original.day).add(offset);
    return DateTime(shifted.year, shifted.month, shifted.day);
  }
}
