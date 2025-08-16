import 'dart:async';

import 'package:wandrr/data/trip/implementations/api_services/currency_converter.dart';
import 'package:wandrr/data/trip/implementations/api_services/geo_locator.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

import 'airlines_data.dart';
import 'airports_data.dart';

class ApiServicesRepositoryImpl implements ApiServicesRepository {
  @override
  final ApiService<String, Iterable<(String, String)>> airlinesDataService;

  @override
  final ApiService<String, Iterable<LocationFacade>> airportsDataService;

  @override
  final ApiService<(Money, String), double?> currencyConverter;

  @override
  final ApiService<String, Iterable<LocationFacade>> geoLocator;

  static Future<ApiServicesRepository> createInstance() async {
    var geoLocator = GeoLocator();
    await geoLocator.initialize();
    var currencyConverter = CurrencyConverter();
    await currencyConverter.initialize();
    var airlinesDataService = AirlinesDataService();
    await airlinesDataService.initialize();
    var airportsDataService = AirportsDataService();
    await airportsDataService.initialize();
    return ApiServicesRepositoryImpl._(
      airlinesDataService: airlinesDataService,
      airportsDataService: airportsDataService,
      currencyConverter: currencyConverter,
      geoLocator: geoLocator,
    );
  }

  ApiServicesRepositoryImpl._({
    required this.airlinesDataService,
    required this.airportsDataService,
    required this.currencyConverter,
    required this.geoLocator,
  });

  @override
  FutureOr<void> dispose() async {
    await airlinesDataService.dispose();
    await airportsDataService.dispose();
    await currencyConverter.dispose();
    await geoLocator.dispose();
  }
}
