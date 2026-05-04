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

  late final StreamSubscription _tripMetadataUpdateSubscription;
  late final StreamSubscription _tripMetadataDeleteSubscription;

  static Future<TripRepositoryImplementation> createInstance(
      String userName) async {
    final tripsCollectionReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripMetadataCollectionName);

    final tripMetadataModelCollection = FirestoreModelCollection.createInstance(
        tripsCollectionReference,
        TripMetadataModelImplementation.fromDocumentSnapshot,
        (tripMetadataModuleFacade) =>
            TripMetadataModelImplementation.fromModelFacade(
                tripMetadataModelFacade: tripMetadataModuleFacade),
        query: tripsCollectionReference.where(_contributorsField,
            arrayContains: userName));

    final jsonString = await rootBundle.loadString(Assets.supportedCurrencies);
    final List<dynamic> jsonResponse = json.decode(jsonString);
    final currencyDataList =
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
  Future<TripDataModelEventHandler> loadTrip(TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository,
      {required bool activateTrip}) async {
    if (!_tripDataCache.containsKey(tripMetadata.id)) {
      final tripToCache = TripDataModelImplementation.createInstance(
          tripMetadata,
          apiServicesRepository,
          currentUserName,
          supportedCurrencies);
      _tripDataCache[tripMetadata.id!] = tripToCache;
    }
    if (activateTrip) {
      if (activeTrip != null &&
          activeTrip!.tripMetadata.id != tripMetadata.id) {
        await activeTrip!.dispose();
      }
      activeTrip = _tripDataCache[tripMetadata.id];
    }
    return _tripDataCache[tripMetadata.id]!;
  }

  @override
  Future<TripMetadataFacade> copyTrip(
      TripMetadataFacade tripMetadata,
      TripMetadataFacade targetTrip,
      ApiServicesRepositoryFacade apiServicesRepository) async {
    await loadTrip(tripMetadata, apiServicesRepository, activateTrip: false);
    final tripToCopy = _tripDataCache[tripMetadata.id]!;

    Future<TripMetadataFacade> createCopy() async {
      final copiedTripMetadata = await TripCopyService.copyTrip(
          sourceTripData: tripToCopy,
          targetTripMetadata: targetTrip,
          apiServicesRepository: apiServicesRepository);
      await loadTrip(copiedTripMetadata, apiServicesRepository,
          activateTrip: false);
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
    await _tripMetadataUpdateSubscription.cancel();
    await _tripMetadataDeleteSubscription.cancel();
    await tripMetadataCollection.dispose();
    for (final trip in _tripDataCache.values) {
      await trip.dispose();
    }
    _tripDataCache.clear();
    activeTrip = null;
  }

  @override
  Future deleteTrip(TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository) async {
    final tripToDelete = await loadTrip(tripMetadata, apiServicesRepository,
        activateTrip: false);

    // Ensure all sub-collections are loaded before building the delete batch,
    // so no data is silently left behind.
    if (!tripToDelete.isFullyLoadedValue) {
      await tripToDelete.isFullyLoaded.firstWhere((isLoaded) => isLoaded);
    }

    final batch = FirebaseFirestore.instance.batch();
    final tripMetadataToDelete = tripMetadataCollection.items
        .firstWhere((item) => item.id == tripMetadata.id);
    batch.delete(tripMetadataCollection
        .collectionDocumentCreator(tripMetadataToDelete)
        .documentReference);
    for (final itinerary in tripToDelete.itineraryCollection) {
      final itineraryPlanDataModelImplementation =
          ItineraryPlanDataModelImplementation(
              tripId: tripMetadata.id!,
              day: itinerary.day,
              sights: itinerary.planData.sights,
              notes: itinerary.planData.notes,
              checkLists: itinerary.planData.checkLists);
      batch.delete(itineraryPlanDataModelImplementation.documentReference);
    }
    for (final transit in tripToDelete.transitCollection.items) {
      final transitModelImplementation =
          TransitImplementation.fromModelFacade(transitModelFacade: transit);
      batch.delete(transitModelImplementation.documentReference);
    }
    for (final lodging in tripToDelete.lodgingCollection.items) {
      final lodgingModelImplementation =
          LodgingModelImplementation.fromModelFacade(
              lodgingModelFacade: lodging);
      batch.delete(lodgingModelImplementation.documentReference);
    }
    for (final expense in tripToDelete.expenseCollection.items) {
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

  TripRepositoryImplementation._(
    this.tripMetadataCollection,
    this.currentUserName,
    this.supportedCurrencies,
  ) {
    _tripMetadataUpdateSubscription =
        tripMetadataCollection.onDocumentUpdated.listen((eventData) async {
      if (activeTrip?.tripMetadata.id !=
          eventData.collectionItemChange.afterUpdate.id) {
        return;
      }
      await activeTrip!
          .updateTripMetadata(eventData.collectionItemChange.afterUpdate);
    });
    _tripMetadataDeleteSubscription =
        tripMetadataCollection.onDocumentDeleted.listen((eventData) async {
      final tripId = eventData.collectionItemChange.id;
      if (tripId == activeTrip?.tripMetadata.id) {
        await unloadActiveTrip();
      }
    });
  }
}
