import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/itinerary.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';

import 'budgeting/budgeting_module.dart';
import 'budgeting/expense.dart';
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

  ItineraryFacadeCollection get itineraryCollection;

  BudgetingModuleFacade get budgetingFacade;

  Iterable<TransitOptionMetadata> get transitOptionMetadatas;
}

abstract class TripDataModelEventHandler extends TripDataFacade
    implements Dispose {
  ItineraryFacadeCollectionEventHandler get itineraryCollectionEventHandler;

  Future updateTripMetadata(
      LeafRepositoryItem<TripMetadataFacade> tripMetadataLeafRepositoryItem);

  LeafRepositoryItem<TripMetadataFacade> get tripMetadataModelEventHandler;

  ModelCollectionModifier<TransitFacade> get transitsModelCollection;

  ModelCollectionModifier<LodgingFacade> get lodgingModelCollection;

  ModelCollectionModifier<ExpenseFacade> get expenseModelCollection;

  ModelCollectionModifier<PlanDataFacade> get planDataModelCollection;
}
