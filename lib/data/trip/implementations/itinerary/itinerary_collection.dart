import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/services/conflict_detection/entity_change.dart';

import 'itinerary_plan_data_implementation.dart';

class ItineraryCollection extends ItineraryFacadeCollectionEventHandler {
  final _subscriptions = <StreamSubscription>[];
  final String tripId;
  DateTime _startDate;
  DateTime _endDate;
  final List<ItineraryModelImplementation> _itineraries;
  final ModelCollectionFacade<TransitFacade> _transitCollection;
  final ModelCollectionFacade<LodgingFacade> _lodgingCollection;

  /// Day keys of plan-data writes triggered by an explicit local action.
  /// The Firestore listener will skip emitting a stream event for these,
  /// since the collection already emits one with isFromExplicitAction: true.
  final Set<String> _explicitPlanDataUpdateIds = {};

  bool _isPlanDataLoaded = false;

  @override
  bool get isLoaded => _isLoaded;
  bool _isLoaded = false;

  @override
  Stream<bool> get onLoaded => _isLoadedController.stream;
  final StreamController<bool> _isLoadedController =
      StreamController<bool>.broadcast();

  static ItineraryCollection createInstance({
    required ModelCollectionFacade<TransitFacade> transitCollection,
    required ModelCollectionFacade<LodgingFacade> lodgingCollection,
    required TripMetadataFacade tripMetadata,
  }) {
    // Always create skeleton itineraries (no transit/lodging data yet).
    // Transits/lodgings are populated in one pass once both collections are loaded.
    final itineraries =
        _createSkeletonItineraryList(tripMetadata: tripMetadata);
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
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    for (final itinerary in _itineraries) {
      await itinerary.dispose();
    }
    _itineraries.clear();
    await _isLoadedController.close();
  }

  @override
  Iterator<ItineraryFacade> get iterator => _itineraries.iterator;

  @override
  Future<void Function()> prepareTripDaysUpdate(
    WriteBatch batch,
    DateTime startDate,
    DateTime endDate,
    Iterable<SightChange> sightChanges,
    Iterable<ExpenseSplitChange> expenseChanges,
  ) async {
    final oldDates = _getDateRange(_startDate, _endDate);
    final newDates = _getDateRange(startDate, endDate);
    final datesToAdd = newDates.difference(oldDates);
    final datesToRemove = oldDates.difference(newDates);

    final sightOps =
        _buildSightOperations(sightChanges, expenseChanges, startDate, endDate);

    // Days with sight changes; deleted/added days are handled separately and
    // removed from this set so they are not double-processed.
    final daysNeedingUpdate = <String>{...sightOps.affectedDays};

    // --- Removed days: dispose + queue Firestore deletion ---
    for (final date in datesToRemove) {
      final itinerary =
          _itineraries.singleWhere((it) => it.day.isOnSameDayAs(date));
      await itinerary.dispose();
      batch.delete(
        ItineraryPlanDataModelImplementation.fromModelFacade(itinerary.planData)
            .documentReference,
      );
      daysNeedingUpdate.remove(date.itineraryDateFormat);
    }

    // --- Added days: create skeleton itinerary + optional Firestore write ---
    final newItineraries = <ItineraryModelImplementation>[];
    for (final date in datesToAdd) {
      final dayKey = date.itineraryDateFormat;
      // New days start empty; only sights being moved/added apply here.
      final sightsForDay =
          _applySightOps(current: const [], dayKey: dayKey, sightOps: sightOps);
      final planData = ItineraryPlanDataModelImplementation(
        tripId: tripId,
        id: dayKey,
        day: date,
        sights: sightsForDay,
        notes: const [],
        checkLists: const [],
      );
      // Only write to Firestore when there is actual content.
      if (sightsForDay.isNotEmpty) {
        batch.set(planData.documentReference, planData.toJson());
      }
      // Transits/lodgings are wired up later via collection events.
      newItineraries.add(ItineraryModelImplementation.createInstance(
        tripId: tripId,
        day: date,
        transits: const [],
        checkinLodging: null,
        checkoutLodging: null,
        fullDayLodging: null,
        planData: planData,
      ));
      daysNeedingUpdate.remove(dayKey);
    }

    // --- Existing days: apply sight changes ---
    for (final dayKey in daysNeedingUpdate) {
      final itinerary =
          _itineraries.singleWhere((it) => it.planData.id == dayKey);
      _writeSightUpdatesToBatch(batch, itinerary, dayKey, sightOps);
    }

    return () {
      _itineraries.removeWhere(
          (it) => datesToRemove.any((d) => d.isOnSameDayAs(it.day)));
      _itineraries.addAll(newItineraries);
      _itineraries.sort((a, b) => a.day.compareTo(b.day));
      _startDate = startDate;
      _endDate = endDate;
      if (_isLoaded) {
        _reconcileFromTransitsAndStays();
      }
    };
  }

  /// Builds organized sight operations from change lists
  _SightOperations _buildSightOperations(
    Iterable<SightChange> sightChanges,
    Iterable<ExpenseSplitChange> expenseChanges,
    DateTime startDate,
    DateTime endDate,
  ) {
    final sightsToRemove = <String, Set<String>>{};
    final sightsToAdd = <String, List<SightFacade>>{};
    final sightsToUpdate = <String, List<SightFacade>>{};
    final affectedDays = <String>{};

    for (final change in sightChanges) {
      final originalDay = change.original.day;
      final originalDayKey = originalDay.itineraryDateFormat;

      if (change.isMarkedForDeletion) {
        sightsToRemove.putIfAbsent(originalDayKey, () => {});
        sightsToRemove[originalDayKey]!.add(change.original.id!);
        affectedDays.add(originalDayKey);
      } else if (change.action == ChangeAction.update) {
        final modifiedSight = change.modified;
        final newDay = modifiedSight.day;
        final newDayKey = newDay.itineraryDateFormat;

        // Skip if outside new trip range
        if (newDay.isBefore(startDate) || newDay.isAfter(endDate)) {
          continue;
        }

        // Apply expense update if exists
        final expenseChange = expenseChanges.singleWhereOrNull((e) =>
            e.original is SightFacade &&
            (e.original as SightFacade).day == modifiedSight.day &&
            e.original.id == modifiedSight.id);
        if (expenseChange != null) {
          modifiedSight.expense = expenseChange.modified.expense;
        }

        if (!originalDay.isOnSameDayAs(newDay)) {
          // Moving to different day
          sightsToRemove.putIfAbsent(originalDayKey, () => {});
          sightsToRemove[originalDayKey]!.add(change.original.id!);
          affectedDays.add(originalDayKey);

          if (modifiedSight.getValidationErrors().isEmpty) {
            sightsToAdd.putIfAbsent(newDayKey, () => []);
            sightsToAdd[newDayKey]!.add(modifiedSight);
            affectedDays.add(newDayKey);
          }
        } else if (modifiedSight.getValidationErrors().isEmpty) {
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
  ItineraryFacade getItineraryForDay(DateTime dateTime) {
    return _itineraries
        .singleWhere((itinerary) => itinerary.day.isOnSameDayAs(dateTime));
  }

  @override
  void prepareSightUpdates(
    WriteBatch batch,
    Iterable<SightChange> sightChanges,
  ) {
    if (sightChanges.isEmpty) {
      return;
    }

    final sightOps =
        _buildSightOperations(sightChanges, const [], _startDate, _endDate);

    for (final dayKey in sightOps.affectedDays) {
      final itinerary = _itineraries
          .firstWhereOrNull((it) => it.day.itineraryDateFormat == dayKey);
      if (itinerary == null) {
        continue;
      }
      _writeSightUpdatesToBatch(batch, itinerary, dayKey, sightOps);
    }
  }

  // ---------------------------------------------------------------------------
  // Sight-update helpers
  // ---------------------------------------------------------------------------

  /// Applies [sightOps] for [dayKey] to [itinerary]'s current plan data and
  /// queues a `batch.set` with the result.
  void _writeSightUpdatesToBatch(
    WriteBatch batch,
    ItineraryModelImplementation itinerary,
    String dayKey,
    _SightOperations sightOps,
  ) {
    final updatedSights = _applySightOps(
      current: itinerary.planData.sights,
      dayKey: dayKey,
      sightOps: sightOps,
    );
    final updatedPlanData = ItineraryPlanDataModelImplementation(
      tripId: tripId,
      id: dayKey,
      day: itinerary.day,
      sights: updatedSights,
      notes: itinerary.planData.notes.toList(),
      checkLists: itinerary.planData.checkLists.toList(),
    );
    batch.set(updatedPlanData.documentReference, updatedPlanData.toJson());
  }

  /// Returns a new sights list by applying the add/update/remove operations
  /// in [sightOps] for [dayKey] to [current].
  ///
  /// Safe to pass an empty [current] for newly created days — only additions
  /// will have any effect.
  List<SightFacade> _applySightOps({
    required Iterable<SightFacade> current,
    required String dayKey,
    required _SightOperations sightOps,
  }) {
    final sights = List<SightFacade>.from(current);

    // Apply in-place updates
    for (final sight in sightOps.sightsToUpdate[dayKey] ?? <SightFacade>[]) {
      final idx = sights.indexWhere((s) => s.id == sight.id);
      if (idx >= 0) {
        sights[idx] = sight;
      }
    }
    // Apply removals
    final toRemove = sightOps.sightsToRemove[dayKey] ?? {};
    sights.removeWhere((s) => toRemove.contains(s.id));
    // Apply additions
    sights.addAll(sightOps.sightsToAdd[dayKey] ?? []);

    return sights;
  }

  /// Creates day-skeleton itineraries for the trip date range with no
  /// transit or lodging data. Transits/lodgings are populated later in one
  /// pass via [_reconcileFromTransitsAndStays].
  static List<ItineraryModelImplementation> _createSkeletonItineraryList({
    required TripMetadataFacade tripMetadata,
  }) {
    final startDate = tripMetadata.startDate!;
    final endDate = tripMetadata.endDate!;
    final numberOfDays =
        startDate.calculateDaysInBetween(endDate, includeBoundaryDay: true);
    final itineraries = <ItineraryModelImplementation>[];

    for (var i = 0; i < numberOfDays; i++) {
      final day = startDate.add(Duration(days: i));
      itineraries.add(ItineraryModelImplementation.createInstance(
        tripId: tripMetadata.id!,
        day: day,
        transits: const [],
        checkinLodging: null,
        checkoutLodging: null,
        fullDayLodging: null,
      ));
    }
    return itineraries;
  }

  /// Marks the collection as loaded once transits, lodgings, AND the initial
  /// plan-data snapshot have all been delivered.
  void _checkAndMarkLoaded() {
    if (_transitCollection.isLoaded &&
        _lodgingCollection.isLoaded &&
        _isPlanDataLoaded &&
        !_isLoaded) {
      _reconcileFromTransitsAndStays();

      _isLoaded = true;
      _isLoadedController.add(true);

      // Real-time change listeners — only process events after the initial
      // bulk-load reconciliation is complete (_isLoaded == true).
      _subscriptions.add(_transitCollection.onDocumentAdded.listen((eventData) {
        if (!_isLoaded) {
          return;
        }
        _addOrRemoveTransitToItinerary(eventData.collectionItemChange, false);
      }));
      _subscriptions
          .add(_transitCollection.onDocumentDeleted.listen((eventData) {
        if (!_isLoaded) {
          return;
        }
        _addOrRemoveTransitToItinerary(eventData.collectionItemChange, true);
      }));
      _subscriptions
          .add(_transitCollection.onDocumentUpdated.listen((eventData) {
        if (!_isLoaded) {
          return;
        }
        _addOrRemoveTransitToItinerary(
            eventData.collectionItemChange.beforeUpdate, true);
        _addOrRemoveTransitToItinerary(
            eventData.collectionItemChange.afterUpdate, false);
      }));
      _subscriptions.add(_lodgingCollection.onDocumentAdded.listen((eventData) {
        if (!_isLoaded) {
          return;
        }
        _addOrRemoveLodgingToItinerary(eventData.collectionItemChange, false);
      }));
      _subscriptions
          .add(_lodgingCollection.onDocumentUpdated.listen((eventData) {
        if (!_isLoaded) {
          return;
        }
        _addOrRemoveLodgingToItinerary(
            eventData.collectionItemChange.beforeUpdate, true);
        _addOrRemoveLodgingToItinerary(
            eventData.collectionItemChange.afterUpdate, false);
      }));
      _subscriptions
          .add(_lodgingCollection.onDocumentDeleted.listen((eventData) {
        if (!_isLoaded) {
          return;
        }
        _addOrRemoveLodgingToItinerary(eventData.collectionItemChange, true);
      }));
    }
  }

  /// Idempotently applies all items from both underlying collections to the
  /// current itinerary instances.
  void _reconcileFromTransitsAndStays() {
    for (final transit in _transitCollection.items) {
      _addOrRemoveTransitToItinerary(transit, false);
    }
    for (final lodging in _lodgingCollection.items) {
      _addOrRemoveLodgingToItinerary(lodging, false);
    }
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
          itinerary.removeTransit(transit.id!);
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
    required List<ItineraryModelImplementation> itineraries,
  })  : _startDate = startDate,
        _endDate = endDate,
        _itineraries = itineraries,
        _transitCollection = transitCollection,
        _lodgingCollection = lodgingCollection {
    _listenToItineraryDataCollection();
    if (transitCollection.isLoaded && lodgingCollection.isLoaded) {
      _checkAndMarkLoaded();
    } else {
      if (!transitCollection.isLoaded) {
        _subscriptions.add(
            transitCollection.onLoaded.listen((_) => _checkAndMarkLoaded()));
      }
      if (!lodgingCollection.isLoaded) {
        _subscriptions.add(
            lodgingCollection.onLoaded.listen((_) => _checkAndMarkLoaded()));
      }
      // One may already be loaded; check now in case it won't fire onLoaded.
      _checkAndMarkLoaded();
    }
  }

  @override
  void updatePlanData(ItineraryPlanData planData) {
    final matchingItinerary = _itineraries
        .firstWhereOrNull((it) => it.day.isOnSameDayAs(planData.day));
    if (matchingItinerary == null) {
      return;
    }

    final leafRepositoryItem =
        ItineraryPlanDataModelImplementation.fromModelFacade(planData);

    // Mark as explicit before the write so the snapshot listener can pick
    // up isFromExplicitAction = true when the echo arrives.
    _explicitPlanDataUpdateIds.add(leafRepositoryItem.id!);

    leafRepositoryItem.documentReference
        .set(leafRepositoryItem.toJson(), SetOptions(merge: false));
  }

  void _listenToItineraryDataCollection() {
    final collectionRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripId)
        .collection(FirestoreCollections.itineraryDataCollectionName);

    _subscriptions.add(collectionRef.snapshots().listen((snapshot) {
      // Capture whether this is the very first snapshot before mutating state,
      // mirroring the FirestoreModelCollection.isInitialLoad pattern.
      final isInitialLoad = !_isPlanDataLoaded;

      for (final docChange in snapshot.docChanges) {
        final doc = docChange.doc;
        if (!doc.exists) {
          continue;
        }

        final dayKey = doc.id;
        final matchingItinerary = _itineraries.firstWhereOrNull(
          (it) => it.planData.id == dayKey,
        );
        if (matchingItinerary == null) {
          continue;
        }

        // During initial load: apply silently — consumers read planData after
        // isLoaded fires; planDataStream takes over for subsequent changes.
        if (isInitialLoad) {
          final planDataModel =
              ItineraryPlanDataModelImplementation.fromDocumentSnapshot(
            tripId: tripId,
            documentData: doc.data() as Map<String, dynamic>,
            day: matchingItinerary.day,
          );
          matchingItinerary.applyPlanData(planDataModel, silent: true);
          continue;
        }

        // Snapshot listener is the sole event source. Derive isFromExplicitAction
        // from the pending-IDs set (mirrors FirestoreModelCollection pattern).
        final isExplicit = _explicitPlanDataUpdateIds.remove(dayKey);
        final planDataModel =
            ItineraryPlanDataModelImplementation.fromDocumentSnapshot(
          tripId: tripId,
          documentData: doc.data() as Map<String, dynamic>,
          day: matchingItinerary.day,
        );
        matchingItinerary.applyPlanData(planDataModel,
            isFromExplicitAction: isExplicit);
      }

      // After the first snapshot is fully processed, signal plan-data readiness
      // and check whether the collection as a whole is now loaded.
      if (isInitialLoad) {
        _isPlanDataLoaded = true;
        _checkAndMarkLoaded();
      }
    }));
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
