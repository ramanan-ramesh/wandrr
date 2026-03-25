import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/data/store/implementations/firestore_model_collection.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/budgeting/expense.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary/itinerary_plan_data_implementation.dart';
import 'package:wandrr/data/trip/implementations/lodging.dart';
import 'package:wandrr/data/trip/implementations/transit.dart';
import 'package:wandrr/data/trip/implementations/trip_metadata.dart';
import 'package:wandrr/data/trip/implementations/trip_visit_tracker.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';

import 'services/trip_copy_service.dart';
import 'trip_data.dart';

class TripRepositoryImplementation implements TripRepositoryEventHandler {
  static const _contributorsField = 'contributors';

  late final StreamSubscription _tripMetadataUpdatedEventSubscription;
  late final StreamSubscription _tripMetadataDeletedEventSubscription;

  static Future<TripRepositoryImplementation> createInstance(
      {required String userName}) async {
    var tripsCollectionReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripMetadataCollectionName);

    var tripMetadataModelCollection = FirestoreModelCollection.createInstance(
        tripsCollectionReference,
        TripMetadataModelImplementation.fromDocumentSnapshot,
        (tripMetadataModuleFacade) =>
            TripMetadataModelImplementation.fromModelFacade(
                tripMetadataModelFacade: tripMetadataModuleFacade),
        query: tripsCollectionReference.where(_contributorsField,
            arrayContains: userName));

    final jsonString = await rootBundle.loadString(Assets.supportedCurrencies);
    final List<dynamic> jsonResponse = json.decode(jsonString);
    var currencyDataList =
        jsonResponse.map((json) => CurrencyData.fromJson(json)).toList();

    return TripRepositoryImplementation._(
      tripMetadataModelCollection,
      userName,
      currencyDataList,
    );
  }

  @override
  final ModelCollectionModifier<TripMetadataFacade> tripMetadataCollection;

  @override
  TripDataModelImplementation? activeTrip;

  final Map<String, TripDataModelImplementation> _tripDataCache = {};

  final String currentUserName;

  @override
  Future unloadActiveTrip() async {
    activeTrip = null;
  }

  @override
  TripDataModelEventHandler loadTrip(TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository, bool activateTrip) {
    if (!_tripDataCache.containsKey(tripMetadata.id)) {
      final tripToCache = TripDataModelImplementation.createInstance(
          tripMetadata,
          apiServicesRepository,
          currentUserName,
          supportedCurrencies);
      _tripDataCache[tripMetadata.id!] = tripToCache;
    }
    if (activateTrip) {
      activeTrip = _tripDataCache[tripMetadata.id];
    }
    return _tripDataCache[tripMetadata.id]!;
  }

  @override
  Future<TripMetadataFacade> copyTrip(
      TripMetadataFacade tripMetadata,
      TripMetadataFacade targetTrip,
      ApiServicesRepositoryFacade apiServicesRepository) async {
    loadTrip(tripMetadata, apiServicesRepository, false);
    final tripToCopy = _tripDataCache[tripMetadata.id]!;

    Future<TripMetadataFacade> createCopy() async {
      final copiedTripMetadata = await TripCopyService.copyTrip(
          sourceTripData: tripToCopy,
          targetTripMetadata: targetTrip,
          apiServicesRepository: apiServicesRepository);
      loadTrip(copiedTripMetadata, apiServicesRepository, false);
      return copiedTripMetadata;
    }

    if (!tripToCopy.isFullyLoadedValue) {
      // Wait for trip data to be fully loaded before copying
      await tripToCopy.isFullyLoaded.listen((isLoaded) async {
        if (isLoaded) {
          await createCopy();
        }
      }).asFuture();
    }

    return await createCopy();
  }

  @override
  final Iterable<CurrencyData> supportedCurrencies;

  @override
  Future dispose() async {
    await _tripMetadataUpdatedEventSubscription.cancel();
    await _tripMetadataDeletedEventSubscription.cancel();
    await tripMetadataCollection.dispose();
    for (var trip in _tripDataCache.values) {
      await trip.dispose();
    }
    _tripDataCache.clear();
    activeTrip = null;
  }

  TripRepositoryImplementation._(
    this.tripMetadataCollection,
    this.currentUserName,
    this.supportedCurrencies,
  ) {
    _tripMetadataUpdatedEventSubscription =
        tripMetadataCollection.onDocumentUpdated.listen((eventData) async {
      if (activeTrip?.tripMetadata.id !=
          eventData.modifiedCollectionItem.afterUpdate.id) {
        return;
      }
      await activeTrip!
          .updateTripMetadata(eventData.modifiedCollectionItem.afterUpdate);
    });
    _tripMetadataDeletedEventSubscription =
        tripMetadataCollection.onDocumentDeleted.listen((eventData) async {
      var tripId = eventData.modifiedCollectionItem.id;
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.tripCollectionName)
          .doc(tripId)
          .delete();
      if (tripId == activeTrip?.tripMetadata.id) {
        await unloadActiveTrip();
      }
    });
  }

  @override
  Future deleteTrip(TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository) async {
    TripDataModelImplementation tripToDelete;
    if (!_tripDataCache.containsKey(tripMetadata.id)) {
      tripToDelete = TripDataModelImplementation.createInstance(tripMetadata,
          apiServicesRepository, currentUserName, supportedCurrencies);
    } else {
      tripToDelete = _tripDataCache[tripMetadata.id]!;
    }
    final batch = FirebaseFirestore.instance.batch();
    var tripMetadataToDelete = tripMetadataCollection.collectionItems
        .firstWhere((item) => item.id == tripMetadata.id);
    batch.delete(tripMetadataCollection
        .repositoryItemCreator(tripMetadataToDelete)
        .documentReference);
    for (var itinerary in tripToDelete.itineraryCollection) {
      final itineraryPlanDataModelImplementation =
          ItineraryPlanDataModelImplementation(
              tripId: tripMetadata.id!,
              day: itinerary.day,
              sights: itinerary.planData.sights,
              notes: itinerary.planData.notes,
              checkLists: itinerary.planData.checkLists);
      batch.delete(itineraryPlanDataModelImplementation.documentReference);
    }
    for (var transit in tripToDelete.transitCollection.collectionItems) {
      final transitModelImplementation =
          TransitImplementation.fromModelFacade(transitModelFacade: transit);
      batch.delete(transitModelImplementation.documentReference);
    }
    for (var lodging in tripToDelete.lodgingCollection.collectionItems) {
      final lodgingModelImplementation =
          LodgingModelImplementation.fromModelFacade(
              lodgingModelFacade: lodging);
      batch.delete(lodgingModelImplementation.documentReference);
    }
    for (var expense in tripToDelete.expenseCollection.collectionItems) {
      final expenseModelImplementation =
          StandaloneExpenseModelImplementation.fromModelFacade(
              expenseModelFacade: expense);
      batch.delete(expenseModelImplementation.documentReference);
    }
    batch.delete(FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripMetadata.id));
    await tripToDelete.dispose();
    await batch.commit();
    if (_tripDataCache.containsKey(tripMetadata.id)) {
      _tripDataCache.remove(tripMetadata.id);
    }
    await TripVisitTracker.deleteVisitCount(tripMetadata.id!);
  }
}
