import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/itinerary.dart';
import 'package:wandrr/data/trip/models/plan_data.dart';

import 'budgeting_module.dart';
import 'expense.dart';
import 'lodging.dart';
import 'transit.dart';
import 'transit_option_metadata.dart';
import 'trip_metadata.dart';

abstract class TripDataFacade {
  TripMetadataFacade get tripMetadata;

  List<TransitFacade> get transits;

  List<LodgingFacade> get lodgings;

  List<ExpenseFacade> get expenses;

  List<PlanDataFacade> get planDataList;

  ItineraryFacadeCollection get itineraryModelCollection;

  BudgetingModuleFacade get budgetingModuleFacade;

  Iterable<TransitOptionMetadata> get transitOptionMetadatas;
}

abstract class TripDataModelEventHandler extends TripDataFacade
    implements Dispose {
  ItineraryFacadeCollectionEventHandler
      get itineraryModelCollectionEventHandler;

  Future updateTripMetadata(
      LeafRepositoryItem<TripMetadataFacade> tripMetadataRepositoryPattern);

  LeafRepositoryItem<TripMetadataFacade> get tripMetadataModelEventHandler;

  ModelCollectionFacade<TransitFacade> get transitsModelCollection;

  ModelCollectionFacade<LodgingFacade> get lodgingModelCollection;

  ModelCollectionFacade<ExpenseFacade> get expenseModelCollection;

  ModelCollectionFacade<PlanDataFacade> get planDataModelCollection;
}
