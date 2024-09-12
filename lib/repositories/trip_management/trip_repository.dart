import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/database_connectors/model_collection_facade.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_entity_facades/trip_metadata.dart';
import 'package:wandrr/contracts/trip_repository.dart';
import 'package:wandrr/repositories/api_services/currency_converter.dart';
import 'package:wandrr/repositories/model_collection_implementation.dart';
import 'package:wandrr/repositories/trip_management/implementations/trip_metadata.dart';

import 'implementations/trip_data.dart';

class TripRepositoryImplementation implements TripRepositoryEventHandler {
  static const _contributorsField = 'contributors';

  @override
  List<TripMetadataFacade> get tripMetadatas =>
      List.from(_tripMetadataModelCollection.collectionItems
          .cast<TripMetadataFacade>()
          .map<TripMetadataFacade>((facade) => facade.clone()));

  @override
  ModelCollectionFacade<TripMetadataFacade> get tripMetadataModelCollection =>
      _tripMetadataModelCollection;
  final ModelCollectionFacade<TripMetadataFacade> _tripMetadataModelCollection;

  @override
  TripDataFacade? get activeTrip => _activeTrip;
  TripDataModelImplementation? _activeTrip;

  @override
  TripDataModelEventHandler? get activeTripEventHandler => _activeTrip;

  CurrencyConverter currencyConverter;

  TripRepositoryImplementation._(
      this._tripMetadataModelCollection, this.currencyConverter) {
    _tripMetadataUpdatedEventSubscription =
        tripMetadataModelCollection.onDocumentUpdated.listen((eventData) async {
      if (_activeTrip == null) {
        return;
      }
      await _activeTrip!
          .updateTripMetadata(eventData.modifiedCollectionItem.afterUpdate);
    });
    _tripMetadataDeletedEventSubscription = _tripMetadataModelCollection
        .onDocumentDeleted
        .listen((eventData) async {
      var deletedTripId = eventData.modifiedCollectionItem.id;
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.tripsCollection)
          .doc(deletedTripId)
          .delete();
    });
  }

  late StreamSubscription _tripMetadataUpdatedEventSubscription;
  late StreamSubscription _tripMetadataDeletedEventSubscription;

  static Future<TripRepositoryImplementation> createInstanceAsync(
      {required String userName,
      required CurrencyConverter currencyConverter}) async {
    var tripsCollectionReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsMetadataCollection);

    var tripMetadataModelCollection =
        await ModelCollectionImplementation.createInstance(
            tripsCollectionReference,
            (snapshot) =>
                TripMetadataModelImplementation.fromDocumentSnapshot(snapshot),
            (tripMetadataModuleFacade) =>
                TripMetadataModelImplementation.fromModelFacade(
                    tripMetadataModelFacade: tripMetadataModuleFacade),
            query: tripsCollectionReference.where(_contributorsField,
                arrayContains: userName));

    return TripRepositoryImplementation._(
        tripMetadataModelCollection, currencyConverter);
  }

  @override
  Future loadAndActivateTrip(TripMetadataFacade? tripMetadata) async {
    if (tripMetadata == null) {
      await _activeTrip?.dispose();
      _activeTrip = null;
      return;
    }

    await _activeTrip?.dispose();
    _activeTrip = await TripDataModelImplementation.createExistingInstanceAsync(
        tripMetadata, currencyConverter);
  }

  @override
  Future dispose() async {
    await _tripMetadataUpdatedEventSubscription.cancel();
    await _tripMetadataDeletedEventSubscription.cancel();
  }
}
