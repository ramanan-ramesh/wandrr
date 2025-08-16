import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/l10n/app_localizations.dart';

import 'api_services_repository.dart';
import 'budgeting/currency_data.dart';
import 'trip_data.dart';
import 'trip_metadata.dart';

abstract class TripRepositoryFacade {
  List<TripMetadataFacade> get tripMetadatas;

  TripDataFacade? get activeTrip;

  Iterable<CurrencyData> get supportedCurrencies;
}

abstract class TripRepositoryEventHandler extends TripRepositoryFacade
    implements Dispose {
  ModelCollectionFacade<TripMetadataFacade> get tripMetadataModelCollection;

  TripDataModelEventHandler? get activeTripEventHandler;

  Future unloadActiveTrip();

  Future loadTrip(TripMetadataFacade tripMetadata,
      ApiServicesRepository apiServicesRepository);

  void updateLocalizations(AppLocalizations appLocalizations);
}
