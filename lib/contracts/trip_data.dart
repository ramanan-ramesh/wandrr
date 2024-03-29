import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/firestore_helpers.dart';
import 'package:wandrr/contracts/plan_data.dart';
import 'package:wandrr/repositories/api_services/currency_converter.dart';

import 'budgeting_module.dart';
import 'expense.dart';
import 'itinerary.dart';
import 'lodging.dart';
import 'transit.dart';
import 'trip_metadata.dart';

abstract class TripFacade {
  TripMetaDataFacade get tripMetaData;

  UnmodifiableListView<TransitFacade> get transits;

  UnmodifiableListView<LodgingFacade> get lodgings;

  UnmodifiableListView<ExpenseFacade> get expenses;

  UnmodifiableListView<PlanDataFacade> get planDataList;

  UnmodifiableListView<ItineraryFacade> get itineraries;

  BudgetingModuleFacade get budgetingModuleFacade;
}

class Trip with EquatableMixin implements TripFacade, TripModifier {
  @override
  UnmodifiableListView<ExpenseFacade> get expenses =>
      UnmodifiableListView(_expenses);
  final List<Expense> _expenses;

  @override
  UnmodifiableListView<LodgingFacade> get lodgings =>
      UnmodifiableListView(_lodgings);
  final List<Lodging> _lodgings;

  @override
  UnmodifiableListView<TransitFacade> get transits =>
      UnmodifiableListView(_transits);
  final List<Transit> _transits;

  @override
  UnmodifiableListView<PlanDataFacade> get planDataList =>
      UnmodifiableListView(_planDataList);
  final List<PlanData> _planDataList;

  @override
  UnmodifiableListView<ItineraryFacade> get itineraries =>
      UnmodifiableListView(_dailyItineraries);
  final List<Itinerary> _dailyItineraries;

  @override
  TripMetaDataFacade get tripMetaData => _tripMetaData;
  final TripMetaData _tripMetaData;

  @override
  BudgetingModuleFacade get budgetingModuleFacade => _budgetingModule;
  final BudgetingModule _budgetingModule;

  final CurrencyConverter _currencyConverter;

  //TODO: update this logic to include itineraries
  static Future<Trip> createFromTripMetadata(
      {required TripMetaData tripMetaData,
      required bool isNewlyCreatedTrip,
      required CurrencyConverter currencyConverter}) async {
    var itineraries = Trip._createEmptyDailyItineraries(tripMetaData).toList();
    List<Lodging> lodgings = [];
    List<Transit> transits = [];
    List<Expense> expenses = [];
    List<PlanData> planDataList = [];
    if (!isNewlyCreatedTrip) {
      var tripDocumentReference = FirebaseFirestore.instance
          .collection(FirestoreCollections.tripsCollection)
          .doc(tripMetaData.id);

      var itineraryDataCollection = await tripDocumentReference
          .collection(FirestoreCollections.itineraryDataCollection)
          .get();
      for (var itineraryDataDocument in itineraryDataCollection.docs) {
        var itinerary = await Itinerary.fromDocumentSnapshot(
            tripId: tripMetaData.id, documentSnapshot: itineraryDataDocument);
        var itineraryToUpdate = itineraries
            .firstWhere((element) => element.isOnSameDayAs(itinerary.day));
        itineraryToUpdate.planData = itinerary.planData;
      }

      var transitCollection = await tripDocumentReference
          .collection(FirestoreCollections.transitCollection)
          .get();
      for (var transitDocument in transitCollection.docs) {
        var transit = Transit.fromDocumentSnapshot(
            tripId: tripMetaData.id, documentSnapshot: transitDocument);

        transits.add(transit);
      }

      var lodgingCollection = await tripDocumentReference
          .collection(FirestoreCollections.lodgingCollection)
          .get();
      for (var lodgingDocument in lodgingCollection.docs) {
        var lodging = Lodging.fromDocumentSnapshot(
            tripId: tripMetaData.id, documentSnapshot: lodgingDocument);

        lodgings.add(lodging);
      }

      var expenseCollection = await tripDocumentReference
          .collection(FirestoreCollections.expensesCollection)
          .get();
      for (var expenseDocument in expenseCollection.docs) {
        var expense = Expense.fromDocumentSnapshot(
            tripId: tripMetaData.id, documentSnapshot: expenseDocument);
        expenses.add(expense);
      }

      var planDataListCollection = await tripDocumentReference
          .collection(FirestoreCollections.planDataListCollection)
          .get();
      for (var planDataDocument in planDataListCollection.docs) {
        var planData = await PlanData.fromDocumentSnapshot(
            tripId: tripMetaData.id,
            documentSnapshot: planDataDocument,
            isPlanDataList: true);
        planDataList.add(planData);
      }
    }

    var trip = Trip._(
        transits: transits,
        lodgings: lodgings,
        expenses: expenses,
        planDataList: planDataList,
        itineraries: itineraries,
        tripMetaData: tripMetaData,
        currencyConverter: currencyConverter);

    var totalExpenditure = await trip.budgetingModuleFacade.totalExpenditure;
    if (trip.tripMetaData.totalExpenditure != totalExpenditure.amount) {
      await trip._tripMetaData.updateTotalExpenditure(totalExpenditure.amount);
    }
    trip._initializeItinerary();
    return trip;
  }

  @override
  FutureOr<bool> updateExpense({required ExpenseUpdator expenseUpdator}) async {
    switch (expenseUpdator.dataState) {
      case DataState.RequestedCreation:
        {
          var expense =
              await Expense.createFromUserInput(expenseUpdator: expenseUpdator);
          if (expense != null) {
            _expenses.add(expense);
            await _budgetingModule
                .tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
                    expense, expenseUpdator.dataState);
            return true;
          }
          return false;
        }
      case DataState.RequestedDeletion:
        {
          var expenseDocumentReference = FirebaseFirestore.instance
              .collection(FirestoreCollections.tripsCollection)
              .doc(tripMetaData.id)
              .collection(FirestoreCollections.expensesCollection)
              .doc(expenseUpdator.id!);
          return await FirestoreHelpers.tryDeleteDocumentReference(
              documentReference: expenseDocumentReference,
              onSuccess: () async {
                var expenseToDelete = _expenses
                    .where((element) => element.id! == expenseUpdator.id!)
                    .first;
                await _budgetingModule
                    .tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
                        expenseToDelete, expenseUpdator.dataState);
                _expenses.removeWhere(
                    (element) => element.id! == expenseUpdator.id!);
              });
        }
      case DataState.RequestedUpdate:
        {
          var expenseToUpdate = _expenses
              .firstWhere((element) => element.id == expenseUpdator.id!);
          var expenseAmountBeforeUpdate = CurrencyWithValue(
              currency: expenseToUpdate.totalExpense.currency,
              amount: expenseToUpdate.totalExpense.amount);
          var didUpdate =
              await expenseToUpdate.update(expenseUpdator: expenseUpdator);
          await _budgetingModule.tryUpdateTotalExpenseOnExpenseUpdated(
              expenseAmountBeforeUpdate, expenseToUpdate);
          return didUpdate;
        }
      default:
        return false;
    }
  }

  @override
  FutureOr<bool> updateLodging({required LodgingUpdator lodgingUpdator}) async {
    switch (lodgingUpdator.dataState) {
      case DataState.RequestedCreation:
        {
          return await _addLodging(lodgingUpdator);
        }
      case DataState.RequestedDeletion:
        {
          return await _removeLodging(lodgingUpdator.id!);
        }
      case DataState.RequestedUpdate:
        {
          var lodgingToUpdate = _lodgings
              .firstWhere((element) => element.id == lodgingUpdator.id!);
          var expenseBeforeUpdate = CurrencyWithValue(
              currency: lodgingToUpdate.expense.totalExpense.currency,
              amount: lodgingToUpdate.expense.totalExpense.amount);
          var didUpdateLodging =
              await lodgingToUpdate.update(lodgingUpdator: lodgingUpdator);
          await _budgetingModule.tryUpdateTotalExpenseOnExpenseUpdated(
              expenseBeforeUpdate, lodgingToUpdate.expense);
          return didUpdateLodging;
        }
      default:
        return false;
    }
  }

  @override
  FutureOr<bool> updateTransit({required TransitUpdator transitUpdator}) async {
    switch (transitUpdator.dataState) {
      case DataState.RequestedCreation:
        {
          return await _addTransit(transitUpdator);
        }
      case DataState.RequestedDeletion:
        {
          return await _removeTransit(transitUpdator.id!);
        }
      case DataState.RequestedUpdate:
        {
          var transitToUpdate = _transits
              .firstWhere((element) => element.id == transitUpdator.id!);
          var expenseBeforeUpdate = CurrencyWithValue(
              currency: transitToUpdate.expense.totalExpense.currency,
              amount: transitToUpdate.expense.totalExpense.amount);
          var didUpdate =
              await transitToUpdate.update(transitUpdator: transitUpdator);
          await _budgetingModule.tryUpdateTotalExpenseOnExpenseUpdated(
              expenseBeforeUpdate, transitToUpdate.expense);
          return didUpdate;
        }
      default:
        return false;
    }
  }

  @override
  FutureOr<PlanDataUpdator?> updatePlanData(
      {required PlanDataUpdator planDataUpdator}) async {
    switch (planDataUpdator.dataState) {
      case DataState.RequestedCreation:
        {
          var planData = await PlanData.createFromUserInput(
              planDataUpdator: planDataUpdator);
          if (planData != null) {
            _planDataList.add(planData);
            return PlanDataUpdator.fromPlanData(
                planDataFacade: planData, tripId: _tripMetaData.id);
          }
        }
      case DataState.RequestedDeletion:
        {
          var planDataListReference = FirebaseFirestore.instance
              .collection(FirestoreCollections.tripsCollection)
              .doc(tripMetaData.id)
              .collection(FirestoreCollections.planDataListCollection)
              .doc(planDataUpdator.id!);

          var isDeletionSuccessFull = false;
          await FirestoreHelpers.tryDeleteDocumentReference(
              documentReference: planDataListReference,
              onSuccess: () {
                _planDataList.removeWhere(
                    (element) => element.id == planDataUpdator.id!);
                isDeletionSuccessFull = true;
              }).onError((error, stackTrace) => isDeletionSuccessFull = false);
          return isDeletionSuccessFull ? planDataUpdator : null;
        }
      case DataState.RequestedUpdate:
        {
          var planDataListToUpdate = _planDataList
              .firstWhere((element) => element.id == planDataUpdator.id!);

          var didUpdate = await planDataListToUpdate.updatePlanDataList(
              planDataUpdator: planDataUpdator);
          return didUpdate ? planDataUpdator : null;
        }
      default:
        return null;
    }
    return null;
  }

  @override
  FutureOr<PlanDataUpdator?> updateItineraryData(
      {required ItineraryFacade itineraryFacade,
      required PlanDataUpdator planDataUpdator}) async {
    var itinerary = _dailyItineraries
        .firstWhere((element) => element.isOnSameDayAs(itineraryFacade.day));
    var didUpdate = await (itinerary.planData as PlanDataModifier)
        .updatePlanDataList(planDataUpdator: planDataUpdator);
    return didUpdate ? planDataUpdator : null;
  }

  static Iterable<Itinerary> _createEmptyDailyItineraries(
      TripMetaDataFacade tripMetaDataFacade) sync* {
    var numberOfDays = tripMetaDataFacade.endDate
        .difference(tripMetaDataFacade.startDate)
        .inDays;
    for (var dayNumber = 0; dayNumber <= numberOfDays; dayNumber++) {
      var day = tripMetaDataFacade.startDate.add(Duration(days: dayNumber));
      var itinerary = Itinerary.empty(day: day, tripId: tripMetaDataFacade.id);
      yield itinerary;
    }
  }

  Trip._(
      {required List<Transit> transits,
      required List<Lodging> lodgings,
      required List<Expense> expenses,
      required List<PlanData> planDataList,
      required List<Itinerary> itineraries,
      required TripMetaData tripMetaData,
      required CurrencyConverter currencyConverter})
      : _currencyConverter = currencyConverter,
        _tripMetaData = tripMetaData,
        _transits = transits,
        _lodgings = lodgings,
        _expenses = expenses,
        _planDataList = planDataList,
        _dailyItineraries = itineraries,
        _budgetingModule = BudgetingModule(
            transits: transits,
            lodgings: lodgings,
            expenses: expenses,
            currencyConverter: currencyConverter,
            tripMetaData: tripMetaData);

  void _initializeItinerary() {
    for (var transit in _transits) {
      if (transit.arrivalDateTime.month == transit.departureDateTime.month &&
          transit.arrivalDateTime.year == transit.departureDateTime.year) {
        if (transit.arrivalDateTime.day == transit.departureDateTime.day) {
          var itineraryToUpdate = _dailyItineraries.firstWhere(
              (element) => element.isOnSameDayAs(transit.arrivalDateTime));
          itineraryToUpdate.addTransit(transit);
        } else {
          var departureDayItinerary = _dailyItineraries.firstWhere(
              (element) => element.isOnSameDayAs(transit.departureDateTime));
          departureDayItinerary.addTransit(transit);
          var arrivalDayItinerary = _dailyItineraries.firstWhere(
              (element) => element.isOnSameDayAs(transit.arrivalDateTime));
          arrivalDayItinerary.addTransit(transit);
        }
      }
    }

    for (var lodging in _lodgings) {
      var checkInDayItinerary = _dailyItineraries.firstWhere(
          (element) => element.isOnSameDayAs(lodging.checkinDateTime));
      checkInDayItinerary.addLodging(lodging);
      var checkOutDayItinerary = _dailyItineraries.firstWhere(
          (element) => element.isOnSameDayAs(lodging.checkoutDateTime));
      checkOutDayItinerary.addLodging(lodging);
    }
  }

  Future<bool> _addTransit(TransitUpdator transitUpdator) async {
    var transit =
        await Transit.createFromUserInput(transitUpdator: transitUpdator);
    if (transit != null) {
      _transits.add(transit);

      await _budgetingModule.tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
          transit.expense, DataState.RequestedCreation);

      var departureDayItinerary = _dailyItineraries.firstWhere(
          (element) => element.isOnSameDayAs(transit.departureDateTime));
      departureDayItinerary.addTransit(transit);
      var arrivalDayItinerary = _dailyItineraries.firstWhere(
          (element) => element.isOnSameDayAs(transit.arrivalDateTime));
      arrivalDayItinerary.addTransit(transit);
    }
    return transit != null;
  }

  FutureOr<bool> _removeTransit(String id,
      {bool shouldUpdateDatabase = true}) async {
    var transitDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(tripMetaData.id)
        .collection(FirestoreCollections.transitCollection)
        .doc(id);
    return await FirestoreHelpers.tryDeleteDocumentReference(
        documentReference: transitDocumentReference,
        onSuccess: () async {
          var transitToRemove =
              _transits.firstWhere((element) => element.id == id);
          _transits.removeWhere((element) => element.id == id);
          await _budgetingModule.tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
              transitToRemove.expense, DataState.RequestedDeletion);
          for (var itinerary in _dailyItineraries) {
            if (itinerary.isOnSameDayAs(transitToRemove.departureDateTime) ||
                itinerary.isOnSameDayAs(transitToRemove.arrivalDateTime)) {
              itinerary.removeTransit(transitToRemove);
            }
          }
        });
  }

  Future<bool> _addLodging(LodgingUpdator lodgingUpdator) async {
    var lodging =
        await Lodging.createFromUserInput(lodgingUpdator: lodgingUpdator);
    if (lodging != null) {
      _lodgings.add(lodging);
      await _budgetingModule.tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
          lodging.expense, DataState.RequestedCreation);
      var checkInDayItinerary = _dailyItineraries.firstWhere(
          (element) => element.isOnSameDayAs(lodging.checkinDateTime));
      checkInDayItinerary.addLodging(lodging);
      var checkOutDayItinerary = _dailyItineraries
          .where((element) => element.isOnSameDayAs(lodging.checkoutDateTime))
          .firstOrNull;
      checkOutDayItinerary?.addLodging(lodging);
    }
    return lodging != null;
  }

  FutureOr<bool> _removeLodging(String id,
      {bool shouldUpdateDatabase = true}) async {
    var lodgingDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(tripMetaData.id)
        .collection(FirestoreCollections.lodgingCollection)
        .doc(id);
    return await FirestoreHelpers.tryDeleteDocumentReference(
        documentReference: lodgingDocumentReference,
        onSuccess: () async {
          var lodgingToRemove =
              _lodgings.firstWhere((element) => element.id == id);
          _lodgings.removeWhere((element) => element.id == id);
          await _budgetingModule.tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
              lodgingToRemove.expense, DataState.RequestedDeletion);
          await _budgetingModule.tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
              lodgingToRemove.expense, DataState.RequestedDeletion);
          for (var itinerary in _dailyItineraries) {
            if (itinerary.isOnSameDayAs(lodgingToRemove.checkinDateTime) ||
                itinerary.isOnSameDayAs(lodgingToRemove.checkoutDateTime)) {
              itinerary.removeLodging(lodgingToRemove);
            }
          }
        });
  }

  @override
  List<Object?> get props =>
      [_tripMetaData, _expenses, _lodgings, _transits, _planDataList];
}

abstract class TripModifier {
  FutureOr<bool> updateTransit({required TransitUpdator transitUpdator});

  FutureOr<bool> updateLodging({required LodgingUpdator lodgingUpdator});

  FutureOr<bool> updateExpense({required ExpenseUpdator expenseUpdator});

  FutureOr<PlanDataUpdator?> updatePlanData(
      {required PlanDataUpdator planDataUpdator});

  FutureOr<PlanDataUpdator?> updateItineraryData(
      {required ItineraryFacade itineraryFacade,
      required PlanDataUpdator planDataUpdator});
}
