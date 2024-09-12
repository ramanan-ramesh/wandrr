import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/database_connectors/model_collection_facade.dart';
import 'package:wandrr/contracts/database_connectors/repository_pattern.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/itinerary.dart';
import 'package:wandrr/contracts/trip_entity_facades/lodging.dart';
import 'package:wandrr/contracts/trip_entity_facades/transit.dart';
import 'package:wandrr/contracts/trip_entity_facades/trip_metadata.dart';
import 'package:wandrr/repositories/trip_management/implementations/itinerary.dart';
import 'package:wandrr/repositories/trip_management/implementations/plan_data_model_implementation.dart';

class ItineraryModelCollection extends ItineraryFacadeCollectionEventHandler
    implements Dispose {
  final _subscriptions = <StreamSubscription>[];
  final ModelCollectionFacade<TransitFacade> _transitModelCollection;
  final ModelCollectionFacade<LodgingFacade> _lodgingModelCollection;
  final List<ItineraryModelImplementation> _allItineraries;

  DateTime _startDate;
  DateTime _endDate;
  final String tripId;

  ItineraryModelCollection(
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
      var transitAdded = eventData.modifiedCollectionItem.clone();
      _addOrRemoveTransitToItinerary(transitAdded, false);
    }));
    _subscriptions.add(
        _transitModelCollection.onDocumentDeleted.listen((eventData) async {
      var transitDeleted = eventData.modifiedCollectionItem.clone();
      _addOrRemoveTransitToItinerary(transitDeleted, true);
    }));
    _subscriptions.add(
        _transitModelCollection.onDocumentUpdated.listen((eventData) async {
      var transitBeforeUpdate =
          eventData.modifiedCollectionItem.beforeUpdate.clone();
      var transitAfterUpdate =
          eventData.modifiedCollectionItem.afterUpdate.clone();
      _addOrRemoveTransitToItinerary(transitBeforeUpdate, true);
      _addOrRemoveTransitToItinerary(transitAfterUpdate, false);
    }));
    _subscriptions
        .add(_lodgingModelCollection.onDocumentAdded.listen((eventData) async {
      var lodgingAdded = eventData.modifiedCollectionItem.clone();
      _addOrRemoveLodgingToItinerary(lodgingAdded, false);
    }));
    _subscriptions.add(
        _lodgingModelCollection.onDocumentUpdated.listen((eventData) async {
      var lodgingBeforeUpdate =
          eventData.modifiedCollectionItem.beforeUpdate.clone();
      var lodgingAfterUpdate =
          eventData.modifiedCollectionItem.afterUpdate.clone();
      _addOrRemoveLodgingToItinerary(lodgingBeforeUpdate, true);
      _addOrRemoveLodgingToItinerary(lodgingAfterUpdate, false);
    }));
  }

  static Future<ItineraryModelCollection> createItineraryModelCollection(
      ModelCollectionFacade<TransitFacade> transitModelCollection,
      ModelCollectionFacade<LodgingFacade> lodgingModelCollection,
      TripMetadataFacade tripMetadataFacade) async {
    var itineraries = await _createItineraryList(
        tripMetadataFacade, transitModelCollection, lodgingModelCollection);

    return ItineraryModelCollection(
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
    for (var transitItem in transitModelCollection.collectionItems) {
      var transit = transitItem.facade;
      var totalDaysOfTransit = transit.departureDateTime!
          .calculateDaysInBetween(transit.arrivalDateTime!,
              includeExtraDay: false);
      if (totalDaysOfTransit == 0) {
        var matchingTransitEntry = transitsPerDay.entries.firstWhere(
            (element) => element.key.isOnSameDayAs(transit.arrivalDateTime!));
        transitsPerDay[matchingTransitEntry.key]!.add(transit);
      } else {
        for (var dayCounter = 0;
            dayCounter < numberOfDaysOfTrip;
            dayCounter++) {
          var currentTripDay =
              transit.departureDateTime!.add(Duration(days: dayCounter));
          var matchingTransitEntry = transitsPerDay.entries.firstWhere(
              (element) => element.key.isOnSameDayAs(currentTripDay));
          transitsPerDay[matchingTransitEntry.key]!.add(transit);
        }
      }
    }

    var lodgingsPerDay = <DateTime, LodgingFacade>{};
    for (var lodgingItem in lodgingModelCollection.collectionItems) {
      var lodging = lodgingItem.facade;
      var totalStayTimeInDays = lodging.checkinDateTime!.calculateDaysInBetween(
          lodging.checkoutDateTime!,
          includeExtraDay: false);
      if (totalStayTimeInDays == 0) {
        lodgingsPerDay[lodging.checkinDateTime!] = lodging;
      } else {
        for (var dayCounter = 0;
            dayCounter <= totalStayTimeInDays;
            dayCounter++) {
          var currentTripDay =
              lodging.checkinDateTime!.add(Duration(days: dayCounter));
          lodgingsPerDay[currentTripDay] = lodging;
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
      var lodging = lodgingsPerDay.entries
          .where((mapElement) =>
              mapElement.key.isOnSameDayAs(currentItineraryDateTime))
          .firstOrNull
          ?.value;
      var itineraryModelImplementation =
          await ItineraryModelImplementation.createExistingInstanceAsync(
              tripId: tripMetadataFacade.id!,
              day: currentItineraryDateTime,
              transits: transits,
              lodging: lodging);
      itineraries.add(itineraryModelImplementation);
    }

    return itineraries;
  }

  @override
  Future updateTripDays(DateTime startDate, DateTime endDate) async {
    // Sets for old and new date ranges
    Set<DateTime> oldDates = _getDateRange(_startDate, _endDate);
    Set<DateTime> newDates = _getDateRange(startDate, endDate);

    // Identify dates to be added and removed
    Set<DateTime> datesToAdd = newDates.difference(oldDates);
    Set<DateTime> datesToRemove = oldDates.difference(newDates);

    // Remove itineraries for dates not in the new date range
    var writeBatch = FirebaseFirestore.instance.batch();
    for (var date in datesToRemove) {
      var itineraryIndex =
          indexWhere((itinerary) => itinerary.day.isOnSameDayAs(date));
      var itinerary = this[itineraryIndex];
      writeBatch.delete(itinerary.planDataEventHandler.documentReference);
    }

    if (datesToRemove.isNotEmpty) {
      await writeBatch.commit().then((value) {
        for (var date in datesToRemove) {
          var itineraryIndex = _allItineraries
              .indexWhere((itinerary) => itinerary.day.isOnSameDayAs(date));
          _allItineraries.removeAt(itineraryIndex);
        }
      });
    }

    // Add new itineraries for dates in the new date range but not in the old date range
    for (var date in datesToAdd) {
      var planDataModelImplementation = PlanDataModelImplementation.empty(
          id: _dateFormat.format(date),
          tripId: tripId,
          collectionName: FirestoreCollections.itineraryDataCollection);
      var itinerary = ItineraryModelImplementation(
          tripId, date, planDataModelImplementation, [], null);
      _allItineraries.add(itinerary);
    }

    // Sort the updated list of itineraries
    _allItineraries.sort((a, b) => a.day.compareTo(b.day));
  }

  @override
  int get length => _allItineraries.length;

  @override
  set length(int newLength) {}

  @override
  ItineraryModelImplementation operator [](int index) {
    return _allItineraries[index];
  }

  @override
  ItineraryModelEventHandler getItineraryForDay(DateTime dateTime) {
    return _allItineraries
        .singleWhere((itinerary) => itinerary.day.isOnSameDayAs(dateTime));
  }

  @override
  void operator []=(int index, ItineraryFacade value) {}

  @override
  Future dispose() async {
    _allItineraries.clear();
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  void _addOrRemoveTransitToItinerary(TransitFacade transit, bool toDelete) {
    var departureItinerary = getItineraryForDay(transit.departureDateTime!);
    if (toDelete) {
      departureItinerary.removeTransit(transit);
    } else {
      departureItinerary.addTransit(transit);
    }
    var arrivalItinerary = getItineraryForDay(transit.arrivalDateTime!);
    if (toDelete) {
      arrivalItinerary.removeTransit(transit);
    } else {
      arrivalItinerary.addTransit(transit);
    }
  }

  void _addOrRemoveLodgingToItinerary(LodgingFacade lodging, bool toDelete) {
    var checkInDayItinerary = getItineraryForDay(lodging.checkinDateTime!);
    if (toDelete) {
      checkInDayItinerary.removeLodging(lodging);
    } else {
      checkInDayItinerary.addLodging(lodging);
    }
    var checkOutDayItinerary = getItineraryForDay(lodging.checkoutDateTime!);
    if (toDelete) {
      checkOutDayItinerary.removeLodging(lodging);
    } else {
      checkOutDayItinerary.addLodging(lodging);
    }
  }

  static final _dateFormat = DateFormat('ddMMyyyy');

  Set<DateTime> _getDateRange(DateTime startDate, DateTime endDate) {
    Set<DateTime> dateSet = {};
    var newStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    var newEndDate = DateTime(endDate.year, endDate.month, endDate.day);
    for (DateTime date = newStartDate;
        date.isBefore(newEndDate) || date.isAtSameMomentAs(newEndDate);
        date = date.add(Duration(days: 1))) {
      dateSet.add(date);
    }
    return dateSet;
  }
}
