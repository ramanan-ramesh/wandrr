import '../../app_data/models/model_collection_facade.dart';
import '../../app_data/models/repository_pattern.dart';
import 'trip_data.dart';
import 'trip_metadata.dart';

abstract class TripRepositoryFacade {
  List<TripMetadataFacade> get tripMetadatas;

  TripDataFacade? get activeTrip;
}

abstract class TripRepositoryEventHandler extends TripRepositoryFacade
    implements Dispose {
  ModelCollectionFacade<TripMetadataFacade> get tripMetadataModelCollection;

  TripDataModelEventHandler? get activeTripEventHandler;

  Future loadAndActivateTrip(TripMetadataFacade? tripMetadata);
}
