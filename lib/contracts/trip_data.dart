import 'package:wandrr/contracts/budgeting_module.dart';
import 'package:wandrr/contracts/database_connectors/repository_pattern.dart';
import 'package:wandrr/contracts/itinerary.dart';
import 'package:wandrr/contracts/trip_entity_facades/plan_data.dart';

import 'database_connectors/model_collection_facade.dart';
import 'trip_entity_facades/expense.dart';
import 'trip_entity_facades/lodging.dart';
import 'trip_entity_facades/transit.dart';
import 'trip_entity_facades/trip_metadata.dart';

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
