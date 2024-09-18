import 'package:wandrr/app_data/models/model_collection_facade.dart';
import 'package:wandrr/app_data/models/repository_pattern.dart';
import 'package:wandrr/trip_data/models/itinerary.dart';
import 'package:wandrr/trip_data/models/plan_data.dart';

import 'budgeting_module.dart';
import 'expense.dart';
import 'lodging.dart';
import 'transit.dart';
import 'trip_metadata.dart';

abstract class TripDataFacade {
  TripMetadataFacade get tripMetadata;

  List<TransitFacade> get transits;

  List<LodgingFacade> get lodgings;

  List<ExpenseFacade> get expenses;

  List<PlanDataFacade> get planDataList;

  ItineraryFacadeCollection get itineraryModelCollection;

  BudgetingModuleFacade get budgetingModuleFacade;
}

abstract class TripDataModelEventHandler extends TripDataFacade
    implements Dispose {
  ItineraryFacadeCollectionEventHandler
      get itineraryModelCollectionEventHandler;

  Future updateTripMetadata(
      RepositoryPattern<TripMetadataFacade> tripMetadataRepositoryPattern);

  RepositoryPattern<TripMetadataFacade> get tripMetadataModelEventHandler;

  ModelCollectionFacade<TransitFacade> get transitsModelCollection;

  ModelCollectionFacade<LodgingFacade> get lodgingModelCollection;

  ModelCollectionFacade<ExpenseFacade> get expenseModelCollection;

  ModelCollectionFacade<PlanDataFacade> get planDataModelCollection;
}
