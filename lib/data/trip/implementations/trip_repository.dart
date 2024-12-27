import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/data/app/implementations/collection_model_implementation.dart';
import 'package:wandrr/data/app/models/collection_model_facade.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/trip_metadata.dart';
import 'package:wandrr/data/trip/models/api_services/currency_converter.dart';
import 'package:wandrr/data/trip/models/api_services/flight_operations.dart';
import 'package:wandrr/data/trip/models/api_services/geo_locator.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';

import 'api_services/currency_converter.dart';
import 'api_services/flight_operations_service.dart';
import 'api_services/geo_locator.dart';
import 'trip_data.dart';

class TripRepositoryImplementation implements TripRepositoryEventHandler {
  static const _contributorsField = 'contributors';

  final AppLocalizations _appLocalizations;

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
  final FlightOperationsService flightOperationsService;

  @override
  final GeoLocatorService geoLocator;

  @override
  final CurrencyConverterService currencyConverter;

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
    var flightOperationsService = await FlightOperations.create();
    return TripRepositoryImplementation._(
        tripMetadataModelCollection,
        appLocalizations,
        currencyConverter,
        geoLocator,
        flightOperationsService);
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
        tripMetadata, currencyConverter, _appLocalizations);
  }

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
      this.flightOperationsService) {
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
