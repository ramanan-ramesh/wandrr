import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/contracts/budgeting_module.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/itinerary.dart';
import 'package:wandrr/contracts/lodging.dart';
import 'package:wandrr/contracts/model_collection.dart';
import 'package:wandrr/contracts/plan_data.dart';
import 'package:wandrr/contracts/repository_pattern.dart';
import 'package:wandrr/contracts/transit.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/repositories/api_services/currency_converter.dart';
import 'package:wandrr/repositories/trip_management/implementations/itinerary_model_collection.dart';

import 'expense.dart';
import 'lodging.dart';
import 'plan_data_model_implementation.dart';
import 'transit.dart';
import 'trip_metadata.dart';

class TripDataModelImplementation extends TripDataModelEventHandler {
  final _subscriptions = <StreamSubscription>[];

  TripDataModelImplementation(
      TripMetadataModelImplementation tripMetadata,
      ModelCollection<TransitModelFacade> transitModelCollection,
      ModelCollection<LodgingModelFacade> lodgingModelCollection,
      ModelCollection<ExpenseModelFacade> expenseModelCollection,
      ModelCollection<PlanDataModelFacade> planDataModelCollection,
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
  List<TransitModelFacade> get transits =>
      List.from(_transitModelCollection.collectionItems
          .cast<TransitModelFacade>()
          .map((facade) => facade.clone()));

  @override
  ModelCollection<TransitModelFacade> get transitsModelCollection =>
      _transitModelCollection;
  final ModelCollection<TransitModelFacade> _transitModelCollection;

  @override
  ModelCollection<LodgingModelFacade> get lodgingModelCollection =>
      _lodgingModelCollection;
  final ModelCollection<LodgingModelFacade> _lodgingModelCollection;

  @override
  ModelCollection<ExpenseModelFacade> get expenseModelCollection =>
      _expenseModelCollection;
  final ModelCollection<ExpenseModelFacade> _expenseModelCollection;

  @override
  List<ExpenseModelFacade> get expenses =>
      List.from(_expenseModelCollection.collectionItems
          .cast<ExpenseModelFacade>()
          .map((facade) => facade.clone()));

  @override
  List<LodgingModelFacade> get lodgings =>
      List.from(_lodgingModelCollection.collectionItems
          .cast<LodgingModelFacade>()
          .map((facade) => facade.clone()));

  @override
  List<PlanDataModelFacade> get planDataList =>
      List.from(planDataModelCollection.collectionItems
          .cast<PlanDataModelFacade>()
          .map((facade) => facade.clone()));

  @override
  ModelCollection<PlanDataModelFacade> get planDataModelCollection =>
      _planDataModelCollection;
  final ModelCollection<PlanDataModelFacade> _planDataModelCollection;

  @override
  ItineraryModelCollectionFacade get itineraryModelCollection =>
      _itineraryModelCollection;

  @override
  ItineraryModelCollectionEventHandler
      get itineraryModelCollectionEventHandler => _itineraryModelCollection;
  final ItineraryModelCollection _itineraryModelCollection;

  CurrencyConverter currencyConverter;

  @override
  TripMetadataModelFacade get tripMetadata =>
      _tripMetadataModelImplementation.clone();

  @override
  RepositoryPattern<TripMetadataModelFacade>
      get tripMetadataModelEventHandler => _tripMetadataModelImplementation;
  TripMetadataModelImplementation _tripMetadataModelImplementation;

  @override
  BudgetingModuleFacade get budgetingModuleFacade =>
      _budgetingModuleEventHandler;
  final BudgetingModuleEventHandler _budgetingModuleEventHandler;

  static Future<TripDataModelImplementation> createExistingInstanceAsync(
      TripMetadataModelFacade tripMetadata,
      CurrencyConverter currencyConverter) async {
    var tripMetadataModelImplementation =
        TripMetadataModelImplementation.fromModelFacade(
            tripMetadataModelFacade: tripMetadata);

    var tripDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(tripMetadata.id);

    var transitModelCollection = await ModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.transitCollection),
        (documentSnapshot) => TransitImplementation.fromDocumentSnapshot(
            tripMetadata.id!, documentSnapshot),
        (transitModelFacade) => TransitImplementation.fromModelFacade(
            transitModelFacade: transitModelFacade));
    var lodgingModelCollection = await ModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.lodgingCollection),
        (documentSnapshot) => LodgingModelImplementation.fromDocumentSnapshot(
            tripId: tripMetadata.id!, documentSnapshot: documentSnapshot),
        (lodgingModelFacade) => LodgingModelImplementation.fromModelFacade(
            lodgingModelFacade: lodgingModelFacade));
    var expenseModelCollection = await ModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.expensesCollection),
        (documentSnapshot) => ExpenseModelImplementation.fromDocumentSnapshot(
            tripId: tripMetadata.id!, documentSnapshot: documentSnapshot),
        (expenseModelFacade) => ExpenseModelImplementation.fromModelFacade(
            expenseModelFacade: expenseModelFacade));
    var planDataModelCollection = await ModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.planDataListCollection),
        (documentSnapshot) => PlanDataModelImplementation.fromDocumentSnapshot(
            tripId: tripMetadata.id!, documentSnapshot: documentSnapshot),
        (planDataModelFacade) => PlanDataModelImplementation.fromModelFacade(
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
      RepositoryPattern<TripMetadataModelFacade>
          tripMetadataRepositoryPattern) async {
    var tripMetadata = tripMetadataRepositoryPattern.clone();
    if (!_tripMetadataModelImplementation.startDate!
            .isOnSameDayAs(tripMetadata.startDate!) ||
        !_tripMetadataModelImplementation.endDate!
            .isOnSameDayAs(tripMetadata.endDate!)) {
      await _itineraryModelCollection.updateTripDays(
          tripMetadata.startDate!, tripMetadata.endDate!);
    }

    if (!tripMetadata.startDate!
            .isOnSameDayAs(_tripMetadataModelImplementation.startDate!) ||
        !tripMetadata.endDate!
            .isOnSameDayAs(_tripMetadataModelImplementation.endDate!)) {
      Set<DateTime> oldDates = _createDateRange(
          _tripMetadataModelImplementation.startDate!,
          _tripMetadataModelImplementation.endDate!);
      Set<DateTime> newDates =
          _createDateRange(tripMetadata.startDate!, tripMetadata.endDate!);
      Set<DateTime> datesToRemove = oldDates.difference(newDates);

      var writeBatch = FirebaseFirestore.instance.batch();
      var deletedTransits = _updateTripEntityList<TransitModelFacade>(
          datesToRemove,
          _transitModelCollection,
          (dateTime, transit) =>
              transit.departureDateTime!.isOnSameDayAs(dateTime) ||
              transit.arrivalDateTime!.isOnSameDayAs(dateTime),
          writeBatch);

      var deletedLodgings = _updateTripEntityList<LodgingModelFacade>(
          datesToRemove,
          _lodgingModelCollection,
          (dateTime, lodging) =>
              lodging.checkinDateTime!.isOnSameDayAs(dateTime) ||
              lodging.checkoutDateTime!.isOnSameDayAs(dateTime),
          writeBatch);
      await writeBatch.commit();
      await _budgetingModuleEventHandler.recalculateTotalExpenditure(
          tripMetadata, deletedTransits, deletedLodgings);
    }

    _tripMetadataModelImplementation.copyWith(tripMetadata);
  }

  Iterable<T> _updateTripEntityList<T>(
      Set<DateTime> removedDates,
      ModelCollectionFacade<T> modelCollection,
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
