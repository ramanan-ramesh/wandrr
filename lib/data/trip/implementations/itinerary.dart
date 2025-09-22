import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/models/itinerary.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';
import 'package:wandrr/data/trip/models/transit.dart';

import 'plan_data/plan_data_model_implementation.dart';

class ItineraryModelImplementation extends ItineraryModelEventHandler {
  final String tripId;
  final DateTime day;

  ItineraryModelImplementation(
      this.tripId,
      this.day,
      PlanDataModelImplementation planDataModelImplementation,
      Iterable<TransitFacade> transits,
      {LodgingFacade? checkinLodging,
      LodgingFacade? checkoutLodging,
      LodgingFacade? fullDayLodging})
      : _planDataModelImplementation = planDataModelImplementation,
        _transits = transits.toList(),
        _checkinLodging = checkinLodging,
        _checkoutLodging = checkoutLodging,
        _fullDayLodging = fullDayLodging;

  static Future<ItineraryModelImplementation> createInstance(
      {required String tripId,
      required DateTime day,
      required Iterable<TransitFacade> transits,
      LodgingFacade? checkinLodging,
      LodgingFacade? checkoutLodging,
      LodgingFacade? fullDayLodging}) async {
    var itineraryDataDocumentId = _dateFormat.format(day);
    var itineraryDataCollection = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripId)
        .collection(FirestoreCollections.itineraryDataCollectionName)
        .doc(itineraryDataDocumentId);

    var itineraryDocumentReference = await itineraryDataCollection.get();

    var planDataModelImplementation = itineraryDocumentReference.exists
        ? PlanDataModelImplementation.fromDocumentSnapshot(
            tripId: tripId,
            documentSnapshot: itineraryDocumentReference,
            collectionName: FirestoreCollections.itineraryDataCollectionName)
        : PlanDataModelImplementation.empty(
            tripId: tripId,
            id: itineraryDataDocumentId,
            collectionName: FirestoreCollections.itineraryDataCollectionName);

    var itineraryModelImplementation = ItineraryModelImplementation(
        tripId, day, planDataModelImplementation, transits,
        checkinLodging: checkinLodging,
        checkoutLodging: checkoutLodging,
        fullDayLodging: fullDayLodging);

    return itineraryModelImplementation;
  }

  @override
  ItineraryFacade clone() {
    return ItineraryModelImplementation(
      tripId,
      day,
      _planDataModelImplementation.clone() as PlanDataModelImplementation,
      transits.map((transit) => transit.clone()).toList(),
      checkinLodging: _checkinLodging?.clone(),
      checkoutLodging: _checkoutLodging?.clone(),
      fullDayLodging: _fullDayLodging?.clone(),
    );
  }

  @override
  LodgingFacade? get checkoutLodging => _checkoutLodging?.clone();
  LodgingFacade? _checkoutLodging;

  @override
  LodgingFacade? get checkinLodging => _checkinLodging?.clone();
  LodgingFacade? _checkinLodging;

  @override
  LodgingFacade? get fullDayLodging => _fullDayLodging?.clone();
  LodgingFacade? _fullDayLodging;

  @override
  LeafRepositoryItem<PlanDataFacade> get planDataEventHandler =>
      _planDataModelImplementation;
  final PlanDataModelImplementation _planDataModelImplementation;

  @override
  PlanDataFacade get planData => _planDataModelImplementation;

  @override
  Iterable<TransitFacade> get transits => List.from(_transits);
  final List<TransitFacade> _transits;

  static final _dateFormat = DateFormat('ddMMyyyy');

  @override
  void addTransit(TransitFacade transitToAdd) {
    if (!_transits.any((transit) => transit.id == transitToAdd.id)) {
      _transits.add(transitToAdd);
    }
  }

  @override
  void removeTransit(TransitFacade transit) {
    _transits.removeWhere((transit) => transit.id == transit.id);
  }

  @override
  set checkInLodging(LodgingFacade? lodging) {
    _checkinLodging = lodging;
    _fullDayLodging = null;
  }

  @override
  set checkoutLodging(LodgingFacade? lodging) {
    _checkoutLodging = lodging;
    _fullDayLodging = null;
  }

  @override
  set fullDayLodging(LodgingFacade? lodging) {
    _fullDayLodging = lodging;
    _checkinLodging = null;
    _checkoutLodging = null;
  }
}
