import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';

import 'itinerary_plan_data_implementation.dart';

class ItineraryModelImplementation implements ItineraryModelEventHandler {
  @override
  final String tripId;

  @override
  final DateTime day;

  @override
  Iterable<TransitFacade> get transits =>
      _transits.map((t) => t.clone()).toList()
        ..sort((a, b) => a.departureDateTime!.compareTo(b.departureDateTime!));
  final List<TransitFacade> _transits;

  @override
  LodgingFacade? get checkInLodging => _checkInLodging?.clone();
  LodgingFacade? _checkInLodging;

  @override
  set checkInLodging(LodgingFacade? lodging) => _checkInLodging = lodging;

  @override
  LodgingFacade? get checkOutLodging => _checkOutLodging?.clone();
  LodgingFacade? _checkOutLodging;

  @override
  set checkOutLodging(LodgingFacade? lodging) => _checkOutLodging = lodging;

  @override
  LodgingFacade? get fullDayLodging => _fullDayLodging?.clone();
  LodgingFacade? _fullDayLodging;

  @override
  set fullDayLodging(LodgingFacade? lodging) => _fullDayLodging = lodging;

  @override
  Stream<
      CollectionItemChangeMetadata<
          CollectionItemChangeSet<ItineraryPlanData>>> get planDataStream =>
      _planDataStreamController.stream;
  final StreamController<
          CollectionItemChangeMetadata<
              CollectionItemChangeSet<ItineraryPlanData>>>
      _planDataStreamController = StreamController.broadcast();

  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      _planDataSubscription;

  @override
  ItineraryPlanData get planData => _planData.facade;
  ItineraryPlanDataModelImplementation _planData;

  var _shouldListenToPlanDataChanges = true;

  static Future<ItineraryModelImplementation> createInstance({
    required String tripId,
    required DateTime day,
    required Iterable<TransitFacade> transits,
    required LodgingFacade? checkinLodging,
    required LodgingFacade? checkoutLodging,
    required LodgingFacade? fullDayLodging,
    ItineraryPlanDataModelImplementation? planData,
  }) async {
    final planDataId = day.itineraryDateFormat;
    final planDataDocRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripId)
        .collection(FirestoreCollections.itineraryDataCollectionName)
        .doc(planDataId);
    ItineraryPlanDataModelImplementation planDataModelImplementation;
    if (planData != null) {
      planDataModelImplementation = planData;
    } else {
      var planDataSnapshot = await planDataDocRef.get();
      if (planDataSnapshot.exists) {
        planDataModelImplementation =
            ItineraryPlanDataModelImplementation.fromDocumentSnapshot(
          tripId: tripId,
          documentSnapshot: planDataSnapshot,
          day: day,
        );
      } else {
        planDataModelImplementation =
            ItineraryPlanDataModelImplementation.empty(
          tripId: tripId,
          day: day,
        );
      }
    }

    return ItineraryModelImplementation._(
      tripId: tripId,
      day: day,
      planData: planDataModelImplementation,
      transits: transits.toList(),
      checkInLodging: checkinLodging,
      checkOutLodging: checkoutLodging,
      fullDayLodging: fullDayLodging,
    );
  }

  @override
  Future dispose() async {
    await _planDataSubscription.cancel();
    await _planDataStreamController.close();
  }

  @override
  String get id => day.toIso8601String();

  Future<bool> updatePlanData(ItineraryPlanData planData) async {
    var didUpdate = false;
    _shouldListenToPlanDataChanges = false;
    _planDataSubscription.pause();
    var leafRepositoryItem =
        ItineraryPlanDataModelImplementation.fromModelFacade(planData);
    var planDataBeforeUpdate = _planData.facade;
    didUpdate = await _planData.documentReference
        .set(leafRepositoryItem.toJson(), SetOptions(merge: false))
        .then((value) {
      return true;
    }).catchError((error, stackTrace) {
      return false;
    });
    _planDataSubscription.resume();
    _shouldListenToPlanDataChanges = true;
    if (didUpdate) {
      _planData = leafRepositoryItem;
      _planDataStreamController.add(CollectionItemChangeMetadata(
          CollectionItemChangeSet(planDataBeforeUpdate, _planData.facade),
          isFromExplicitAction: true));
    }
    return didUpdate;
  }

  ItineraryFacade clone() {
    return ItineraryModelImplementation._(
      tripId: tripId,
      day: day,
      planData: ItineraryPlanDataModelImplementation.fromModelFacade(
          _planData.facade),
      transits: _transits.map((e) => e.clone()).toList(),
      checkInLodging: checkInLodging?.clone(),
      checkOutLodging: checkOutLodging?.clone(),
      fullDayLodging: fullDayLodging?.clone(),
    );
  }

  @override
  void addTransit(TransitFacade transitToAdd) {
    if (!_transits.any((transit) => transit.id == transitToAdd.id)) {
      _transits.add(transitToAdd);
    }
  }

  @override
  void removeTransit(TransitFacade transit) {
    _transits.removeWhere((t) => t.id == transit.id);
  }

  @override
  List<Object?> get props => [tripId, day, planData, transits, checkInLodging];

  @override
  bool? get stringify => true;

  @override
  bool validate() {
    return planData.validate() &&
        !(fullDayLodging != null &&
            (checkInLodging != null || checkOutLodging != null));
  }

  void _listenToPlanDataChanges() {
    final planDataId = day.itineraryDateFormat;
    final planDataDocRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripId)
        .collection(FirestoreCollections.itineraryDataCollectionName)
        .doc(planDataId);

    var hasHitFirstTime = false;
    _planDataSubscription = planDataDocRef.snapshots().listen((snapshot) {
      if (!_shouldListenToPlanDataChanges) {
        return;
      }
      if (!hasHitFirstTime) {
        hasHitFirstTime = true;
        return;
      }
      ItineraryPlanDataModelImplementation planDataModelImplementation;
      if (snapshot.exists) {
        planDataModelImplementation =
            ItineraryPlanDataModelImplementation.fromDocumentSnapshot(
          tripId: tripId,
          documentSnapshot: snapshot,
          day: day,
        );
      } else {
        planDataModelImplementation =
            ItineraryPlanDataModelImplementation.empty(
          tripId: tripId,
          day: day,
        );
      }
      var planDataBeforeUpdate = _planData.facade;
      _planData = planDataModelImplementation;
      _planDataStreamController.add(CollectionItemChangeMetadata(
          CollectionItemChangeSet(planDataBeforeUpdate, _planData.facade),
          isFromExplicitAction: false));
    });
  }

  ItineraryModelImplementation._({
    required this.tripId,
    required this.day,
    required ItineraryPlanDataModelImplementation planData,
    required List<TransitFacade> transits,
    LodgingFacade? checkInLodging,
    LodgingFacade? checkOutLodging,
    LodgingFacade? fullDayLodging,
  })  : _planData = planData,
        _transits = transits,
        _checkInLodging = checkInLodging,
        _checkOutLodging = checkOutLodging,
        _fullDayLodging = fullDayLodging {
    _listenToPlanDataChanges();
  }
}
