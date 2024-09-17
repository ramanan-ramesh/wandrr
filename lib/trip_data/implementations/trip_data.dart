import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/api_services/models/currency_converter.dart';
import 'package:wandrr/app_data/implementations/model_collection_implementation.dart';
import 'package:wandrr/app_data/models/model_collection_facade.dart';
import 'package:wandrr/app_data/models/repository_pattern.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/trip_data/implementations/collection_names.dart';
import 'package:wandrr/trip_data/implementations/itinerary_model_collection.dart';
import 'package:wandrr/trip_data/models/budgeting_module.dart';
import 'package:wandrr/trip_data/models/expense.dart';
import 'package:wandrr/trip_data/models/itinerary.dart';
import 'package:wandrr/trip_data/models/lodging.dart';
import 'package:wandrr/trip_data/models/plan_data.dart';
import 'package:wandrr/trip_data/models/transit.dart';
import 'package:wandrr/trip_data/models/trip_data.dart';
import 'package:wandrr/trip_data/models/trip_metadata.dart';

import 'expense.dart';
import 'lodging.dart';
import 'plan_data_model_implementation.dart';
import 'transit.dart';
import 'trip_metadata.dart';

class TripDataModelImplementation extends TripDataModelEventHandler {
  final _subscriptions = <StreamSubscription>[];

  TripDataModelImplementation(
      TripMetadataModelImplementation tripMetadata,
      ModelCollectionImplementation<TransitFacade> transitModelCollection,
      ModelCollectionImplementation<LodgingFacade> lodgingModelCollection,
      ModelCollectionImplementation<ExpenseFacade> expenseModelCollection,
      ModelCollectionImplementation<PlanDataFacade> planDataModelCollection,
      ItineraryModelCollection itineraryModelCollection,
      this.currencyConverter,
      BudgetingModuleEventHandler budgetingModuleEventHandler)
      : _transitModelCollection = transitModelCollection,
        _lodgingModelCollection = lodgingModelCollection,
        _expenseModelCollection = expenseModelCollection,
        _planDataModelCollection = planDataModelCollection,
        _tripMetadataModelImplementation = tripMetadata,
        _budgetingModuleEventHandler = budgetingModuleEventHandler,
        _itineraryModelCollection = itineraryModelCollection;

  @override
  List<TransitFacade> get transits =>
      List.from(_transitModelCollection.collectionItems
          .cast<TransitFacade>()
          .map((facade) => facade.clone()));

  @override
  ModelCollectionFacade<TransitFacade> get transitsModelCollection =>
      _transitModelCollection;
  final ModelCollectionImplementation<TransitFacade> _transitModelCollection;

  @override
  ModelCollectionFacade<LodgingFacade> get lodgingModelCollection =>
      _lodgingModelCollection;
  final ModelCollectionImplementation<LodgingFacade> _lodgingModelCollection;

  @override
  ModelCollectionFacade<ExpenseFacade> get expenseModelCollection =>
      _expenseModelCollection;
  final ModelCollectionImplementation<ExpenseFacade> _expenseModelCollection;

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
  ModelCollectionFacade<PlanDataFacade> get planDataModelCollection =>
      _planDataModelCollection;
  final ModelCollectionFacade<PlanDataFacade> _planDataModelCollection;

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
  RepositoryPattern<TripMetadataFacade> get tripMetadataModelEventHandler =>
      _tripMetadataModelImplementation;
  final TripMetadataModelImplementation _tripMetadataModelImplementation;

  @override
  BudgetingModuleFacade get budgetingModuleFacade =>
      _budgetingModuleEventHandler;
  final BudgetingModuleEventHandler _budgetingModuleEventHandler;

  static Future<TripDataModelImplementation> createExistingInstanceAsync(
      TripMetadataFacade tripMetadata,
      CurrencyConverterService currencyConverter) async {
    var tripMetadataModelImplementation =
        TripMetadataModelImplementation.fromModelFacade(
            tripMetadataModelFacade: tripMetadata);

    var tripDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripMetadata.id);

    var transitModelCollection =
        await ModelCollectionImplementation.createInstance(
            tripDocumentReference.collection(
                FirestoreCollections.transitCollectionName),
            (documentSnapshot) =>
                TransitImplementation.fromDocumentSnapshot(
                    tripMetadata.id!, documentSnapshot),
            (transitModelFacade) => TransitImplementation.fromModelFacade(
                transitModelFacade: transitModelFacade));
    var lodgingModelCollection =
        await ModelCollectionImplementation.createInstance(
            tripDocumentReference.collection(
                FirestoreCollections.lodgingCollectionName),
            (documentSnapshot) =>
                LodgingModelImplementation.fromDocumentSnapshot(
                    tripId: tripMetadata.id!,
                    documentSnapshot: documentSnapshot),
            (lodgingModelFacade) => LodgingModelImplementation.fromModelFacade(
                lodgingModelFacade: lodgingModelFacade));
    var expenseModelCollection =
        await ModelCollectionImplementation.createInstance(
            tripDocumentReference.collection(
                FirestoreCollections.expenseCollectionName),
            (documentSnapshot) =>
                ExpenseModelImplementation.fromDocumentSnapshot(
                    tripId: tripMetadata.id!,
                    documentSnapshot: documentSnapshot),
            (expenseModelFacade) => ExpenseModelImplementation.fromModelFacade(
                expenseModelFacade: expenseModelFacade));
    var planDataModelCollection =
        await ModelCollectionImplementation.createInstance(
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

    var budgetingModuleFacade = BudgetingModuleEventHandler.createInstance(
        transitModelCollection,
        lodgingModelCollection,
        expenseModelCollection,
        currencyConverter,
        tripMetadataModelImplementation);

    return TripDataModelImplementation(
        tripMetadataModelImplementation,
        transitModelCollection,
        lodgingModelCollection,
        expenseModelCollection,
        planDataModelCollection,
        itineraries,
        currencyConverter,
        budgetingModuleFacade);
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
      RepositoryPattern<TripMetadataFacade>
          tripMetadataRepositoryPattern) async {
    var updatedTripMetadata = tripMetadataRepositoryPattern.clone();
    var currentContributors = _tripMetadataModelImplementation.contributors;
    var didContributorsChange =
        currentContributors != updatedTripMetadata.contributors;
    var haveTripDatesChanged = !_tripMetadataModelImplementation.startDate!
            .isOnSameDayAs(updatedTripMetadata.startDate!) ||
        !_tripMetadataModelImplementation.endDate!
            .isOnSameDayAs(updatedTripMetadata.endDate!);
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
      var deletedTransits = _updateTripEntityListOnDatesChanged<TransitFacade>(
          datesToRemove,
          _transitModelCollection,
          (dateTime, transit) =>
              transit.departureDateTime!.isOnSameDayAs(dateTime) ||
              transit.arrivalDateTime!.isOnSameDayAs(dateTime),
          writeBatch);

      var deletedLodgings = _updateTripEntityListOnDatesChanged<LodgingFacade>(
          datesToRemove,
          _lodgingModelCollection,
          (dateTime, lodging) =>
              lodging.checkinDateTime!.isOnSameDayAs(dateTime) ||
              lodging.checkoutDateTime!.isOnSameDayAs(dateTime),
          writeBatch);
      await writeBatch.commit();
      await _budgetingModuleEventHandler.recalculateTotalExpenditure(
          updatedTripMetadata, deletedTransits, deletedLodgings);
    }

    if (didContributorsChange) {
      await _budgetingModuleEventHandler
          .tryBalanceExpensesOnContributorsChanged(
              updatedTripMetadata.contributors);
    }
    _tripMetadataModelImplementation.copyWith(updatedTripMetadata);
  }

  Iterable<T> _updateTripEntityListOnDatesChanged<T>(
      Set<DateTime> removedDates,
      ModelCollectionImplementation<T> modelCollection,
      bool Function(DateTime, T) itemsFilter,
      WriteBatch writeBatch) sync* {
    var updatedItems = <T>[];
    var currentCollectionItems = modelCollection.collectionItems;
    for (var collectionItem in currentCollectionItems) {
      var item = collectionItem.clone();
      if (!removedDates.any((removedDate) => itemsFilter(removedDate, item))) {
        updatedItems.add(item);
      } else {
        writeBatch.delete(collectionItem.documentReference);
        yield item;
      }
    }
    modelCollection.tryUpdateList(writeBatch, updatedItems);
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
