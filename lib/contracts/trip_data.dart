import 'package:wandrr/contracts/budgeting_module.dart';
import 'package:wandrr/contracts/itinerary.dart';
import 'package:wandrr/contracts/plan_data.dart';
import 'package:wandrr/contracts/repository_pattern.dart';

import 'expense.dart';
import 'lodging.dart';
import 'model_collection.dart';
import 'transit.dart';
import 'trip_metadata.dart';

abstract class TripEntity {
  String? id;

  TripEntity(this.id);
}

abstract class TripDataModelFacade {
  TripMetadataModelFacade get tripMetadata;

  List<TransitModelFacade> get transits;

  List<LodgingModelFacade> get lodgings;

  List<ExpenseModelFacade> get expenses;

  List<PlanDataModelFacade> get planDataList;

  ItineraryModelCollectionFacade get itineraryModelCollection;

  BudgetingModuleFacade get budgetingModuleFacade;
}

abstract class TripDataModelEventHandler extends TripDataModelFacade
    implements Dispose {
  ItineraryModelCollectionEventHandler get itineraryModelCollectionEventHandler;

  Future updateTripMetadata(
      RepositoryPattern<TripMetadataModelFacade> tripMetadataRepositoryPattern);

  RepositoryPattern<TripMetadataModelFacade> get tripMetadataModelEventHandler;

  ModelCollectionFacade<TransitModelFacade> get transitsModelCollection;

  ModelCollectionFacade<LodgingModelFacade> get lodgingModelCollection;

  ModelCollectionFacade<ExpenseModelFacade> get expenseModelCollection;

  ModelCollectionFacade<PlanDataModelFacade> get planDataModelCollection;
}
