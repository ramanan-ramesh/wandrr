import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/data/app/implementations/collection_model_implementation.dart';
import 'package:wandrr/data/app/models/collection_model_facade.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/trip_metadata.dart';
import 'package:wandrr/data/trip/models/api_services/airports_data.dart';
import 'package:wandrr/data/trip/models/api_services/currency_converter.dart';
import 'package:wandrr/data/trip/models/api_services/flight_operations.dart';
import 'package:wandrr/data/trip/models/api_services/geo_locator.dart';
import 'package:wandrr/data/trip/models/currency_data.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/app_localizations.dart';

import 'api_services/airlines_data.dart';
import 'api_services/airports_data.dart';
import 'api_services/currency_converter.dart';
import 'api_services/geo_locator.dart';
import 'trip_data.dart';

class TripRepositoryImplementation implements TripRepositoryEventHandler {
  static const _contributorsField = 'contributors';
  static const _pathToSupportedCurrencies = 'assets/supported_currencies.json';

  AppLocalizations _appLocalizations;

  late StreamSubscription _tripMetadataUpdatedEventSubscription;
  late StreamSubscription _tripMetadataDeletedEventSubscription;

  @override
  List<TripMetadataFacade> get tripMetadatas =>
      List.from(_tripMetadataModelCollection.collectionItems
          .cast<TripMetadataFacade>()
          .map<TripMetadataFacade>((facade) => facade.clone()));

  @override
  CollectionModelFacade<TripMetadataFacade> get tripMetadataModelCollection =>
      _tripMetadataModelCollection;
  final CollectionModelFacade<TripMetadataFacade> _tripMetadataModelCollection;

  @override
  TripDataFacade? get activeTrip => _activeTrip;
  TripDataModelImplementation? _activeTrip;

  @override
  TripDataModelEventHandler? get activeTripEventHandler => _activeTrip;

  @override
  final AirlinesDataServiceFacade airlinesDataService;

  @override
  final AirportsDataServiceFacade airportsDataService;

  @override
  final GeoLocatorService geoLocator;

  @override
  final CurrencyConverterService currencyConverter;

  final String currentUserName;

  static Future<TripRepositoryImplementation> createInstanceAsync(
      {required String userName,
      required AppLocalizations appLocalizations}) async {
    var tripsCollectionReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripMetadataCollectionName);

    var tripMetadataModelCollection =
        await CollectionModelImplementation.createInstance(
            tripsCollectionReference,
            (snapshot) =>
                TripMetadataModelImplementation.fromDocumentSnapshot(snapshot),
            (tripMetadataModuleFacade) =>
                TripMetadataModelImplementation.fromModelFacade(
                    tripMetadataModelFacade: tripMetadataModuleFacade),
            query: tripsCollectionReference.where(_contributorsField,
                arrayContains: userName));
    var geoLocator = await GeoLocator.create();
    var currencyConverter = CurrencyConverter.create();
    var airlinesDataService = await AirlinesDataService.create();
    var airportsDataService = await AirportsDataService.create();

    final String jsonString =
        await rootBundle.loadString(_pathToSupportedCurrencies);
    final List<dynamic> jsonResponse = json.decode(jsonString);
    var currencyDataList =
        jsonResponse.map((json) => CurrencyData.fromJson(json)).toList();

    return TripRepositoryImplementation._(
      tripMetadataModelCollection,
      appLocalizations,
      currencyConverter,
      geoLocator,
      airlinesDataService,
      airportsDataService,
      userName,
      currencyDataList,
    );
  }

  @override
  Future loadAndActivateTrip(TripMetadataFacade? tripMetadata) async {
    if (tripMetadata == null) {
      await _activeTrip?.dispose();
      _activeTrip = null;
      return;
    }

    await _activeTrip?.dispose();
    _activeTrip = await TripDataModelImplementation.createExistingInstanceAsync(
        tripMetadata, currencyConverter, _appLocalizations, currentUserName);
  }

  @override
  void updateLocalizations(AppLocalizations appLocalizations) {
    _appLocalizations = appLocalizations;
  }

  @override
  final Iterable<CurrencyData> supportedCurrencies;

  @override
  Future dispose() async {
    await _tripMetadataUpdatedEventSubscription.cancel();
    await _tripMetadataDeletedEventSubscription.cancel();
  }

  TripRepositoryImplementation._(
    this._tripMetadataModelCollection,
    this._appLocalizations,
    this.currencyConverter,
    this.geoLocator,
    this.airlinesDataService,
    this.airportsDataService,
    this.currentUserName,
    this.supportedCurrencies,
  ) {
    _tripMetadataUpdatedEventSubscription =
        tripMetadataModelCollection.onDocumentUpdated.listen((eventData) async {
      if (_activeTrip == null) {
        return;
      }
      await _activeTrip!
          .updateTripMetadata(eventData.modifiedCollectionItem.afterUpdate);
    });
    _tripMetadataDeletedEventSubscription = _tripMetadataModelCollection
        .onDocumentDeleted
        .listen((eventData) async {
      var deletedTripId = eventData.modifiedCollectionItem.id;
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.tripCollectionName)
          .doc(deletedTripId)
          .delete();
    });
  }
}
