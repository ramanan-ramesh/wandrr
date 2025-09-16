import 'dart:collection';

import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'lodging.dart';
import 'transit.dart';

abstract class ItineraryFacade extends TripEntity {
  String get tripId;

  DateTime get day;

  Iterable<TransitFacade> get transits;

  LodgingFacade? get checkinLodging;

  LodgingFacade? get checkoutLodging;

  LodgingFacade? get fullDayLodging;

  PlanDataFacade get planData;

  @override
  String get id => day.toIso8601String();
}

abstract class ItineraryModelEventHandler extends ItineraryFacade {
  LeafRepositoryItem<PlanDataFacade> get planDataEventHandler;

  void addTransit(TransitFacade transitToAdd);

  void removeTransit(TransitFacade transit);

  set checkInLodging(LodgingFacade? lodging);

  set checkoutLodging(LodgingFacade? lodging);

  set fullDayLodging(LodgingFacade? lodging);
}

abstract class ItineraryFacadeCollection extends IterableBase<ItineraryFacade> {
  ItineraryModelEventHandler getItineraryForDay(DateTime dateTime);
}

abstract class ItineraryFacadeCollectionEventHandler
    extends ItineraryFacadeCollection {
  Future updateTripDays(DateTime startDate, DateTime endDate);
}
