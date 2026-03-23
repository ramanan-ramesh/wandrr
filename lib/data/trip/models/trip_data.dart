import 'package:flutter/foundation.dart';
import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';

import 'budgeting/budgeting_module.dart';
import 'budgeting/expense.dart';
import 'lodging.dart';
import 'transit.dart';
import 'trip_metadata.dart';

abstract class TripDataFacade {
  TripMetadataFacade get tripMetadata;

  ModelCollectionFacade<TransitFacade> get transitCollection;

  ModelCollectionFacade<LodgingFacade> get lodgingCollection;

  ModelCollectionFacade<StandaloneExpense> get expenseCollection;

  ItineraryFacadeCollection get itineraryCollection;

  BudgetingModuleFacade get budgetingModule;

  ValueNotifier<bool> get isFullyLoadedNotifier;
}

abstract class TripDataModelEventHandler extends TripDataFacade
    implements Dispose {
  /// Updates trip metadata and applies all necessary rebalancing
  /// @deprecated Use applyUpdatePlan for more control over the update process
  Future updateTripMetadata(TripMetadataFacade tripMetadata);

  /// Applies a pre-computed update plan using batch writes
  /// This is the preferred way to handle trip metadata changes
  ///
  /// The update order is:
  /// 1. Update currency (if changed)
  /// 2. Update/delete transits, stays, sights, expenses (entity changes)
  /// 3. Update itinerary days (add/remove days)
  /// 4. Recalculate total expenditure
  Future<void> applyUpdatePlan(TripEntityUpdatePlan plan);

  ItineraryFacadeCollectionEventHandler get itineraryCollection;

  ModelCollectionModifier<TransitFacade> get transitCollection;

  ModelCollectionModifier<LodgingFacade> get lodgingCollection;

  ModelCollectionModifier<StandaloneExpense> get expenseCollection;
}
