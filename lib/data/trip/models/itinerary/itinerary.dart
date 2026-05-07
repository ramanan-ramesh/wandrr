import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/change_set.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';

import 'itinerary_plan_data.dart';

abstract class ItineraryFacade extends Equatable
    implements TripEntity<ItineraryValidationError> {
  DateTime get day;

  ItineraryPlanData get planData;

  Iterable<TransitFacade> get transits;

  LodgingFacade? get checkInLodging;

  LodgingFacade? get checkOutLodging;

  LodgingFacade? get fullDayLodging;

  Stream<CollectionItemChangeMetadata<Changeset<ItineraryPlanData>>>
      get planDataStream;
}

abstract class ItineraryFacadeCollection<T extends ItineraryFacade>
    extends IterableBase<T> {
  T getItineraryForDay(DateTime dateTime);

  bool get isLoaded;

  Stream<bool> get onLoaded;
}

abstract class ItineraryFacadeCollectionEventHandler
    extends ItineraryFacadeCollection<ItineraryFacade> implements Dispose {
  /// Prepares itinerary day changes and sight updates to be executed in an external WriteBatch.
  /// This allows all changes (itinerary days + sight updates) to be committed atomically in a single batch.
  ///
  /// Returns a Future that resolves to a function which updates local state after batch commits.
  Future<void Function()> prepareTripDaysUpdate(
    WriteBatch batch,
    DateTime startDate,
    DateTime endDate,
    Iterable<SightChange> sightChanges,
    Iterable<ExpenseSplitChange> expenseChanges,
  );

  /// Prepares sight updates only (for conflict resolution, without changing trip days).
  /// Returns a Future that resolves to a function which updates local state after batch commits.
  void prepareSightUpdates(
    WriteBatch batch,
    Iterable<SightChange> sightChanges,
  );

  Future<bool> updatePlanData(ItineraryPlanData planData);
}
