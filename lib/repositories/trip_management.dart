import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/contracts/api_service.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/location.dart';
import 'package:wandrr/contracts/platform_user.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/currencies.dart';
import 'package:wandrr/repositories/api_services/flight_operations_service.dart';

import 'api_services/currency_converter.dart';
import 'api_services/geo_locator.dart';

abstract class TripManagementFacade {
  UnmodifiableListView<TripMetaDataFacade> get tripMetadatas;

  TripFacade? get activeTrip;

  MultiOptionsAPIService<Location> get geoLocator;
}

abstract class TripManagementModifier {
  Future<Trip?> createTrip({required TripMetadataUpdator tripMetadataUpdator});

  Future<void> deleteTrip({required TripMetadataUpdator tripMetadataUpdator});

  CurrencyConverter get currencyConverter;

  FlightOperations get flightOperationsService;
}

class TripManagement implements TripManagementFacade, TripManagementModifier {
  static const _contributorsField = 'contributors';

  @override
  CurrencyConverter get currencyConverter => _currencyConverter;
  final CurrencyConverter _currencyConverter;

  @override
  GeoLocator get geoLocator => _geoLocator;
  final GeoLocator _geoLocator;

  @override
  TripFacade? get activeTrip => _activeTrip;
  Trip? _activeTrip;

  final PlatformUser _activeUser;

  @override
  UnmodifiableListView<TripMetaDataFacade> get tripMetadatas =>
      UnmodifiableListView<TripMetaDataFacade>(_tripMetadatas);
  final List<TripMetaData> _tripMetadatas;

  static TripManagement? _activeTripManagement;

  @override
  Future<Trip?> createTrip(
      {required TripMetadataUpdator tripMetadataUpdator}) async {
    var tripMetadata = await TripMetaData.createFromUserInput(
        tripMetadataUpdator: tripMetadataUpdator);
    if (tripMetadata != null) {
      _tripMetadatas.add(tripMetadata);
      return await Trip.createFromTripMetadata(
          tripMetaData: tripMetadata,
          isNewlyCreatedTrip: true,
          currencyConverter: _currencyConverter);
    }
    return null;
  }

  static Future<TripManagement> createInstance(PlatformUser activeUser) async {
    if (_activeTripManagement != null) {
      return _activeTripManagement!;
    }

    var geoLocator = await GeoLocator.create();
    var currencyConverter = CurrencyConverter.create();
    var flightOperationsService = await FlightOperationsService.create();

    var collectionReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsMetadataCollection);
    var queryTripsForUser = collectionReference.where(_contributorsField,
        arrayContains: activeUser.userName);

    var queryResult = await queryTripsForUser.get();
    List<TripMetaData> tripMetadatas = [];
    if (queryResult.docs.isNotEmpty) {
      for (var snapshot in queryResult.docs) {
        var tripMetadata = TripMetaData.fromDocumentSnapshot(snapshot);
        tripMetadatas.add(tripMetadata);
      }
    }

    _activeTripManagement = TripManagement._(
        tripMetadatas: tripMetadatas,
        geoLocator: geoLocator,
        currencyConverter: currencyConverter,
        activeUser: activeUser,
        flightOperationsService: flightOperationsService);

    currencies.sort((firstCurrency, secondCurrency) =>
        (firstCurrency['name'] as String)
            .compareTo((secondCurrency['name'] as String)));
    return _activeTripManagement!;
  }

  Future<Trip> retrieveTrip(
      {required TripMetaData tripMetaData,
      required bool isNewlyCreatedTrip}) async {
    return await Trip.createFromTripMetadata(
        tripMetaData: tripMetaData,
        isNewlyCreatedTrip: isNewlyCreatedTrip,
        currencyConverter: _currencyConverter);
  }

  void setActiveTrip(Trip? trip) {
    _activeTrip = trip;
    //TODO: Ideally start listening to document changes on transit/lodgings/tripMetadata etc.. here?
  }

  TripManagement._(
      {required List<TripMetaData> tripMetadatas,
      required GeoLocator geoLocator,
      required PlatformUser activeUser,
      required CurrencyConverter currencyConverter,
      required FlightOperations flightOperationsService})
      : _tripMetadatas = tripMetadatas,
        _geoLocator = geoLocator,
        _activeUser = activeUser,
        _currencyConverter = currencyConverter,
        _flightOperationsService = flightOperationsService;

  @override
  FlightOperations get flightOperationsService => _flightOperationsService;
  final FlightOperations _flightOperationsService;

  @override
  Future<void> deleteTrip(
      {required TripMetadataUpdator tripMetadataUpdator}) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsMetadataCollection)
        .doc(tripMetadataUpdator.id)
        .delete();
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(tripMetadataUpdator.id)
        .delete();
    _tripMetadatas
        .removeWhere((element) => element.id == tripMetadataUpdator.id);
  }
}
