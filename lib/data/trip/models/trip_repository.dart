import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/l10n/app_localizations.dart';

import 'api_services_repository.dart';
import 'budgeting/currency_data.dart';
import 'trip_data.dart';
import 'trip_metadata.dart';

abstract class TripRepositoryFacade {
  ModelCollectionFacade<TripMetadataFacade> get tripMetadataCollection;

  TripDataFacade? get activeTrip;

  Iterable<CurrencyData> get supportedCurrencies;
}

abstract class TripRepositoryEventHandler extends TripRepositoryFacade
    implements Dispose {
  ModelCollectionModifier<TripMetadataFacade> get tripMetadataCollection;

  TripDataModelEventHandler? get activeTrip;

  Future loadTrip(TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository);

  Future unloadActiveTrip();

  void updateLocalizations(AppLocalizations appLocalizations);
}
