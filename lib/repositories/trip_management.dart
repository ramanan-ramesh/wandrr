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

  Future<bool> updateTransit({required TransitUpdator transitUpdator});

  Future<bool> updateLodging({required LodgingUpdator lodgingUpdator});

  Future<bool> updateExpense({required ExpenseUpdator expenseUpdator});

  CurrencyConverter get currencyConverter;

  FlightOperationsService get flightOperationsService;
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

  static Future<TripManagement> createForUser(PlatformUser activeUser) async {
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

  void setActiveTrip(Trip trip) {
    _activeTrip = trip;
  }

  @override
  Future<bool> updateExpense({required ExpenseUpdator expenseUpdator}) async {
    if (_activeTrip == null) {
      return false;
    }

    return await _activeTrip!.updateExpense(expenseUpdator: expenseUpdator);
  }

  @override
  Future<bool> updateLodging({required LodgingUpdator lodgingUpdator}) async {
    if (_activeTrip == null) {
      return false;
    }

    return await _activeTrip!.updateLodging(lodgingUpdator: lodgingUpdator);
  }

  @override
  Future<bool> updateTransit({required TransitUpdator transitUpdator}) async {
    if (_activeTrip == null) {
      return false;
    }

    return await _activeTrip!.updateTransit(transitUpdator: transitUpdator);
  }

  TripManagement._(
      {required List<TripMetaData> tripMetadatas,
      required GeoLocator geoLocator,
      required CurrencyConverter currencyConverter,
      required FlightOperationsService flightOperationsService})
      : _tripMetadatas = tripMetadatas,
        _geoLocator = geoLocator,
        _currencyConverter = currencyConverter,
        _flightOperationsService = flightOperationsService;

  @override
  FlightOperationsService get flightOperationsService =>
      _flightOperationsService;
  final FlightOperationsService _flightOperationsService;
}
