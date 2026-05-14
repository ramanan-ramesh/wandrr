import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/data/store/implementations/firestore_model_collection.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary/itinerary_plan_data_implementation.dart';
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
  TripDataModelEventHandler loadTrip(TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository,
      {required bool activateTrip}) {
    if (!_tripDataCache.containsKey(tripMetadata.id)) {
      _tripDataCache[tripMetadata.id!] =
          TripDataModelImplementation.createInstance(
              tripMetadata, apiServicesRepository);
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
    loadTrip(tripMetadata, apiServicesRepository, activateTrip: false);
    final tripToCopy = _tripDataCache[tripMetadata.id]!;

    // Wait for trip data to be fully loaded before copying.
    if (!tripToCopy.isFullyLoadedValue) {
      await tripToCopy.isFullyLoaded.firstWhere((isLoaded) => isLoaded);
    }

    final copiedTripMetadata = await TripCopyService.copyTrip(
        sourceTripData: tripToCopy,
        targetTripMetadata: targetTrip,
        apiServicesRepository: apiServicesRepository);
    loadTrip(copiedTripMetadata, apiServicesRepository, activateTrip: false);
    return copiedTripMetadata;
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
    final tripToDelete =
        loadTrip(tripMetadata, apiServicesRepository, activateTrip: false);

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
          ItineraryPlanDataModelImplementation.fromModelFacade(
              itinerary.planData);
      batch.delete(itineraryPlanDataModelImplementation.documentReference);
    }
    for (final tripEntity in [
      tripToDelete.transitCollection,
      tripToDelete.lodgingCollection,
      tripToDelete.expenseCollection
    ]) {
      for (final tripEntityItem in tripEntity.items) {
        batch.delete(tripEntity
            .collectionDocumentCreator(tripEntityItem)
            .documentReference);
      }
    }
    batch.delete(FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripMetadata.id));
    await tripToDelete.dispose();
    await batch.commit();
    _tripDataCache.remove(tripMetadata.id);
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
