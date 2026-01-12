import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';

import 'itinerary_plan_data_implementation.dart';

class ItineraryCollection extends ItineraryFacadeCollectionEventHandler {
  final _subscriptions = <StreamSubscription>[];
  final String tripId;
  DateTime _startDate;
  DateTime _endDate;
  List<ItineraryModelEventHandler> _itineraries;

  static Future<ItineraryCollection> createInstance({
    required ModelCollectionFacade<TransitFacade> transitCollection,
    required ModelCollectionFacade<LodgingFacade> lodgingCollection,
    required TripMetadataFacade tripMetadata,
  }) async {
    final itineraries = await _createItineraryList(
      tripMetadata: tripMetadata,
      transitCollection: transitCollection,
      lodgingCollection: lodgingCollection,
    );
    return ItineraryCollection._(
      transitCollection: transitCollection,
      lodgingCollection: lodgingCollection,
      tripId: tripMetadata.id!,
      startDate: tripMetadata.startDate!,
      endDate: tripMetadata.endDate!,
      itineraries: itineraries,
    );
  }

  @override
  Future dispose() async {
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    for (var itinerary in _itineraries) {
      await itinerary.dispose();
    }
    _itineraries.clear();
  }

  @override
  Iterator<ItineraryModelEventHandler> get iterator => _itineraries.iterator;

  @override
  Future<void> updateTripDays(DateTime startDate, DateTime endDate) async {
    var writeBatch = FirebaseFirestore.instance.batch();
    final updateLocalState = await prepareTripDaysUpdate(
      writeBatch,
      startDate,
      endDate,
      [], // No sight changes for simple updateTripDays
      [], // No expense changes
    );
    await writeBatch.commit();
    await updateLocalState();
  }

  @override
  Future<Future<void> Function()> prepareTripDaysUpdate(
    WriteBatch batch,
    DateTime startDate,
    DateTime endDate,
    Iterable<EntityChange<SightFacade>> sightChanges,
    Iterable<EntityChange<ExpenseBearingTripEntity>> expenseChanges,
  ) async {
    final oldDates = _getDateRange(_startDate, _endDate);
    final newDates = _getDateRange(startDate, endDate);

    final datesToAdd = newDates.difference(oldDates);
    final datesToRemove = oldDates.difference(newDates);

    // Build sight change maps
    final sightOps =
        _buildSightOperations(sightChanges, expenseChanges, startDate, endDate);

    // Collect all days that need plan data updates
    final daysNeedingUpdate = <String>{...sightOps.affectedDays};

    // Queue deletions for removed days
    for (final date in datesToRemove) {
      final dayKey = date.itineraryDateFormat;
      var itinerary =
          _itineraries.singleWhere((it) => it.day.isOnSameDayAs(date));
      itinerary.dispose();
      var planData = ItineraryPlanDataModelImplementation.fromModelFacade(
          itinerary.planData);
      batch.delete(planData.documentReference);
      // Remove from days needing update since we're deleting them
      daysNeedingUpdate.remove(dayKey);
    }

    // Create new itineraries for added days
    final newItineraries = <ItineraryModelEventHandler>[];
    for (final date in datesToAdd) {
      final dayKey = date.itineraryDateFormat;

      // Get any sights being added to this new day
      final sightsForDay = sightOps.sightsToAdd[dayKey] ?? [];

      var planData = ItineraryPlanDataModelImplementation(
        tripId: tripId,
        id: dayKey,
        day: date,
        sights: sightsForDay,
        notes: [],
        checkLists: [],
      );
      if (sightsForDay.isNotEmpty) {
        batch.set(planData.documentReference, planData.toJson());
      }

      //Create an itinerary with just ItineraryPlanData for now. Transits and Stays should be filled when batch commits succeed and ModelCollection events fire.
      var itinerary = await ItineraryModelImplementation.createInstance(
        tripId: tripId,
        day: date,
        transits: [],
        checkinLodging: null,
        checkoutLodging: null,
        fullDayLodging: null,
        planData: planData,
      );
      newItineraries.add(itinerary);

      // Remove from days needing update since we've handled it
      daysNeedingUpdate.remove(dayKey);
    }

    // Update existing itineraries with sight changes
    for (final dayKey in daysNeedingUpdate) {
      final itinerary =
          _itineraries.singleWhere((it) => it.planData.id == dayKey);

      // Start with current sights
      final currentSights = List<SightFacade>.from(itinerary.planData.sights);

      // Apply updates first
      for (final sight in sightOps.sightsToUpdate[dayKey] ?? <SightFacade>[]) {
        final idx = currentSights.indexWhere((s) => s.id == sight.id);
        if (idx >= 0) {
          currentSights[idx] = sight;
        }
      }

      // Apply removals
      final toRemove = sightOps.sightsToRemove[dayKey] ?? {};
      currentSights.removeWhere((s) => toRemove.contains(s.id));

      // Apply additions
      currentSights.addAll(sightOps.sightsToAdd[dayKey] ?? []);

      // Create updated plan data
      final updatedPlanData = ItineraryPlanDataModelImplementation(
        tripId: tripId,
        id: dayKey,
        day: itinerary.day,
        sights: currentSights,
        notes: itinerary.planData.notes.toList(),
        checkLists: itinerary.planData.checkLists.toList(),
      );

      batch.set(updatedPlanData.documentReference, updatedPlanData.toJson());
    }

    // Return function to update local state after batch commits
    return () async {
      _itineraries.removeWhere((it) => datesToRemove.contains(it.day));
      _itineraries.addAll(newItineraries);
      _itineraries.sort((a, b) => a.day.compareTo(b.day));
      _startDate = startDate;
      _endDate = endDate;
    };
  }

  /// Builds organized sight operations from change lists
  _SightOperations _buildSightOperations(
    Iterable<EntityChange<SightFacade>> sightChanges,
    Iterable<EntityChange<ExpenseBearingTripEntity>> expenseChanges,
    DateTime startDate,
    DateTime endDate,
  ) {
    final sightsToRemove = <String, Set<String>>{};
    final sightsToAdd = <String, List<SightFacade>>{};
    final sightsToUpdate = <String, List<SightFacade>>{};
    final affectedDays = <String>{};

    for (final change in sightChanges) {
      final originalDay = change.originalEntity.day;
      final originalDayKey = originalDay.itineraryDateFormat;

      if (change.isDelete) {
        sightsToRemove.putIfAbsent(originalDayKey, () => {});
        sightsToRemove[originalDayKey]!.add(change.originalEntity.id!);
        affectedDays.add(originalDayKey);
      } else if (change.isUpdate) {
        final modifiedSight = change.modifiedEntity;
        final newDay = modifiedSight.day;
        final newDayKey = newDay.itineraryDateFormat;

        // Skip if outside new trip range
        if (newDay.isBefore(startDate) || newDay.isAfter(endDate)) {
          continue;
        }

        // Apply expense update if exists
        final expenseChange = expenseChanges.singleWhereOrNull((e) =>
            e.originalEntity is SightFacade &&
            e.originalEntity.id == modifiedSight.id);
        if (expenseChange != null) {
          modifiedSight.expense = expenseChange.modifiedEntity.expense;
        }

        if (!originalDay.isOnSameDayAs(newDay)) {
          // Moving to different day
          sightsToRemove.putIfAbsent(originalDayKey, () => {});
          sightsToRemove[originalDayKey]!.add(change.originalEntity.id!);
          affectedDays.add(originalDayKey);

          if (modifiedSight.validate()) {
            sightsToAdd.putIfAbsent(newDayKey, () => []);
            sightsToAdd[newDayKey]!.add(modifiedSight);
            affectedDays.add(newDayKey);
          }
        } else if (modifiedSight.validate()) {
          // Same day, just update
          sightsToUpdate.putIfAbsent(originalDayKey, () => []);
          sightsToUpdate[originalDayKey]!.add(modifiedSight);
          affectedDays.add(originalDayKey);
        }
      }
    }

    return _SightOperations(
      sightsToRemove: sightsToRemove,
      sightsToAdd: sightsToAdd,
      sightsToUpdate: sightsToUpdate,
      affectedDays: affectedDays,
    );
  }

  @override
  ItineraryModelEventHandler getItineraryForDay(DateTime dateTime) {
    return _itineraries
        .singleWhere((itinerary) => itinerary.day.isOnSameDayAs(dateTime));
  }

  static Future<List<ItineraryModelEventHandler>> _createItineraryList({
    required TripMetadataFacade tripMetadata,
    required ModelCollectionFacade<TransitFacade> transitCollection,
    required ModelCollectionFacade<LodgingFacade> lodgingCollection,
  }) async {
    final startDate = tripMetadata.startDate!;
    final endDate = tripMetadata.endDate!;
    final numberOfDays =
        startDate.calculateDaysInBetween(endDate, includeExtraDay: true);
    final itineraries = <ItineraryModelEventHandler>[];

    final transitsPerDay = _groupTransitsByDay(
        transitCollection.collectionItems, startDate, numberOfDays);
    final lodgingsPerDay = _groupLodgingsByDay(
        lodgingCollection.collectionItems, startDate, numberOfDays);

    for (var i = 0; i < numberOfDays; i++) {
      final day = startDate.add(Duration(days: i));
      var transits = transitsPerDay.entries
          .firstWhere((mapElement) => mapElement.key.isOnSameDayAs(day))
          .value;
      var lodgings = lodgingsPerDay.entries
              .where((mapElement) => mapElement.key.isOnSameDayAs(day))
              .firstOrNull
              ?.value ??
          [];

      final checkinLodging = lodgings
          .where((lodging) => lodging.checkinDateTime!.isOnSameDayAs(day))
          .firstOrNull;
      final checkoutLodging = lodgings
          .where((lodging) => lodging.checkoutDateTime!.isOnSameDayAs(day))
          .firstOrNull;
      final fullDayLodging = lodgings
          .where((lodging) =>
              day.isAfter(lodging.checkinDateTime!) &&
              day
                  .copyWith(hour: 23, minute: 59, second: 59)
                  .isBefore(lodging.checkoutDateTime!))
          .firstOrNull;

      var itinerary = await ItineraryModelImplementation.createInstance(
        tripId: tripMetadata.id!,
        day: day,
        transits: transits,
        checkinLodging: checkinLodging,
        checkoutLodging: checkoutLodging,
        fullDayLodging: fullDayLodging,
      );
      itineraries.add(
        itinerary,
      );
    }
    return itineraries;
  }

  void _initializeListeners(
      ModelCollectionFacade<TransitFacade> transitCollection,
      ModelCollectionFacade<LodgingFacade> lodgingCollection) {
    _subscriptions
        .add(transitCollection.onDocumentAdded.listen((eventData) async {
      var transitAdded = eventData.modifiedCollectionItem;
      _addOrRemoveTransitToItinerary(transitAdded, false);
    }));
    _subscriptions
        .add(transitCollection.onDocumentDeleted.listen((eventData) async {
      var transitDeleted = eventData.modifiedCollectionItem;
      _addOrRemoveTransitToItinerary(transitDeleted, true);
    }));
    _subscriptions
        .add(transitCollection.onDocumentUpdated.listen((eventData) async {
      var transitBeforeUpdate = eventData.modifiedCollectionItem.beforeUpdate;
      var transitAfterUpdate = eventData.modifiedCollectionItem.afterUpdate;
      _addOrRemoveTransitToItinerary(transitBeforeUpdate, true);
      _addOrRemoveTransitToItinerary(transitAfterUpdate, false);
    }));
    _subscriptions
        .add(lodgingCollection.onDocumentAdded.listen((eventData) async {
      var lodgingAdded = eventData.modifiedCollectionItem;
      _addOrRemoveLodgingToItinerary(lodgingAdded, false);
    }));
    _subscriptions
        .add(lodgingCollection.onDocumentUpdated.listen((eventData) async {
      var lodgingBeforeUpdate = eventData.modifiedCollectionItem.beforeUpdate;
      var lodgingAfterUpdate = eventData.modifiedCollectionItem.afterUpdate;
      _addOrRemoveLodgingToItinerary(lodgingBeforeUpdate, true);
      _addOrRemoveLodgingToItinerary(lodgingAfterUpdate, false);
    }));
    _subscriptions
        .add(lodgingCollection.onDocumentDeleted.listen((eventData) async {
      var lodgingDeleted = eventData.modifiedCollectionItem;
      _addOrRemoveLodgingToItinerary(lodgingDeleted, true);
    }));
  }

  void _addOrRemoveTransitToItinerary(TransitFacade transit, bool toDelete) {
    for (final itinerary in _itineraries) {
      var isItineraryDayOnOrAfterDeparture =
          itinerary.day.isOnSameDayAs(transit.departureDateTime!) ||
              itinerary.day.isAfter(transit.departureDateTime!);
      var isItineraryDayOnOrBeforeArrival =
          itinerary.day.isOnSameDayAs(transit.arrivalDateTime!) ||
              itinerary.day
                  .copyWith(hour: 23, minute: 59, second: 59)
                  .isBefore(transit.arrivalDateTime!);
      if (isItineraryDayOnOrAfterDeparture && isItineraryDayOnOrBeforeArrival) {
        if (toDelete) {
          itinerary.removeTransit(transit);
        } else {
          itinerary.addTransit(transit);
        }
      }
    }
  }

  void _addOrRemoveLodgingToItinerary(LodgingFacade lodging, bool toDelete) {
    for (final itinerary in _itineraries) {
      if (itinerary.day.isOnSameDayAs(lodging.checkinDateTime!)) {
        itinerary.checkInLodging = toDelete ? null : lodging;
      }
      if (itinerary.day.isOnSameDayAs(lodging.checkoutDateTime!)) {
        itinerary.checkOutLodging = toDelete ? null : lodging;
      }
      if (itinerary.day.isAfter(lodging.checkinDateTime!) &&
          itinerary.day
              .copyWith(hour: 23, minute: 59, second: 59)
              .isBefore(lodging.checkoutDateTime!)) {
        itinerary.fullDayLodging = toDelete ? null : lodging;
      }
    }
  }

  static Map<DateTime, Iterable<TransitFacade>> _groupTransitsByDay(
    Iterable<TransitFacade> transits,
    DateTime startDate,
    int numberOfDays,
  ) {
    final transitsPerDay = <DateTime, List<TransitFacade>>{};
    for (var i = 0; i < numberOfDays; i++) {
      final day = startDate.add(Duration(days: i));
      transitsPerDay[day] = transits
          .where((transit) =>
              (day.isAfter(transit.departureDateTime!) ||
                  day.isOnSameDayAs(transit.departureDateTime!)) &&
              (day
                      .copyWith(hour: 23, minute: 59, second: 59)
                      .isBefore(transit.arrivalDateTime!) ||
                  day.isOnSameDayAs(transit.arrivalDateTime!)))
          .toList();
    }
    return transitsPerDay;
  }

  static Map<DateTime, Iterable<LodgingFacade>> _groupLodgingsByDay(
    Iterable<LodgingFacade> lodgings,
    DateTime startDate,
    int numberOfDays,
  ) {
    final lodgingsPerDay = <DateTime, List<LodgingFacade>>{};
    for (var i = 0; i < numberOfDays; i++) {
      final day = startDate.add(Duration(days: i));
      lodgingsPerDay[day] = lodgings
          .where((lodging) =>
              (day.isAfter(lodging.checkinDateTime!) ||
                  day.isOnSameDayAs(lodging.checkinDateTime!)) &&
              (day
                      .copyWith(hour: 23, minute: 59, second: 59)
                      .isBefore(lodging.checkoutDateTime!) ||
                  day.isOnSameDayAs(lodging.checkoutDateTime!)))
          .toList();
    }
    return lodgingsPerDay;
  }

  Set<DateTime> _getDateRange(DateTime startDate, DateTime endDate) {
    final dateSet = <DateTime>{};
    var currentDate = startDate;
    while (currentDate
            .copyWith(hour: 23, minute: 59, second: 59)
            .isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      dateSet
          .add(DateTime(currentDate.year, currentDate.month, currentDate.day));
      currentDate = currentDate.add(const Duration(days: 1));
    }
    return dateSet;
  }

  ItineraryCollection._({
    required this.tripId,
    required ModelCollectionFacade<TransitFacade> transitCollection,
    required ModelCollectionFacade<LodgingFacade> lodgingCollection,
    required DateTime startDate,
    required DateTime endDate,
    required List<ItineraryModelEventHandler> itineraries,
  })  : _startDate = startDate,
        _endDate = endDate,
        _itineraries = itineraries {
    _initializeListeners(transitCollection, lodgingCollection);
  }
}

/// Helper class to organize sight operations by day
class _SightOperations {
  final Map<String, Set<String>> sightsToRemove;
  final Map<String, List<SightFacade>> sightsToAdd;
  final Map<String, List<SightFacade>> sightsToUpdate;
  final Set<String> affectedDays;

  const _SightOperations({
    required this.sightsToRemove,
    required this.sightsToAdd,
    required this.sightsToUpdate,
    required this.affectedDays,
  });
}
