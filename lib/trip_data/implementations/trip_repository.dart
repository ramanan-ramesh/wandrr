import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/api_services/models/currency_converter.dart';
import 'package:wandrr/app_data/implementations/model_collection_implementation.dart';
import 'package:wandrr/app_data/models/model_collection_facade.dart';
import 'package:wandrr/trip_data/implementations/collection_names.dart';
import 'package:wandrr/trip_data/implementations/trip_metadata.dart';
import 'package:wandrr/trip_data/models/trip_data.dart';
import 'package:wandrr/trip_data/models/trip_metadata.dart';
import 'package:wandrr/trip_data/models/trip_repository.dart';

import 'trip_data.dart';

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

  CurrencyConverterService currencyConverter;

  final AppLocalizations _appLocalizations;

  TripRepositoryImplementation._(this._tripMetadataModelCollection,
      this.currencyConverter, this._appLocalizations) {
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
          .collection(FirestoreCollections.tripCollectionName)
          .doc(deletedTripId)
          .delete();
    });
  }

  late StreamSubscription _tripMetadataUpdatedEventSubscription;
  late StreamSubscription _tripMetadataDeletedEventSubscription;

  static Future<TripRepositoryImplementation> createInstanceAsync(
      {required String userName,
      required CurrencyConverterService currencyConverter,
      required AppLocalizations appLocalizations}) async {
    var tripsCollectionReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripMetadataCollectionName);

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
        tripMetadataModelCollection, currencyConverter, appLocalizations);
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
        tripMetadata, currencyConverter, _appLocalizations);
  }

  @override
  Future dispose() async {
    await _tripMetadataUpdatedEventSubscription.cancel();
    await _tripMetadataDeletedEventSubscription.cancel();
  }
}
