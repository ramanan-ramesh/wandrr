import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/itinerary.dart';
import 'package:wandrr/contracts/lodging.dart';
import 'package:wandrr/contracts/plan_data.dart';
import 'package:wandrr/contracts/repository_pattern.dart';
import 'package:wandrr/contracts/transit.dart';

import 'plan_data_model_implementation.dart';

class ItineraryModelImplementation extends ItineraryModelEventHandler {
  @override
  LodgingModelFacade? get lodging => _lodging;
  LodgingModelFacade? _lodging;

  @override
  RepositoryPattern<PlanDataModelFacade> get planDataEventHandler =>
      _planDataModelImplementation;
  final PlanDataModelImplementation _planDataModelImplementation;

  @override
  PlanDataModelFacade get planData => _planDataModelImplementation;

  @override
  List<TransitModelFacade> get transits => List.from(_transits);
  List<TransitModelFacade> _transits;

  static final _dateFormat = DateFormat('ddMMyyyy');

  ItineraryModelImplementation(
      String tripId,
      DateTime day,
      PlanDataModelImplementation planDataModelImplementation,
      List<TransitModelFacade> transits,
      LodgingModelFacade? lodging)
      : _planDataModelImplementation = planDataModelImplementation,
        _transits = transits,
        _lodging = lodging,
        super(tripId, day);

  @override
  void addLodging(LodgingModelFacade lodging) {
    _lodging = lodging;
  }

  @override
  void addTransit(TransitModelFacade transitToAdd) {
    if (!_transits.any((transit) => transit.id == transitToAdd.id)) {
      _transits.add(transitToAdd);
    }
  }

  @override
  void removeLodging(LodgingModelFacade lodging) {
    _lodging = null;
  }

  @override
  void removeTransit(TransitModelFacade transit) {
    _transits.removeWhere((transit) => transit.id == transit.id);
  }

  static Future<ItineraryModelImplementation> createExistingInstanceAsync(
      {required String tripId,
      required DateTime day,
      required List<TransitModelFacade> transits,
      LodgingModelFacade? lodging}) async {
    var itineraryDataDocumentId = _dateFormat.format(day);
    var itineraryDataCollection = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(tripId)
        .collection(FirestoreCollections.itineraryDataCollection)
        .doc(itineraryDataDocumentId);

    var itineraryDocumentReference = await itineraryDataCollection.get();

    var planDataModelImplementation =
        PlanDataModelImplementation.fromDocumentSnapshot(
            tripId: tripId,
            documentSnapshot: itineraryDocumentReference,
            collectionName: FirestoreCollections.itineraryDataCollection);

    var itineraryModelImplementation = ItineraryModelImplementation(
        tripId, day, planDataModelImplementation, transits, lodging);

    return itineraryModelImplementation;
  }
}
