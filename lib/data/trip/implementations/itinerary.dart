import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/implementations/plan_data/plan_data_model_implementation.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';
import 'package:wandrr/data/trip/models/transit.dart';

import 'collection_names.dart';

class ItineraryModelImplementation implements ItineraryModelEventHandler {
  @override
  final String tripId;

  @override
  final DateTime day;

  @override
  final List<TransitFacade> transits;

  @override
  final LodgingFacade? checkinLodging;

  @override
  final LodgingFacade? checkoutLodging;

  @override
  final LodgingFacade? fullDayLodging;

  @override
  Stream<CollectionItemChangeMetadata<PlanDataFacade>> get planDataStream =>
      _planDataStreamController.stream;
  final StreamController<CollectionItemChangeMetadata<PlanDataFacade>>
      _planDataStreamController = StreamController.broadcast();

  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      _planDataSubscription;

  @override
  PlanDataFacade get planData => _planData;
  PlanDataModelImplementation _planData;

  var _shouldListenToPlanDataChanges = true;

  static Future<ItineraryModelImplementation> createInstance(
      {required String tripId,
      required DateTime day,
      required Iterable<TransitFacade> transits,
      required LodgingFacade? checkinLodging,
      required LodgingFacade? checkoutLodging,
      required LodgingFacade? fullDayLodging,
      PlanDataModelImplementation? planData}) async {
    final planDataId = day.itineraryDateFormat;
    final planDataDocRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripId)
        .collection(FirestoreCollections.itineraryDataCollectionName)
        .doc(planDataId);
    PlanDataModelImplementation planDataModelImplementation;
    if (planData != null) {
      planDataModelImplementation = planData;
    } else {
      var planDataSnapshot = await planDataDocRef.get();
      if (planDataSnapshot.exists) {
        planDataModelImplementation =
            PlanDataModelImplementation.fromDocumentSnapshot(
          tripId: tripId,
          documentSnapshot: planDataSnapshot,
          collectionName: FirestoreCollections.itineraryDataCollectionName,
        );
      } else {
        planDataModelImplementation = PlanDataModelImplementation.empty(
            tripId: tripId,
            id: planDataId,
            collectionName: FirestoreCollections.itineraryDataCollectionName);
      }
    }

    return ItineraryModelImplementation._(
      tripId: tripId,
      day: day,
      planData: planDataModelImplementation,
      transits: transits.toList(),
      checkinLodging: checkinLodging,
      checkoutLodging: checkoutLodging,
      fullDayLodging: fullDayLodging,
    );
  }

  @override
  Future dispose() async {
    await _planDataSubscription.cancel();
    await _planDataStreamController.close();
  }

  void _listenToPlanDataChanges() {
    final planDataId = day.itineraryDateFormat;
    final planDataDocRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripId)
        .collection(FirestoreCollections.itineraryDataCollectionName)
        .doc(planDataId);

    var isFirstEvent = true;
    _planDataSubscription = planDataDocRef.snapshots().listen((snapshot) {
      if (!_shouldListenToPlanDataChanges) {
        return;
      }
      if (isFirstEvent) {
        isFirstEvent = false;
        return;
      }
      PlanDataModelImplementation planDataModelImplementation;
      if (snapshot.exists) {
        planDataModelImplementation =
            PlanDataModelImplementation.fromDocumentSnapshot(
          tripId: tripId,
          documentSnapshot: snapshot,
          collectionName: FirestoreCollections.itineraryDataCollectionName,
        );
      } else {
        planDataModelImplementation = PlanDataModelImplementation.empty(
            tripId: tripId,
            id: planDataId,
            collectionName: FirestoreCollections.itineraryDataCollectionName);
      }
      _planData = planDataModelImplementation;
      _planDataStreamController.add(CollectionItemChangeMetadata(
          _planData.facade,
          isFromExplicitAction: true));
    });
  }

  @override
  String get id => day.toIso8601String();

  @override
  Future<bool> updatePlanData(PlanDataFacade planData) async {
    var didUpdate = false;
    _shouldListenToPlanDataChanges = false;
    _planDataSubscription.pause();
    var leafRepositoryItem = PlanDataModelImplementation.fromModelFacade(
        planDataFacade: planData,
        collectionName: FirestoreCollections.itineraryDataCollectionName);
    didUpdate = await _planData.documentReference
        .set(leafRepositoryItem.toJson(), SetOptions(merge: true))
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
          _planData.facade,
          isFromExplicitAction: false));
    }
    return didUpdate;
  }

  @override
  ItineraryFacade clone() {
    return ItineraryModelImplementation._(
      tripId: tripId,
      day: day,
      planData: PlanDataModelImplementation.fromModelFacade(
          planDataFacade: _planData,
          collectionName: FirestoreCollections.itineraryDataCollectionName),
      transits: transits.map((e) => e.clone()).toList(),
      checkinLodging: checkinLodging?.clone(),
      checkoutLodging: checkoutLodging?.clone(),
      fullDayLodging: fullDayLodging?.clone(),
    );
  }

  @override
  void addTransit(TransitFacade transitToAdd) {
    if (!transits.any((transit) => transit.id == transitToAdd.id)) {
      transits.add(transitToAdd);
    }
  }

  @override
  void removeTransit(TransitFacade transit) {
    transits.removeWhere((transit) => transit.id == transit.id);
  }

  @override
  set checkInLodging(LodgingFacade? lodging) {
    checkInLodging = lodging;
    fullDayLodging = null;
  }

  @override
  set checkoutLodging(LodgingFacade? lodging) {
    checkoutLodging = lodging;
    fullDayLodging = null;
  }

  @override
  set fullDayLodging(LodgingFacade? lodging) {
    fullDayLodging = lodging;
    checkInLodging = null;
    checkoutLodging = null;
  }

  ItineraryModelImplementation._({
    required this.tripId,
    required this.day,
    required PlanDataModelImplementation planData,
    required this.transits,
    this.checkinLodging,
    this.checkoutLodging,
    this.fullDayLodging,
  }) : _planData = planData {
    _listenToPlanDataChanges();
  }

  @override
  List<Object?> get props => [tripId, day, planData, transits, checkinLodging];

  @override
  bool? get stringify => true;

  @override
  bool validate() {
    return planData.validate() &&
        !(fullDayLodging != null &&
            (checkinLodging != null || checkoutLodging != null));
  }
}
