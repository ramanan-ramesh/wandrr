import 'dart:collection';

import 'package:wandrr/contracts/database_connectors/repository_pattern.dart';
import 'package:wandrr/contracts/trip_entity_facades/plan_data.dart';

import 'trip_entity_facades/lodging.dart';
import 'trip_entity_facades/transit.dart';

abstract class ItineraryFacade {
  final String tripId;

  final DateTime day;

  List<TransitFacade> get transits;

  LodgingFacade? get lodging;

  PlanDataFacade get planData;

  ItineraryFacade(this.tripId, this.day);
}

abstract class ItineraryModelEventHandler extends ItineraryFacade {
  ItineraryModelEventHandler(super.tripId, super.day);

  RepositoryPattern<PlanDataFacade> get planDataEventHandler;

  void addTransit(TransitFacade transitToAdd);

  void addLodging(LodgingFacade lodging);

  void removeTransit(TransitFacade transit);

  void removeLodging(LodgingFacade lodging);
}

abstract class ItineraryFacadeCollection extends ListBase<ItineraryFacade> {
  ItineraryModelEventHandler getItineraryForDay(DateTime dateTime);
}

abstract class ItineraryFacadeCollectionEventHandler
    extends ItineraryFacadeCollection {
  Future updateTripDays(DateTime startDate, DateTime endDate);
}
