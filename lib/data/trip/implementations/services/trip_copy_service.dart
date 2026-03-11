import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/trip/implementations/budgeting/expense.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary/itinerary_plan_data_implementation.dart';
import 'package:wandrr/data/trip/implementations/lodging.dart';
import 'package:wandrr/data/trip/implementations/transit.dart';
import 'package:wandrr/data/trip/implementations/trip_metadata.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

/// Service that copies an entire trip (metadata + all sub-entities) into a new
/// trip using a single Firestore batch write for atomicity.
class TripCopyService {
  /// Copies a trip with the given parameters.
  ///
  /// Reads all sub-entities from the source trip, shifts their dates by the
  /// offset between [newStartDate] and the source trip's start date, and writes
  /// everything to a new trip document atomically.
  ///
  /// Returns the new [TripMetadataFacade] with its Firestore-generated ID.
  Future<TripMetadataFacade> copyTrip({
    required TripMetadataFacade sourceTripMetadata,
    required String newName,
    required DateTime newStartDate,
    required DateTime newEndDate,
    required List<String> contributors,
    required Money budget,
    required String thumbnailTag,
  }) async {
    final sourceId = sourceTripMetadata.id!;
    final dateOffset = newStartDate.difference(sourceTripMetadata.startDate!);

    // Read all source sub-collections
    final sourceDocRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(sourceId);

    final transitSnapshots = await sourceDocRef
        .collection(FirestoreCollections.transitCollectionName)
        .get();
    final lodgingSnapshots = await sourceDocRef
        .collection(FirestoreCollections.lodgingCollectionName)
        .get();
    final expenseSnapshots = await sourceDocRef
        .collection(FirestoreCollections.expenseCollectionName)
        .get();
    final itinerarySnapshots = await sourceDocRef
        .collection(FirestoreCollections.itineraryDataCollectionName)
        .get();

    // Create new trip metadata document to get the new trip ID
    final newTripMetadataRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripMetadataCollectionName)
        .doc();
    final newTripId = newTripMetadataRef.id;

    final newTripMetadata = TripMetadataFacade(
      id: newTripId,
      startDate: newStartDate,
      endDate: newEndDate,
      name: newName,
      contributors: contributors,
      thumbnailTag: thumbnailTag,
      budget: budget,
    );

    final newTripDocRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(newTripId);

    final batch = FirebaseFirestore.instance.batch();

    // 1. Write trip metadata
    final metadataImpl = TripMetadataModelImplementation.fromModelFacade(
        tripMetadataModelFacade: newTripMetadata);
    batch.set(newTripMetadataRef, metadataImpl.toJson());

    // 2. Copy transits with shifted dates
    for (final doc in transitSnapshots.docs) {
      final transit = TransitImplementation.fromDocumentSnapshot(sourceId, doc);
      final shiftedTransit = _shiftTransitDates(
          transit, dateOffset, newTripId, contributors, budget.currency);
      final newDocRef = newTripDocRef
          .collection(FirestoreCollections.transitCollectionName)
          .doc();
      final transitImpl = TransitImplementation.fromModelFacade(
          transitModelFacade: shiftedTransit);
      batch.set(newDocRef, transitImpl.toJson());
    }

    // 3. Copy lodgings with shifted dates
    for (final doc in lodgingSnapshots.docs) {
      final lodging = LodgingModelImplementation.fromDocumentSnapshot(
          tripId: sourceId, documentSnapshot: doc);
      final shiftedLodging = _shiftLodgingDates(
          lodging, dateOffset, newTripId, contributors, budget.currency);
      final newDocRef = newTripDocRef
          .collection(FirestoreCollections.lodgingCollectionName)
          .doc();
      final lodgingImpl = LodgingModelImplementation.fromModelFacade(
          lodgingModelFacade: shiftedLodging);
      batch.set(newDocRef, lodgingImpl.toJson());
    }

    // 4. Copy standalone expenses (amounts reset to 0)
    for (final doc in expenseSnapshots.docs) {
      final data = doc.data();
      final expenseImpl =
          ExpenseModelImplementation.fromJson(data['expense'] ?? data);
      final newExpense = StandaloneExpense(
        tripId: newTripId,
        expense: expenseImpl,
        title: data['title'] as String? ?? '',
        category: ExpenseCategory.other,
      );
      final newDocRef = newTripDocRef
          .collection(FirestoreCollections.expenseCollectionName)
          .doc();
      final newExpenseImpl =
          _createStandaloneExpenseImpl(newExpense, newDocRef);
      batch.set(newDocRef, newExpenseImpl);
    }

    // 5. Copy itinerary plan data with shifted days
    for (final doc in itinerarySnapshots.docs) {
      final data = doc.data();
      // Parse the original day from the document ID
      final originalDay = _parseItineraryDayFromId(doc.id);
      if (originalDay == null) continue;

      final shiftedDay = _shiftDate(originalDay, dateOffset);

      final planData =
          ItineraryPlanDataModelImplementation.fromDocumentSnapshot(
        tripId: newTripId,
        documentData: data,
        day: shiftedDay,
      );

      // Shift sight visitTimes
      final shiftedSights = planData.sights.map((sight) {
        return SightFacade(
          tripId: newTripId,
          name: sight.name,
          day: shiftedDay,
          expense: sight.expense.clone(),
          id: sight.id,
          location: sight.location?.clone(),
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
        notes: planData.notes.toList(),
        checkLists: planData.checkLists.toList(),
      );

      final newDocRef = newTripDocRef
          .collection(FirestoreCollections.itineraryDataCollectionName)
          .doc(shiftedDay.itineraryDateFormat);
      batch.set(newDocRef, shiftedPlanData.toJson());
    }

    // Commit all changes atomically
    await batch.commit();

    return newTripMetadata;
  }

  /// Shifts a DateTime by [offset] while preserving the time-of-day.
  DateTime _shiftDateTime(DateTime original, Duration offset) {
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

  /// Shifts just the date part (no time component).
  DateTime _shiftDate(DateTime original, Duration offset) {
    final shifted =
        DateTime(original.year, original.month, original.day).add(offset);
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  TransitFacade _shiftTransitDates(TransitFacade transit, Duration offset,
      String newTripId, List<String> contributors, String currency) {
    return TransitFacade(
      tripId: newTripId,
      transitOption: transit.transitOption,
      departureDateTime: transit.departureDateTime != null
          ? _shiftDateTime(transit.departureDateTime!, offset)
          : null,
      arrivalDateTime: transit.arrivalDateTime != null
          ? _shiftDateTime(transit.arrivalDateTime!, offset)
          : null,
      departureLocation: transit.departureLocation?.clone(),
      arrivalLocation: transit.arrivalLocation?.clone(),
      expense: transit.expense.clone(),
      journeyId: transit.journeyId,
      confirmationId: transit.confirmationId,
      operator: transit.operator,
      notes: transit.notes,
    );
  }

  LodgingFacade _shiftLodgingDates(LodgingFacade lodging, Duration offset,
      String newTripId, List<String> contributors, String currency) {
    return LodgingFacade(
      location: lodging.location?.clone(),
      checkinDateTime: lodging.checkinDateTime != null
          ? _shiftDateTime(lodging.checkinDateTime!, offset)
          : null,
      checkoutDateTime: lodging.checkoutDateTime != null
          ? _shiftDateTime(lodging.checkoutDateTime!, offset)
          : null,
      tripId: newTripId,
      expense: lodging.expense.clone(),
      confirmationId: lodging.confirmationId,
      notes: lodging.notes,
    );
  }

  /// Parses the itinerary day from a document ID in "ddMMyyyy" format.
  DateTime? _parseItineraryDayFromId(String docId) {
    try {
      if (docId.length != 8) return null;
      final day = int.parse(docId.substring(0, 2));
      final month = int.parse(docId.substring(2, 4));
      final year = int.parse(docId.substring(4, 8));
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Creates a JSON map for a standalone expense document.
  Map<String, dynamic> _createStandaloneExpenseImpl(
      StandaloneExpense expense, DocumentReference docRef) {
    final expenseImpl = ExpenseModelImplementation.fromModelFacade(
        expenseModelFacade: expense.expense);
    return {
      'title': expense.title,
      'category': expense.category.name,
      'expense': expenseImpl.toJson(),
    };
  }
}
