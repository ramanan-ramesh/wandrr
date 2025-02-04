import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app/models/collection_model_facade.dart';
import '../../app/models/leaf_repository_item.dart';
import 'api_services/currency_converter.dart';
import 'api_services/flight_operations.dart';
import 'api_services/geo_locator.dart';
import 'trip_data.dart';
import 'trip_metadata.dart';

abstract class TripRepositoryFacade {
  List<TripMetadataFacade> get tripMetadatas;

  TripDataFacade? get activeTrip;

  CurrencyConverterService get currencyConverter;

  FlightOperationsService get flightOperationsService;

  GeoLocatorService get geoLocator;
}

abstract class TripRepositoryEventHandler extends TripRepositoryFacade
    implements Dispose {
  CollectionModelFacade<TripMetadataFacade> get tripMetadataModelCollection;

  TripDataModelEventHandler? get activeTripEventHandler;

  Future loadAndActivateTrip(TripMetadataFacade? tripMetadata);

  void updateLocalizations(AppLocalizations appLocalizations);
}
