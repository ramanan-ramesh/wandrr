import 'package:wandrr/l10n/app_localizations.dart';

import '../../store/models/leaf_repository_item.dart';
import '../../store/models/model_collection.dart';
import 'api_services_repository.dart';
import 'currency_data.dart';
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
