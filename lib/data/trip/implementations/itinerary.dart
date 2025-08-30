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
  ItineraryModelImplementation(
      String tripId,
      DateTime day,
      PlanDataModelImplementation planDataModelImplementation,
      List<TransitFacade> transits,
      {LodgingFacade? checkinLodging,
      LodgingFacade? checkoutLodging,
      LodgingFacade? fullDayLodging})
      : _planDataModelImplementation = planDataModelImplementation,
        _transits = transits,
        _checkinLodging = checkinLodging,
        _checkoutLodging = checkoutLodging,
        _fullDayLodging = fullDayLodging,
        super(tripId, day);

  static Future<ItineraryModelImplementation> createInstance(
      {required String tripId,
      required DateTime day,
      required List<TransitFacade> transits,
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

    var planDataModelImplementation =
        PlanDataModelImplementation.fromDocumentSnapshot(
            tripId: tripId,
            documentSnapshot: itineraryDocumentReference,
            collectionName: FirestoreCollections.itineraryDataCollectionName);

    var itineraryModelImplementation = ItineraryModelImplementation(
        tripId, day, planDataModelImplementation, transits,
        checkinLodging: checkinLodging,
        checkoutLodging: checkoutLodging,
        fullDayLodging: fullDayLodging);

    return itineraryModelImplementation;
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
  List<TransitFacade> get transits => List.from(_transits);
  final List<TransitFacade> _transits;

  static final _dateFormat = DateFormat('ddMMyyyy');

  @override
  void setCheckinLodging(LodgingFacade? lodging) {
    _checkinLodging = lodging;
    _fullDayLodging = null;
  }

  @override
  void setCheckoutLodging(LodgingFacade? lodging) {
    _checkoutLodging = lodging;
    _fullDayLodging = null;
  }

  @override
  void setFullDayLodging(LodgingFacade? lodging) {
    _fullDayLodging = lodging;
    _checkinLodging = null;
    _checkoutLodging = null;
  }

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
}
