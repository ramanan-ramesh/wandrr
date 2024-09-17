import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/app_data/models/repository_pattern.dart';
import 'package:wandrr/trip_data/implementations/collection_names.dart';
import 'package:wandrr/trip_data/models/itinerary.dart';
import 'package:wandrr/trip_data/models/lodging.dart';
import 'package:wandrr/trip_data/models/plan_data.dart';
import 'package:wandrr/trip_data/models/transit.dart';

import 'plan_data_model_implementation.dart';

class ItineraryModelImplementation extends ItineraryModelEventHandler {
  @override
  LodgingFacade? get lodging => _lodging;
  LodgingFacade? _lodging;

  @override
  RepositoryPattern<PlanDataFacade> get planDataEventHandler =>
      _planDataModelImplementation;
  final PlanDataModelImplementation _planDataModelImplementation;

  @override
  PlanDataFacade get planData => _planDataModelImplementation;

  @override
  List<TransitFacade> get transits => List.from(_transits);
  final List<TransitFacade> _transits;

  static final _dateFormat = DateFormat('ddMMyyyy');

  ItineraryModelImplementation(
      String tripId,
      DateTime day,
      PlanDataModelImplementation planDataModelImplementation,
      List<TransitFacade> transits,
      LodgingFacade? lodging)
      : _planDataModelImplementation = planDataModelImplementation,
        _transits = transits,
        _lodging = lodging,
        super(tripId, day);

  @override
  void addLodging(LodgingFacade lodging) {
    _lodging = lodging;
  }

  @override
  void addTransit(TransitFacade transitToAdd) {
    if (!_transits.any((transit) => transit.id == transitToAdd.id)) {
      _transits.add(transitToAdd);
    }
  }

  @override
  void removeLodging(LodgingFacade lodging) {
    _lodging = null;
  }

  @override
  void removeTransit(TransitFacade transit) {
    _transits.removeWhere((transit) => transit.id == transit.id);
  }

  static Future<ItineraryModelImplementation> createExistingInstanceAsync(
      {required String tripId,
      required DateTime day,
      required List<TransitFacade> transits,
      LodgingFacade? lodging}) async {
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
        tripId, day, planDataModelImplementation, transits, lodging);

    return itineraryModelImplementation;
  }
}
