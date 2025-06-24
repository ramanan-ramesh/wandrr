import 'package:wandrr/data/trip/models/api_services/api_service.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/l10n/app_localizations.dart';

import '../../app/models/collection_model_facade.dart';
import '../../app/models/leaf_repository_item.dart';
import 'api_services/currency_converter.dart';
import 'currency_data.dart';
import 'trip_data.dart';
import 'trip_metadata.dart';

abstract class TripRepositoryFacade {
  List<TripMetadataFacade> get tripMetadatas;

  TripDataFacade? get activeTrip;

  CurrencyConverterService get currencyConverter;

  ApiService<(String airlineName, String airlineCode)> get airlinesDataService;

  ApiService<LocationFacade> get airportsDataService;

  ApiService<LocationFacade> get geoLocator;

  Iterable<CurrencyData> get supportedCurrencies;
}

abstract class TripRepositoryEventHandler extends TripRepositoryFacade
    implements Dispose {
  CollectionModelFacade<TripMetadataFacade> get tripMetadataModelCollection;

  TripDataModelEventHandler? get activeTripEventHandler;

  Future loadAndActivateTrip(TripMetadataFacade? tripMetadata);

  void updateLocalizations(AppLocalizations appLocalizations);
}
