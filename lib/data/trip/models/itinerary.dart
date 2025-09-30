import 'dart:async';
import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'lodging.dart';
import 'transit.dart';

abstract class ItineraryFacade extends Equatable implements TripEntity {
  String get tripId;
  DateTime get day;
  PlanDataFacade get planData;
  Iterable<TransitFacade> get transits;
  LodgingFacade? get checkinLodging;

  LodgingFacade? get checkoutLodging;
  LodgingFacade? get fullDayLodging;

  @override
  String get id => day.toIso8601String();
}

abstract class ItineraryModelEventHandler extends ItineraryFacade
    implements Dispose {
  Stream<CollectionItemChangeMetadata<PlanDataFacade>> get planDataStream;

  Future<bool> updatePlanData(PlanDataFacade planData);

  void addTransit(TransitFacade transitToAdd);

  void removeTransit(TransitFacade transit);

  set checkInLodging(LodgingFacade? lodging);

  set checkoutLodging(LodgingFacade? lodging);

  set fullDayLodging(LodgingFacade? lodging);
}

abstract class ItineraryFacadeCollection<T extends ItineraryFacade>
    extends IterableBase<T> {
  T getItineraryForDay(DateTime dateTime);
}

abstract class ItineraryFacadeCollectionEventHandler
    extends ItineraryFacadeCollection<ItineraryModelEventHandler>
    implements Dispose {
  Future<void> updateTripDays(DateTime startDate, DateTime endDate);
}
