import 'model_collection.dart';
import 'repository_pattern.dart';
import 'trip_data.dart';
import 'trip_metadata.dart';

abstract class TripRepositoryModelFacade {
  List<TripMetadataModelFacade> get tripMetadatas;

  TripDataModelFacade? get activeTrip;
}

abstract class TripRepositoryEventHandler extends TripRepositoryModelFacade
    implements Dispose {
  ModelCollectionFacade<TripMetadataModelFacade>
      get tripMetadataModelCollection;

  TripDataModelEventHandler? get activeTripEventHandler;

  Future loadAndActivateTrip(TripMetadataModelFacade? tripMetadata);
}
