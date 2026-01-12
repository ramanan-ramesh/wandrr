import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/store/implementations/firestore_model_collection.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary/itinerary_collection.dart';
import 'package:wandrr/data/trip/implementations/trip_metadata_update_executor.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';
import 'package:wandrr/l10n/app_localizations.dart';

import 'budgeting/expense.dart';
import 'lodging.dart';
import 'transit.dart';
import 'trip_metadata.dart';

class TripDataModelImplementation extends TripDataModelEventHandler {
  static Future<TripDataModelImplementation> createInstance(
      TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository,
      AppLocalizations appLocalizations,
      String currentUserName,
      Iterable<CurrencyData> supportedCurrencies) async {
    var tripMetadataModelImplementation =
        TripMetadataModelImplementation.fromModelFacade(
            tripMetadataModelFacade: tripMetadata);

    var tripDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripMetadata.id);

    var transitModelCollection = await FirestoreModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.transitCollectionName),
        (documentSnapshot) => TransitImplementation.fromDocumentSnapshot(
            tripMetadata.id!, documentSnapshot),
        (transitModelFacade) => TransitImplementation.fromModelFacade(
            transitModelFacade: transitModelFacade));
    var lodgingModelCollection = await FirestoreModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.lodgingCollectionName),
        (documentSnapshot) => LodgingModelImplementation.fromDocumentSnapshot(
            tripId: tripMetadata.id!, documentSnapshot: documentSnapshot),
        (lodgingModelFacade) => LodgingModelImplementation.fromModelFacade(
            lodgingModelFacade: lodgingModelFacade));
    var expenseModelCollection = await FirestoreModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.expenseCollectionName),
        (documentSnapshot) =>
            StandaloneExpenseModelImplementation.fromDocumentSnapshot(
                tripId: tripMetadata.id!, documentSnapshot: documentSnapshot),
        (expenseModelFacade) =>
            StandaloneExpenseModelImplementation.fromModelFacade(
                expenseModelFacade: expenseModelFacade));

    var itineraries = await ItineraryCollection.createInstance(
        transitCollection: transitModelCollection,
        lodgingCollection: lodgingModelCollection,
        tripMetadata: tripMetadata);

    var budgetingModule = await BudgetingModule.createInstance(
        transitModelCollection,
        lodgingModelCollection,
        expenseModelCollection,
        apiServicesRepository.currencyConverter,
        tripMetadataModelImplementation.budget.currency,
        supportedCurrencies,
        tripMetadataModelImplementation.contributors,
        currentUserName,
        itineraries);

    return TripDataModelImplementation._(
        tripMetadataModelImplementation,
        transitModelCollection,
        lodgingModelCollection,
        expenseModelCollection,
        itineraries,
        apiServicesRepository.currencyConverter,
        budgetingModule,
        appLocalizations);
  }

  @override
  final ModelCollectionModifier<TransitFacade> transitCollection;

  @override
  final ModelCollectionModifier<LodgingFacade> lodgingCollection;

  @override
  final ModelCollectionModifier<StandaloneExpense> expenseCollection;

  @override
  final ItineraryCollection itineraryCollection;

  ApiService<(Money, String), double?> currencyConverter;

  @override
  TripMetadataFacade get tripMetadata =>
      _tripMetadataModelImplementation.clone();
  final TripMetadataModelImplementation _tripMetadataModelImplementation;

  @override
  final BudgetingModuleEventHandler budgetingModule;

  late final TripMetadataUpdateExecutor _tripMetadataUpdateExecutor;

  @override
  Future<void> applyUpdatePlan(TripMetadataUpdatePlan plan) async {
    // Execute the update plan
    await _tripMetadataUpdateExecutor.execute(plan);

    // Update local metadata copy
    _tripMetadataModelImplementation.copyWith(plan.newMetadata);
  }

  @override
  Future updateTripMetadata(TripMetadataFacade tripMetadata) async {
    // This method now only updates the local metadata copy
    // For full rebalancing, use applyUpdatePlan() with a TripMetadataUpdatePlan
    var didCurrencyChange = _tripMetadataModelImplementation.budget.currency !=
        tripMetadata.budget.currency;

    if (didCurrencyChange) {
      budgetingModule.updateCurrency(tripMetadata.budget.currency);
    }

    _tripMetadataModelImplementation.copyWith(tripMetadata);
  }

  @override
  Iterable<TransitOptionMetadata> get transitOptionMetadatas =>
      _transitOptionMetadatas;
  final Iterable<TransitOptionMetadata> _transitOptionMetadatas;

  @override
  Future dispose() async {
    await transitCollection.dispose();
    await lodgingCollection.dispose();
    await expenseCollection.dispose();
    await itineraryCollection.dispose();
    await budgetingModule.dispose();
  }

  static Iterable<TransitOptionMetadata> _initializeIconsAndTransitOptions(
      AppLocalizations appLocalizations) {
    var transitOptionMetadataList = <TransitOptionMetadata>[];
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.publicTransport,
        icon: Icons.emoji_transportation_rounded,
        name: appLocalizations.publicTransit));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.flight,
        icon: Icons.flight_rounded,
        name: appLocalizations.flight));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.bus,
        icon: Icons.directions_bus_rounded,
        name: appLocalizations.bus));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.cruise,
        icon: Icons.kayaking_rounded,
        name: appLocalizations.cruise));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.ferry,
        icon: Icons.directions_ferry_outlined,
        name: appLocalizations.ferry));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.rentedVehicle,
        icon: Icons.car_rental_rounded,
        name: appLocalizations.carRental));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.train,
        icon: Icons.train_rounded,
        name: appLocalizations.train));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.vehicle,
        icon: Icons.bike_scooter_rounded,
        name: appLocalizations.personalVehicle));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.walk,
        icon: Icons.directions_walk_rounded,
        name: appLocalizations.walk));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.taxi,
        icon: Icons.local_taxi_rounded,
        name: appLocalizations.taxi));
    return transitOptionMetadataList;
  }

  TripDataModelImplementation._(
      TripMetadataModelImplementation tripMetadata,
      this.transitCollection,
      this.lodgingCollection,
      this.expenseCollection,
      this.itineraryCollection,
      this.currencyConverter,
      this.budgetingModule,
      AppLocalizations appLocalisations)
      : _tripMetadataModelImplementation = tripMetadata,
        _transitOptionMetadatas =
            _initializeIconsAndTransitOptions(appLocalisations) {
    _tripMetadataUpdateExecutor = TripMetadataUpdateExecutor(
      transitCollection: transitCollection,
      lodgingCollection: lodgingCollection,
      expenseCollection: expenseCollection,
      itineraryCollection: itineraryCollection,
      budgetingModule: budgetingModule,
    );
  }
}
