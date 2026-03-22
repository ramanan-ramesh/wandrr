import 'package:wandrr/data/app/models/dispose.dart';

import 'api_service.dart';
import 'budgeting/money.dart';
import 'location/location.dart';

abstract class ApiServicesRepositoryFacade {
  ApiService<(Money moneyToConvert, String currencyToConvertTo), double?>
      get currencyConverter;

  ApiService<String, Iterable<(String airlineName, String airlineCode)>>
      get airlinesDataService;

  ApiService<String, Iterable<LocationFacade>> get airportsDataService;

  ApiService<String, Iterable<LocationFacade>> get geoLocator;
}

abstract class ApiServicesRepositoryModifier extends ApiServicesRepositoryFacade
    implements Dispose {}
