import 'dart:async';
import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'itinerary_plan_data.dart';

abstract class ItineraryFacade extends Equatable implements TripEntity {
  String get tripId;

  DateTime get day;

  ItineraryPlanData get planData;

  Iterable<TransitFacade> get transits;

  LodgingFacade? get checkinLodging;

  LodgingFacade? get checkoutLodging;

  LodgingFacade? get fullDayLodging;
}

abstract class ItineraryModelEventHandler extends ItineraryFacade
    implements Dispose {
  Stream<
      CollectionItemChangeMetadata<
          CollectionItemChangeSet<ItineraryPlanData>>> get planDataStream;

  Future<bool> updatePlanData(ItineraryPlanData planData);

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
