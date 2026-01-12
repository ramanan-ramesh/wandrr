import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';

import 'itinerary_plan_data.dart';

abstract class ItineraryFacade extends Equatable implements TripEntity {
  String get tripId;

  DateTime get day;

  ItineraryPlanData get planData;

  Iterable<TransitFacade> get transits;

  LodgingFacade? get checkInLodging;

  LodgingFacade? get checkOutLodging;

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

  set checkOutLodging(LodgingFacade? lodging);

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

  /// Prepares itinerary day changes and sight updates to be executed in an external WriteBatch.
  /// This allows all changes (itinerary days + sight updates) to be committed atomically in a single batch.
  ///
  /// Parameters:
  /// - batch: The WriteBatch to add operations to
  /// - startDate: New trip start date
  /// - endDate: New trip end date
  /// - sightChanges: List of sight changes to apply to itineraries
  /// - expenseChanges: List of expense changes to apply expense updates to sights
  ///
  /// Returns a Future that resolves to a function which updates local state after batch commits.
  Future<Future<void> Function()> prepareTripDaysUpdate(
    WriteBatch batch,
    DateTime startDate,
    DateTime endDate,
    Iterable<EntityChange<SightFacade>> sightChanges,
    Iterable<EntityChange<ExpenseBearingTripEntity>> expenseChanges,
  );
}
