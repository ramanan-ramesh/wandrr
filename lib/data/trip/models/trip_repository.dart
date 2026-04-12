import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/model_collection.dart';

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
  @override
  ModelCollectionModifier<TripMetadataFacade> get tripMetadataCollection;

  @override
  TripDataModelEventHandler? get activeTrip;

  TripDataModelEventHandler loadTrip(TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository,
      {required bool activateTrip});

  Future deleteTrip(TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository);

  Future<TripMetadataFacade> copyTrip(
      TripMetadataFacade tripToCopy,
      TripMetadataFacade targetTrip,
      ApiServicesRepositoryFacade apiServicesRepository);

  Future unloadActiveTrip();
}
