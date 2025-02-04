import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/data/app/implementations/collection_model_implementation.dart';
import 'package:wandrr/data/app/models/collection_model_facade.dart';
import 'package:wandrr/data/app/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/budgeting_module.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary_model_collection.dart';
import 'package:wandrr/data/trip/models/api_services/currency_converter.dart';
import 'package:wandrr/data/trip/models/budgeting_module.dart';
import 'package:wandrr/data/trip/models/expense.dart';
import 'package:wandrr/data/trip/models/itinerary.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/plan_data.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/extensions.dart';

import 'expense.dart';
import 'lodging.dart';
import 'plan_data_model_implementation.dart';
import 'transit.dart';
import 'trip_metadata.dart';

class TripDataModelImplementation extends TripDataModelEventHandler {
  final _subscriptions = <StreamSubscription>[];

  TripDataModelImplementation(
      TripMetadataModelImplementation tripMetadata,
      CollectionModelImplementation<TransitFacade> transitModelCollection,
      CollectionModelImplementation<LodgingFacade> lodgingModelCollection,
      CollectionModelImplementation<ExpenseFacade> expenseModelCollection,
      CollectionModelImplementation<PlanDataFacade> planDataModelCollection,
      ItineraryModelCollection itineraryModelCollection,
      this.currencyConverter,
      BudgetingModuleEventHandler budgetingModuleEventHandler,
      AppLocalizations appLocalisations)
      : _transitModelCollection = transitModelCollection,
        _lodgingModelCollection = lodgingModelCollection,
        _expenseModelCollection = expenseModelCollection,
        _planDataModelCollection = planDataModelCollection,
        _tripMetadataModelImplementation = tripMetadata,
        _budgetingModuleEventHandler = budgetingModuleEventHandler,
        _itineraryModelCollection = itineraryModelCollection,
        _transitOptionMetadatas =
            _initializeIconsAndTransitOptions(appLocalisations);

  @override
  List<TransitFacade> get transits =>
      List.from(_transitModelCollection.collectionItems
          .cast<TransitFacade>()
          .map((facade) => facade.clone()));

  @override
  CollectionModelFacade<TransitFacade> get transitsModelCollection =>
      _transitModelCollection;
  final CollectionModelImplementation<TransitFacade> _transitModelCollection;

  @override
  CollectionModelFacade<LodgingFacade> get lodgingModelCollection =>
      _lodgingModelCollection;
  final CollectionModelImplementation<LodgingFacade> _lodgingModelCollection;

  @override
  CollectionModelFacade<ExpenseFacade> get expenseModelCollection =>
      _expenseModelCollection;
  final CollectionModelImplementation<ExpenseFacade> _expenseModelCollection;

  @override
  List<ExpenseFacade> get expenses =>
      List.from(_expenseModelCollection.collectionItems
          .cast<ExpenseFacade>()
          .map((facade) => facade.clone()));

  @override
  List<LodgingFacade> get lodgings =>
      List.from(_lodgingModelCollection.collectionItems
          .cast<LodgingFacade>()
          .map((facade) => facade.clone()));

  @override
  List<PlanDataFacade> get planDataList =>
      List.from(planDataModelCollection.collectionItems
          .cast<PlanDataFacade>()
          .map((facade) => facade.clone()));

  @override
  CollectionModelFacade<PlanDataFacade> get planDataModelCollection =>
      _planDataModelCollection;
  final CollectionModelFacade<PlanDataFacade> _planDataModelCollection;

  @override
  ItineraryFacadeCollection get itineraryModelCollection =>
      _itineraryModelCollection;

  @override
  ItineraryFacadeCollectionEventHandler
      get itineraryModelCollectionEventHandler => _itineraryModelCollection;
  final ItineraryModelCollection _itineraryModelCollection;

  CurrencyConverterService currencyConverter;

  @override
  TripMetadataFacade get tripMetadata =>
      _tripMetadataModelImplementation.clone();

  @override
  LeafRepositoryItem<TripMetadataFacade> get tripMetadataModelEventHandler =>
      _tripMetadataModelImplementation;
  final TripMetadataModelImplementation _tripMetadataModelImplementation;

  @override
  BudgetingModuleFacade get budgetingModuleFacade =>
      _budgetingModuleEventHandler;
  final BudgetingModuleEventHandler _budgetingModuleEventHandler;

  static Future<TripDataModelImplementation> createExistingInstanceAsync(
      TripMetadataFacade tripMetadata,
      CurrencyConverterService currencyConverter,
      AppLocalizations appLocalizations,
      String currentUserName) async {
    var tripMetadataModelImplementation =
        TripMetadataModelImplementation.fromModelFacade(
            tripMetadataModelFacade: tripMetadata);

    var tripDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripMetadata.id);

    var transitModelCollection =
        await CollectionModelImplementation.createInstance(
            tripDocumentReference.collection(
                FirestoreCollections.transitCollectionName),
            (documentSnapshot) =>
                TransitImplementation.fromDocumentSnapshot(
                    tripMetadata.id!, documentSnapshot),
            (transitModelFacade) => TransitImplementation.fromModelFacade(
                transitModelFacade: transitModelFacade));
    var lodgingModelCollection =
        await CollectionModelImplementation.createInstance(
            tripDocumentReference.collection(
                FirestoreCollections.lodgingCollectionName),
            (documentSnapshot) =>
                LodgingModelImplementation.fromDocumentSnapshot(
                    tripId: tripMetadata.id!,
                    documentSnapshot: documentSnapshot),
            (lodgingModelFacade) => LodgingModelImplementation.fromModelFacade(
                lodgingModelFacade: lodgingModelFacade));
    var expenseModelCollection =
        await CollectionModelImplementation.createInstance(
            tripDocumentReference.collection(
                FirestoreCollections.expenseCollectionName),
            (documentSnapshot) =>
                ExpenseModelImplementation.fromDocumentSnapshot(
                    tripId: tripMetadata.id!,
                    documentSnapshot: documentSnapshot),
            (expenseModelFacade) => ExpenseModelImplementation.fromModelFacade(
                expenseModelFacade: expenseModelFacade));
    var planDataModelCollection =
        await CollectionModelImplementation.createInstance(
            tripDocumentReference
                .collection(FirestoreCollections.planDataCollectionName),
            (documentSnapshot) =>
                PlanDataModelImplementation.fromDocumentSnapshot(
                    tripId: tripMetadata.id!,
                    documentSnapshot: documentSnapshot),
            (planDataModelFacade) =>
                PlanDataModelImplementation.fromModelFacade(
                    planDataFacade: planDataModelFacade));

    var itineraries =
        await ItineraryModelCollection.createItineraryModelCollection(
            transitModelCollection, lodgingModelCollection, tripMetadata);

    var budgetingModuleFacade = await BudgetingModule.createInstance(
        transitModelCollection,
        lodgingModelCollection,
        expenseModelCollection,
        currencyConverter,
        tripMetadataModelImplementation.budget.currency,
        tripMetadataModelImplementation.contributors,
        currentUserName);

    return TripDataModelImplementation(
        tripMetadataModelImplementation,
        transitModelCollection,
        lodgingModelCollection,
        expenseModelCollection,
        planDataModelCollection,
        itineraries,
        currencyConverter,
        budgetingModuleFacade,
        appLocalizations);
  }

  @override
  Future dispose() async {
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _transitModelCollection.dispose();
    await _lodgingModelCollection.dispose();
    await _planDataModelCollection.dispose();
    await _expenseModelCollection.dispose();
    await _itineraryModelCollection.dispose();
    await _budgetingModuleEventHandler.dispose();
  }

  @override
  Future updateTripMetadata(
      LeafRepositoryItem<TripMetadataFacade>
          tripMetadataRepositoryPattern) async {
    var updatedTripMetadata = tripMetadataRepositoryPattern.facade;
    var currentContributors = _tripMetadataModelImplementation.contributors;
    var didContributorsChange = !(ListEquality()
        .equals(currentContributors, updatedTripMetadata.contributors));
    var didCurrencyChange = _tripMetadataModelImplementation.budget.currency !=
        updatedTripMetadata.budget.currency;

    if (didCurrencyChange) {
      _budgetingModuleEventHandler
          .updateCurrency(updatedTripMetadata.budget.currency);
    }

    var haveTripDatesChanged = !_tripMetadataModelImplementation.startDate!
            .isOnSameDayAs(updatedTripMetadata.startDate!) ||
        !_tripMetadataModelImplementation.endDate!
            .isOnSameDayAs(updatedTripMetadata.endDate!);
    var deletedLodgings = <LodgingFacade>[];
    var deletedTransits = <TransitFacade>[];
    if (haveTripDatesChanged) {
      await _itineraryModelCollection.updateTripDays(
          updatedTripMetadata.startDate!, updatedTripMetadata.endDate!);
      Set<DateTime> oldDates = _createDateRange(
          _tripMetadataModelImplementation.startDate!,
          _tripMetadataModelImplementation.endDate!);
      Set<DateTime> newDates = _createDateRange(
          updatedTripMetadata.startDate!, updatedTripMetadata.endDate!);
      Set<DateTime> datesToRemove = oldDates.difference(newDates);

      var writeBatch = FirebaseFirestore.instance.batch();
      deletedTransits.addAll(_updateTripEntityListOnDatesChanged<TransitFacade>(
          datesToRemove,
          _transitModelCollection,
          (dateTime, transit) =>
              transit.departureDateTime!.isOnSameDayAs(dateTime) ||
              transit.arrivalDateTime!.isOnSameDayAs(dateTime),
          writeBatch));

      deletedLodgings.addAll(_updateTripEntityListOnDatesChanged<LodgingFacade>(
          datesToRemove,
          _lodgingModelCollection,
          (dateTime, lodging) =>
              lodging.checkinDateTime!.isOnSameDayAs(dateTime) ||
              lodging.checkoutDateTime!.isOnSameDayAs(dateTime),
          writeBatch));
      await writeBatch.commit();
    }

    if (didContributorsChange) {
      await _budgetingModuleEventHandler
          .tryBalanceExpensesOnContributorsChanged(
              updatedTripMetadata.contributors);
    }

    var shouldRecalculateTotalExpense =
        haveTripDatesChanged || didContributorsChange || didCurrencyChange;
    if (shouldRecalculateTotalExpense) {
      _budgetingModuleEventHandler.recalculateTotalExpenditure(
          deletedTransits: deletedTransits, deletedLodgings: deletedLodgings);
    }
    _tripMetadataModelImplementation.copyWith(updatedTripMetadata);
  }

  @override
  Iterable<TransitOptionMetadata> get transitOptionMetadatas =>
      _transitOptionMetadatas;
  Iterable<TransitOptionMetadata> _transitOptionMetadatas;

  Iterable<T> _updateTripEntityListOnDatesChanged<T>(
      Set<DateTime> removedDates,
      CollectionModelImplementation<T> modelCollection,
      bool Function(DateTime, T) itemsFilter,
      WriteBatch writeBatch) sync* {
    var updatedItems = <T>[];
    var currentCollectionItems = modelCollection.collectionItems;
    for (var collectionItem in currentCollectionItems) {
      var item = collectionItem.facade;
      if (!removedDates.any((removedDate) => itemsFilter(removedDate, item))) {
        updatedItems.add(item);
      } else {
        writeBatch.delete(collectionItem.documentReference);
        yield item;
      }
    }
    // modelCollection.tryUpdateList(writeBatch, updatedItems);
  }

  static Iterable<TransitOptionMetadata> _initializeIconsAndTransitOptions(
      AppLocalizations appLocalizations) {
    var transitOptionMetadataList = <TransitOptionMetadata>[];
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.PublicTransport,
        icon: Icons.emoji_transportation_rounded,
        name: appLocalizations.publicTransit));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Flight,
        icon: Icons.flight_rounded,
        name: appLocalizations.flight));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Bus,
        icon: Icons.directions_bus_rounded,
        name: appLocalizations.bus));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Cruise,
        icon: Icons.kayaking_rounded,
        name: appLocalizations.cruise));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Ferry,
        icon: Icons.directions_ferry_outlined,
        name: appLocalizations.ferry));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.RentedVehicle,
        icon: Icons.car_rental_rounded,
        name: appLocalizations.carRental));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Train,
        icon: Icons.train_rounded,
        name: appLocalizations.train));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Vehicle,
        icon: Icons.bike_scooter_rounded,
        name: appLocalizations.personalVehicle));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Walk,
        icon: Icons.directions_walk_rounded,
        name: appLocalizations.walk));
    return transitOptionMetadataList;
  }

  Set<DateTime> _createDateRange(DateTime startDate, DateTime endDate) {
    Set<DateTime> dateSet = {};
    for (DateTime date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(Duration(days: 1))) {
      dateSet.add(date);
    }
    return dateSet;
  }
}
