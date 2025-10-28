import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/data/store/implementations/firestore_model_collection.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/trip_metadata.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/app_localizations.dart';

import 'trip_data.dart';

class TripRepositoryImplementation implements TripRepositoryEventHandler {
  static const _contributorsField = 'contributors';

  AppLocalizations _appLocalizations;

  late final StreamSubscription _tripMetadataUpdatedEventSubscription;
  late final StreamSubscription _tripMetadataDeletedEventSubscription;

  static Future<TripRepositoryImplementation> createInstance(
      {required String userName,
      required AppLocalizations appLocalizations}) async {
    var tripsCollectionReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripMetadataCollectionName);

    var tripMetadataModelCollection =
        await FirestoreModelCollection.createInstance(
            tripsCollectionReference,
            TripMetadataModelImplementation.fromDocumentSnapshot,
            (tripMetadataModuleFacade) =>
                TripMetadataModelImplementation.fromModelFacade(
                    tripMetadataModelFacade: tripMetadataModuleFacade),
            query: tripsCollectionReference.where(_contributorsField,
                arrayContains: userName));

    final jsonString = await rootBundle.loadString(Assets.supportedCurrencies);
    final List<dynamic> jsonResponse = json.decode(jsonString);
    var currencyDataList =
        jsonResponse.map((json) => CurrencyData.fromJson(json)).toList();

    return TripRepositoryImplementation._(
      tripMetadataModelCollection,
      appLocalizations,
      userName,
      currencyDataList,
    );
  }

  @override
  final ModelCollectionModifier<TripMetadataFacade> tripMetadataCollection;

  @override
  TripDataModelImplementation? activeTrip;

  final String currentUserName;

  @override
  Future unloadActiveTrip() async {
    await activeTrip?.dispose();
    activeTrip = null;
  }

  @override
  Future loadTrip(TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository) async {
    await activeTrip?.dispose();
    activeTrip = await TripDataModelImplementation.createInstance(
        tripMetadata,
        apiServicesRepository,
        _appLocalizations,
        currentUserName,
        supportedCurrencies);
  }

  @override
  void updateLocalizations(AppLocalizations appLocalizations) {
    _appLocalizations = appLocalizations;
  }

  @override
  final Iterable<CurrencyData> supportedCurrencies;

  @override
  Future dispose() async {
    await _tripMetadataUpdatedEventSubscription.cancel();
    await _tripMetadataDeletedEventSubscription.cancel();
    await tripMetadataCollection.dispose();
    await activeTrip?.dispose();
    activeTrip = null;
  }

  TripRepositoryImplementation._(
    this.tripMetadataCollection,
    this._appLocalizations,
    this.currentUserName,
    this.supportedCurrencies,
  ) {
    _tripMetadataUpdatedEventSubscription =
        tripMetadataCollection.onDocumentUpdated.listen((eventData) async {
      if (activeTrip == null) {
        return;
      } else if (activeTrip!.tripMetadata.id !=
          eventData.modifiedCollectionItem.afterUpdate.id) {
        return;
      }
      await activeTrip!
          .updateTripMetadata(eventData.modifiedCollectionItem.afterUpdate);
    });
    _tripMetadataDeletedEventSubscription =
        tripMetadataCollection.onDocumentDeleted.listen((eventData) async {
      var tripId = eventData.modifiedCollectionItem.id;
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.tripCollectionName)
          .doc(tripId)
          .delete();
      if (tripId == activeTrip?.tripMetadata.id) {
        await unloadActiveTrip();
      }
    });
  }
}
