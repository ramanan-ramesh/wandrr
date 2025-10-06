import 'package:wandrr/data/app/models/dispose.dart';
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

  ModelCollectionFacade<TransitFacade> get transitCollection;

  ModelCollectionFacade<LodgingFacade> get lodgingCollection;

  ModelCollectionFacade<ExpenseFacade> get expenseCollection;

  ModelCollectionFacade<PlanDataFacade> get planDataCollection;

  ItineraryFacadeCollection get itineraryCollection;

  BudgetingModuleFacade get budgetingModule;

  Iterable<TransitOptionMetadata> get transitOptionMetadatas;
}

abstract class TripDataModelEventHandler extends TripDataFacade
    implements Dispose {
  Future updateTripMetadata(TripMetadataFacade tripMetadata);

  ItineraryFacadeCollectionEventHandler get itineraryCollection;

  ModelCollectionModifier<TransitFacade> get transitCollection;

  ModelCollectionModifier<LodgingFacade> get lodgingCollection;

  ModelCollectionModifier<ExpenseFacade> get expenseCollection;

  ModelCollectionModifier<PlanDataFacade> get planDataCollection;
}
