import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary.dart';
import 'package:wandrr/data/trip/implementations/plan_data/plan_data_model_implementation.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

class ItineraryCollection extends ItineraryFacadeCollectionEventHandler {
  final _subscriptions = <StreamSubscription>[];
  final String tripId;
  DateTime _startDate;
  DateTime _endDate;
  List<ItineraryModelEventHandler> _itineraries;

  static Future<ItineraryCollection> createInstance({
    required ModelCollectionFacade<TransitFacade> transitCollection,
    required ModelCollectionFacade<LodgingFacade> lodgingCollection,
    required TripMetadataFacade tripMetadata,
  }) async {
    final itineraries = await _createItineraryList(
      tripMetadata: tripMetadata,
      transitCollection: transitCollection,
      lodgingCollection: lodgingCollection,
    );
    return ItineraryCollection._(
      transitCollection: transitCollection,
      lodgingCollection: lodgingCollection,
      tripId: tripMetadata.id!,
      startDate: tripMetadata.startDate!,
      endDate: tripMetadata.endDate!,
      itineraries: itineraries,
    );
  }

  @override
  Future dispose() async {
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    for (var itinerary in _itineraries) {
      await itinerary.dispose();
    }
    _itineraries.clear();
  }

  @override
  Iterator<ItineraryModelEventHandler> get iterator => _itineraries.iterator;

  @override
  Future<void> updateTripDays(DateTime startDate, DateTime endDate) async {
    final oldDates = _getDateRange(_startDate, _endDate);
    final newDates = _getDateRange(startDate, endDate);

    final datesToAdd = newDates.difference(oldDates);
    final datesToRemove = oldDates.difference(newDates);

    var writeBatch = FirebaseFirestore.instance.batch();
    for (final date in datesToRemove) {
      var itinerary = _itineraries
          .singleWhere((itinerary) => itinerary.day.isOnSameDayAs(date));
      itinerary.dispose();
      var planDataModelImplementation =
          PlanDataModelImplementation.fromModelFacade(
              planDataFacade: itinerary.planData,
              collectionName: FirestoreCollections.itineraryDataCollectionName);
      writeBatch.delete(planDataModelImplementation.documentReference);
    }
    await writeBatch.commit();

    _itineraries
        .removeWhere((itinerary) => datesToRemove.contains(itinerary.day));

    for (final date in datesToAdd) {
      var itinerary = await ItineraryModelImplementation.createInstance(
          tripId: tripId,
          day: date,
          transits: [],
          checkinLodging: null,
          checkoutLodging: null,
          fullDayLodging: null,
          planData: PlanDataModelImplementation.empty(
              tripId: tripId, id: date.itineraryDateFormat));
      _itineraries.add(
        itinerary,
      );
    }

    _itineraries.sort((a, b) => a.day.compareTo(b.day));
    _startDate = startDate;
    _endDate = endDate;
  }

  @override
  ItineraryModelEventHandler getItineraryForDay(DateTime dateTime) {
    return _itineraries
        .singleWhere((itinerary) => itinerary.day.isOnSameDayAs(dateTime));
  }

  static Future<List<ItineraryModelEventHandler>> _createItineraryList({
    required TripMetadataFacade tripMetadata,
    required ModelCollectionFacade<TransitFacade> transitCollection,
    required ModelCollectionFacade<LodgingFacade> lodgingCollection,
  }) async {
    final startDate = tripMetadata.startDate!;
    final endDate = tripMetadata.endDate!;
    final numberOfDays =
        startDate.calculateDaysInBetween(endDate, includeExtraDay: true);
    final itineraries = <ItineraryModelEventHandler>[];

    final transitsPerDay = _groupTransitsByDay(
        transitCollection.collectionItems, startDate, numberOfDays);
    final lodgingsPerDay = _groupLodgingsByDay(
        lodgingCollection.collectionItems, startDate, numberOfDays);

    for (var i = 0; i < numberOfDays; i++) {
      final day = startDate.add(Duration(days: i));
      var transits = transitsPerDay.entries
          .firstWhere((mapElement) => mapElement.key.isOnSameDayAs(day))
          .value;
      var lodgings = lodgingsPerDay.entries
              .where((mapElement) => mapElement.key.isOnSameDayAs(day))
              .firstOrNull
              ?.value ??
          [];

      final checkinLodging = lodgings
          .where((lodging) => lodging.checkinDateTime!.isOnSameDayAs(day))
          .firstOrNull;
      final checkoutLodging = lodgings
          .where((lodging) => lodging.checkoutDateTime!.isOnSameDayAs(day))
          .firstOrNull;
      final fullDayLodging = lodgings
          .where((lodging) =>
              day.isAfter(lodging.checkinDateTime!) &&
              day.isBefore(lodging.checkoutDateTime!))
          .firstOrNull;

      var itinerary = await ItineraryModelImplementation.createInstance(
        tripId: tripMetadata.id!,
        day: day,
        transits: transits,
        checkinLodging: checkinLodging,
        checkoutLodging: checkoutLodging,
        fullDayLodging: fullDayLodging,
      );
      itineraries.add(
        itinerary,
      );
    }
    return itineraries;
  }

  void _initializeListeners(
      ModelCollectionFacade<TransitFacade> transitCollection,
      ModelCollectionFacade<LodgingFacade> lodgingCollection) {
    _subscriptions
        .add(transitCollection.onDocumentAdded.listen((eventData) async {
      var transitAdded = eventData.modifiedCollectionItem;
      _addOrRemoveTransitToItinerary(transitAdded, false);
    }));
    _subscriptions
        .add(transitCollection.onDocumentDeleted.listen((eventData) async {
      var transitDeleted = eventData.modifiedCollectionItem;
      _addOrRemoveTransitToItinerary(transitDeleted, true);
    }));
    _subscriptions
        .add(transitCollection.onDocumentUpdated.listen((eventData) async {
      var transitBeforeUpdate = eventData.modifiedCollectionItem.beforeUpdate;
      var transitAfterUpdate = eventData.modifiedCollectionItem.afterUpdate;
      _addOrRemoveTransitToItinerary(transitBeforeUpdate, true);
      _addOrRemoveTransitToItinerary(transitAfterUpdate, false);
    }));
    _subscriptions
        .add(lodgingCollection.onDocumentAdded.listen((eventData) async {
      var lodgingAdded = eventData.modifiedCollectionItem;
      _addOrRemoveLodgingToItinerary(lodgingAdded, false);
    }));
    _subscriptions
        .add(lodgingCollection.onDocumentUpdated.listen((eventData) async {
      var lodgingBeforeUpdate = eventData.modifiedCollectionItem.beforeUpdate;
      var lodgingAfterUpdate = eventData.modifiedCollectionItem.afterUpdate;
      _addOrRemoveLodgingToItinerary(lodgingBeforeUpdate, true);
      _addOrRemoveLodgingToItinerary(lodgingAfterUpdate, false);
    }));
  }

  void _addOrRemoveTransitToItinerary(TransitFacade transit, bool toDelete) {
    for (final itinerary in _itineraries) {
      var isItineraryDayOnOrAfterDeparture =
          itinerary.day.isOnSameDayAs(transit.departureDateTime!) ||
              itinerary.day.isAfter(transit.departureDateTime!);
      var isItineraryDayOnOrBeforeArrival =
          itinerary.day.isOnSameDayAs(transit.arrivalDateTime!) ||
              itinerary.day.isBefore(transit.arrivalDateTime!);
      if (isItineraryDayOnOrAfterDeparture && isItineraryDayOnOrBeforeArrival) {
        if (toDelete) {
          itinerary.removeTransit(transit);
        } else {
          itinerary.addTransit(transit);
        }
      }
    }
  }

  void _addOrRemoveLodgingToItinerary(LodgingFacade lodging, bool toDelete) {
    for (final itinerary in _itineraries) {
      if (itinerary.day.isOnSameDayAs(lodging.checkinDateTime!)) {
        itinerary.checkInLodging = toDelete ? null : lodging;
      }
      if (itinerary.day.isOnSameDayAs(lodging.checkoutDateTime!)) {
        itinerary.checkoutLodging = toDelete ? null : lodging;
      }
      if (itinerary.day.isAfter(lodging.checkinDateTime!) &&
          itinerary.day.isBefore(lodging.checkoutDateTime!)) {
        itinerary.fullDayLodging = toDelete ? null : lodging;
      }
    }
  }

  static Map<DateTime, Iterable<TransitFacade>> _groupTransitsByDay(
    Iterable<TransitFacade> transits,
    DateTime startDate,
    int numberOfDays,
  ) {
    final transitsPerDay = <DateTime, List<TransitFacade>>{};
    for (var i = 0; i < numberOfDays; i++) {
      final day = startDate.add(Duration(days: i));
      transitsPerDay[day] = transits
          .where((transit) =>
              (day.isAfter(transit.departureDateTime!) ||
                  day.isOnSameDayAs(transit.departureDateTime!)) &&
              (day.isBefore(transit.arrivalDateTime!) ||
                  day.isOnSameDayAs(transit.arrivalDateTime!)))
          .toList();
    }
    return transitsPerDay;
  }

  static Map<DateTime, Iterable<LodgingFacade>> _groupLodgingsByDay(
    Iterable<LodgingFacade> lodgings,
    DateTime startDate,
    int numberOfDays,
  ) {
    final lodgingsPerDay = <DateTime, List<LodgingFacade>>{};
    for (var i = 0; i < numberOfDays; i++) {
      final day = startDate.add(Duration(days: i));
      lodgingsPerDay[day] = lodgings
          .where((lodging) =>
              (day.isAfter(lodging.checkinDateTime!) ||
                  day.isOnSameDayAs(lodging.checkinDateTime!)) &&
              (day.isBefore(lodging.checkoutDateTime!) ||
                  day.isOnSameDayAs(lodging.checkoutDateTime!)))
          .toList();
    }
    return lodgingsPerDay;
  }

  Set<DateTime> _getDateRange(DateTime startDate, DateTime endDate) {
    final dateSet = <DateTime>{};
    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      dateSet
          .add(DateTime(currentDate.year, currentDate.month, currentDate.day));
      currentDate = currentDate.add(const Duration(days: 1));
    }
    return dateSet;
  }

  ItineraryCollection._({
    required this.tripId,
    required ModelCollectionFacade<TransitFacade> transitCollection,
    required ModelCollectionFacade<LodgingFacade> lodgingCollection,
    required DateTime startDate,
    required DateTime endDate,
    required List<ItineraryModelEventHandler> itineraries,
  })  : _startDate = startDate,
        _endDate = endDate,
        _itineraries = itineraries {
    _initializeListeners(transitCollection, lodgingCollection);
  }
}
