import 'dart:collection';

import 'package:wandrr/contracts/plan_data.dart';
import 'package:wandrr/contracts/repository_pattern.dart';

import 'lodging.dart';
import 'transit.dart';

abstract class ItineraryModelFacade {
  final String tripId;

  final DateTime day;

  List<TransitModelFacade> get transits;

  LodgingModelFacade? get lodging;

  PlanDataModelFacade get planData;

  ItineraryModelFacade(this.tripId, this.day);
}

abstract class ItineraryModelEventHandler extends ItineraryModelFacade {
  ItineraryModelEventHandler(super.tripId, super.day);

  RepositoryPattern<PlanDataModelFacade> get planDataEventHandler;

  void addTransit(TransitModelFacade transitToAdd);

  void addLodging(LodgingModelFacade lodging);

  void removeTransit(TransitModelFacade transit);

  void removeLodging(LodgingModelFacade lodging);
}

abstract class ItineraryModelCollectionFacade
    extends ListBase<ItineraryModelFacade> {
  ItineraryModelEventHandler getItineraryForDay(DateTime dateTime);
}

abstract class ItineraryModelCollectionEventHandler
    extends ItineraryModelCollectionFacade {
  Future updateTripDays(DateTime startDate, DateTime endDate);
}
