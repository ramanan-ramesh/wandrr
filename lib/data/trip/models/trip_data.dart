import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';

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

  ModelCollectionFacade<StandaloneExpense> get expenseCollection;

  ItineraryFacadeCollection get itineraryCollection;

  BudgetingModuleFacade get budgetingModule;

  //TODO: Is repository the right place for localizations related constants? If so, then create a repository at TripEditor page level only
  Iterable<TransitOptionMetadata> get transitOptionMetadatas;
}

abstract class TripDataModelEventHandler extends TripDataFacade
    implements Dispose {
  Future updateTripMetadata(TripMetadataFacade tripMetadata);

  ItineraryFacadeCollectionEventHandler get itineraryCollection;

  ModelCollectionModifier<TransitFacade> get transitCollection;

  ModelCollectionModifier<LodgingFacade> get lodgingCollection;

  ModelCollectionModifier<StandaloneExpense> get expenseCollection;
}
