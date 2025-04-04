import 'dart:collection';

import 'package:wandrr/data/app/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/models/plan_data.dart';

import 'lodging.dart';
import 'transit.dart';

abstract class ItineraryFacade {
  final String tripId;

  final DateTime day;

  List<TransitFacade> get transits;

  LodgingFacade? get checkinLodging;

  LodgingFacade? get checkoutLodging;

  LodgingFacade? get fullDayLodging;

  PlanDataFacade get planData;

  ItineraryFacade(this.tripId, this.day);
}

abstract class ItineraryModelEventHandler extends ItineraryFacade {
  ItineraryModelEventHandler(super.tripId, super.day);

  LeafRepositoryItem<PlanDataFacade> get planDataEventHandler;

  void addTransit(TransitFacade transitToAdd);

  void setCheckinLodging(LodgingFacade? lodging);

  void setCheckoutLodging(LodgingFacade? lodging);

  void setFullDayLodging(LodgingFacade? lodging);

  void removeTransit(TransitFacade transit);
}

abstract class ItineraryFacadeCollection extends ListBase<ItineraryFacade> {
  ItineraryModelEventHandler getItineraryForDay(DateTime dateTime);
}

abstract class ItineraryFacadeCollectionEventHandler
    extends ItineraryFacadeCollection {
  Future updateTripDays(DateTime startDate, DateTime endDate);
}
