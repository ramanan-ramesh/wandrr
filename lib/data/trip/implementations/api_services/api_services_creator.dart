import 'package:wandrr/data/trip/implementations/api_services/geo_locator.dart';
import 'package:wandrr/data/trip/models/api_services/api_service.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

import 'airlines_data.dart';
import 'airports_data.dart';
import 'currency_converter.dart';

class ApiServicesCreator {
  static ApiService<LocationFacade> createGeoLocator() {
    return GeoLocator();
  }

  static ApiService<LocationFacade> createAirportsDataService() {
    return AirportsDataService();
  }

  static ApiService<(String airlineName, String airlineCode)>
      createAirlinesDataService() {
    return AirlinesDataService();
  }

  static CurrencyConverter createCurrencyConverterService() {
    return CurrencyConverter.create();
  }
}
