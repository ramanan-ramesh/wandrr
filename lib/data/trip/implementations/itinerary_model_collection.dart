import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary.dart';
import 'package:wandrr/data/trip/implementations/plan_data/plan_data_model_implementation.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

class ItineraryModelCollection extends ItineraryFacadeCollectionEventHandler
    implements Dispose {
  final _subscriptions = <StreamSubscription>[];
  final ModelCollectionFacade<TransitFacade> _transitModelCollection;
  final ModelCollectionFacade<LodgingFacade> _lodgingModelCollection;
  final List<ItineraryModelImplementation> _allItineraries;

  static final _dateFormat = DateFormat('ddMMyyyy');

  DateTime _startDate;
  DateTime _endDate;
  final String tripId;

  static Future<ItineraryModelCollection> createInstance(
      ModelCollectionFacade<TransitFacade> transitModelCollection,
      ModelCollectionFacade<LodgingFacade> lodgingModelCollection,
      TripMetadataFacade tripMetadataFacade) async {
    var itineraries = await _createItineraryList(
        tripMetadataFacade, transitModelCollection, lodgingModelCollection);

    return ItineraryModelCollection._(
        transitModelCollection,
        lodgingModelCollection,
        tripMetadataFacade.startDate!,
        tripMetadataFacade.endDate!,
        tripMetadataFacade.id!,
        itineraries);
  }

  static Future<List<ItineraryModelImplementation>> _createItineraryList(
      TripMetadataFacade tripMetadataFacade,
      ModelCollectionFacade<TransitFacade> transitModelCollection,
      ModelCollectionFacade<LodgingFacade> lodgingModelCollection) async {
    var startDateFromFacade = tripMetadataFacade.startDate!;
    var endDateFromFacade = tripMetadataFacade.endDate!;
    var numberOfDaysOfTrip = startDateFromFacade
        .calculateDaysInBetween(endDateFromFacade, includeExtraDay: true);
    var itineraries = <ItineraryModelImplementation>[];

    var transitsPerDay = <DateTime, List<TransitFacade>>{};
    for (var dayCounter = 0; dayCounter < numberOfDaysOfTrip; dayCounter++) {
      var currentTripDay = startDateFromFacade.add(Duration(days: dayCounter));
      transitsPerDay[currentTripDay] = [];
    }
    for (final transitItem in transitModelCollection.collectionItems) {
      var totalDaysOfTransit = transitItem.departureDateTime!
          .calculateDaysInBetween(transitItem.arrivalDateTime!,
              includeExtraDay: false);
      for (var dayCounter = 0; dayCounter <= totalDaysOfTransit; dayCounter++) {
        var currentTripDay =
            transitItem.departureDateTime!.add(Duration(days: dayCounter));
        var matchingTransitEntry = transitsPerDay.entries
            .where((element) => element.key.isOnSameDayAs(currentTripDay))
            .firstOrNull;
        if (matchingTransitEntry != null) {
          transitsPerDay[matchingTransitEntry.key]!.add(transitItem);
        }
      }
    }

    var lodgingEventsPerDay = <DateTime, List<LodgingFacade>>{};
    for (final lodgingItem in lodgingModelCollection.collectionItems) {
      var totalStayTimeInDays = lodgingItem.checkinDateTime!
          .calculateDaysInBetween(lodgingItem.checkoutDateTime!,
              includeExtraDay: false);
      for (var dayCounter = 0;
          dayCounter <= totalStayTimeInDays;
          dayCounter++) {
        var currentTripDay = DateTime(
                lodgingItem.checkinDateTime!.year,
                lodgingItem.checkinDateTime!.month,
                lodgingItem.checkinDateTime!.day)
            .add(Duration(days: dayCounter));
        var lodgingEventOnSameDay = lodgingEventsPerDay.entries
            .where((mapElement) => mapElement.key.isOnSameDayAs(currentTripDay))
            .firstOrNull;
        if (lodgingEventOnSameDay != null) {
          lodgingEventsPerDay[lodgingEventOnSameDay.key]!.add(lodgingItem);
        } else {
          lodgingEventsPerDay[currentTripDay] = [lodgingItem];
        }
      }
    }

    for (var dayCounter = 0; dayCounter < numberOfDaysOfTrip; dayCounter++) {
      var currentItineraryDateTime =
          startDateFromFacade.add(Duration(days: dayCounter));

      var transits = transitsPerDay.entries
          .firstWhere((mapElement) =>
              mapElement.key.isOnSameDayAs(currentItineraryDateTime))
          .value;
      var lodgingEventsOnSameDay = (lodgingEventsPerDay.entries
                  .where((mapElement) =>
                      mapElement.key.isOnSameDayAs(currentItineraryDateTime))
                  .firstOrNull
                  ?.value ??
              [])
          .toList();
      var checkinLodging = lodgingEventsOnSameDay
          .where((lodgingEvent) => currentItineraryDateTime
              .isOnSameDayAs(lodgingEvent.checkinDateTime!))
          .firstOrNull;
      var checkoutLodging = lodgingEventsOnSameDay
          .where((lodgingEvent) => currentItineraryDateTime
              .isOnSameDayAs(lodgingEvent.checkoutDateTime!))
          .firstOrNull;
      var fullDayLodging = lodgingEventsOnSameDay
          .where((lodgingEvent) =>
              currentItineraryDateTime.isAfter(lodgingEvent.checkinDateTime!) &&
              currentItineraryDateTime
                  .isBefore(lodgingEvent.checkoutDateTime!) &&
              !currentItineraryDateTime
                  .isOnSameDayAs(lodgingEvent.checkinDateTime!) &&
              !currentItineraryDateTime
                  .isOnSameDayAs(lodgingEvent.checkoutDateTime!))
          .firstOrNull;
      var itineraryModelImplementation =
          await ItineraryModelImplementation.createInstance(
              tripId: tripMetadataFacade.id!,
              day: currentItineraryDateTime,
              transits: transits,
              checkinLodging: checkinLodging,
              checkoutLodging: checkoutLodging,
              fullDayLodging: fullDayLodging);
      itineraries.add(itineraryModelImplementation);
    }

    return itineraries;
  }

  @override
  Future updateTripDays(DateTime startDate, DateTime endDate) async {
    // Sets for old and new date ranges
    var oldDates = _getDateRange(_startDate, _endDate);
    var newDates = _getDateRange(startDate, endDate);

    // Identify dates to be added and removed
    var datesToAdd = newDates.difference(oldDates);
    var datesToRemove = oldDates.difference(newDates);

    // Remove itineraries for dates not in the new date range
    var writeBatch = FirebaseFirestore.instance.batch();
    for (final date in datesToRemove) {
      var itineraryIndex =
          _indexWhere((itinerary) => itinerary.day.isOnSameDayAs(date));
      var itinerary = this[itineraryIndex];
      writeBatch.delete(itinerary.planDataEventHandler.documentReference);
    }

    if (datesToRemove.isNotEmpty) {
      await writeBatch.commit().then((value) {
        for (final date in datesToRemove) {
          _allItineraries
              .removeWhere((itinerary) => itinerary.day.isOnSameDayAs(date));
        }
      });
    }

    // Add new itineraries for dates in the new date range but not in the old date range
    for (final date in datesToAdd) {
      var planDataModelImplementation = PlanDataModelImplementation.empty(
          id: _dateFormat.format(date),
          tripId: tripId,
          collectionName: FirestoreCollections.itineraryDataCollectionName);
      var itinerary = ItineraryModelImplementation(
          tripId, date, planDataModelImplementation, []);
      _allItineraries.add(itinerary);
    }

    // Sort the updated list of itineraries
    _allItineraries.sort((a, b) => a.day.compareTo(b.day));

    _startDate = DateTime(startDate.year, startDate.month, startDate.day);
    _endDate = DateTime(endDate.year, endDate.month, endDate.day);
  }

  @override
  Iterator<ItineraryFacade> get iterator => _allItineraries.iterator;

  ItineraryModelImplementation operator [](int index) => _allItineraries[index];

  @override
  ItineraryModelEventHandler getItineraryForDay(DateTime dateTime) =>
      _allItineraries
          .singleWhere((itinerary) => itinerary.day.isOnSameDayAs(dateTime));

  @override
  Future dispose() async {
    _allItineraries.clear();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  void _addOrRemoveTransitToItinerary(TransitFacade transit, bool toDelete) {
    for (final itinerary in _allItineraries) {
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
    for (final itinerary in _allItineraries) {
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

  Set<DateTime> _getDateRange(DateTime startDate, DateTime endDate) {
    var dateSet = <DateTime>{};
    var newStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    var newEndDate = DateTime(endDate.year, endDate.month, endDate.day);
    for (var date = newStartDate;
        date.isBefore(newEndDate) || date.isAtSameMomentAs(newEndDate);
        date = date.add(const Duration(days: 1))) {
      dateSet.add(date);
    }
    return dateSet;
  }

  ItineraryModelCollection._(
      ModelCollectionFacade<TransitFacade> transitModelCollection,
      ModelCollectionFacade<LodgingFacade> lodgingModelCollection,
      DateTime startDate,
      DateTime endDate,
      this.tripId,
      List<ItineraryModelImplementation> allItineraries)
      : _transitModelCollection = transitModelCollection,
        _lodgingModelCollection = lodgingModelCollection,
        _allItineraries = allItineraries,
        _startDate = startDate,
        _endDate = endDate {
    _subscriptions
        .add(_transitModelCollection.onDocumentAdded.listen((eventData) async {
      var transitAdded = eventData.modifiedCollectionItem;
      _addOrRemoveTransitToItinerary(transitAdded, false);
    }));
    _subscriptions.add(
        _transitModelCollection.onDocumentDeleted.listen((eventData) async {
      var transitDeleted = eventData.modifiedCollectionItem;
      _addOrRemoveTransitToItinerary(transitDeleted, true);
    }));
    _subscriptions.add(
        _transitModelCollection.onDocumentUpdated.listen((eventData) async {
      var transitBeforeUpdate = eventData.modifiedCollectionItem.beforeUpdate;
      var transitAfterUpdate = eventData.modifiedCollectionItem.afterUpdate;
      _addOrRemoveTransitToItinerary(transitBeforeUpdate, true);
      _addOrRemoveTransitToItinerary(transitAfterUpdate, false);
    }));
    _subscriptions
        .add(_lodgingModelCollection.onDocumentAdded.listen((eventData) async {
      var lodgingAdded = eventData.modifiedCollectionItem;
      _addOrRemoveLodgingToItinerary(lodgingAdded, false);
    }));
    _subscriptions.add(
        _lodgingModelCollection.onDocumentUpdated.listen((eventData) async {
      var lodgingBeforeUpdate = eventData.modifiedCollectionItem.beforeUpdate;
      var lodgingAfterUpdate = eventData.modifiedCollectionItem.afterUpdate;
      _addOrRemoveLodgingToItinerary(lodgingBeforeUpdate, true);
      _addOrRemoveLodgingToItinerary(lodgingAfterUpdate, false);
    }));
  }

  int _indexWhere(bool Function(ItineraryFacade itinerary) predicate) {
    for (var i = 0; i < _allItineraries.length; i++) {
      if (predicate(_allItineraries[i])) {
        return i;
      }
    }
    return -1;
  }
}
