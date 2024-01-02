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

  Future<CurrencyWithValue> get totalExpenditure;
}

class Trip with EquatableMixin implements TripFacade, TripModifier {
  @override
  UnmodifiableListView<ExpenseFacade> get expenses =>
      UnmodifiableListView(_expenses);
  final List<Expense> _expenses = [];

  @override
  UnmodifiableListView<LodgingFacade> get lodgings =>
      UnmodifiableListView(_lodgings);
  final List<Lodging> _lodgings = [];

  @override
  UnmodifiableListView<TransitFacade> get transits =>
      UnmodifiableListView(_transits);
  final List<Transit> _transits = [];

  @override
  UnmodifiableListView<PlanDataFacade> get planDataList =>
      UnmodifiableListView(_planDataList);
  final List<PlanData> _planDataList = [];

  @override
  UnmodifiableListView<ItineraryFacade> get itineraries =>
      UnmodifiableListView(_dailyItineraries);
  final List<Itinerary> _dailyItineraries = [];

  @override
  TripMetaDataFacade get tripMetaData => _tripMetaData;
  final TripMetaData _tripMetaData;

  @override
  Future<CurrencyWithValue> get totalExpenditure async {
    var currentCurrency = tripMetaData.budget.currency;
    var allExpenses = _retrieveAllExpenses().map((e) => e.totalExpense);
    double totalExpense = 0;

    if (allExpenses.isNotEmpty) {
      for (var expense in allExpenses) {
        if (expense.currency == currentCurrency) {
          totalExpense += expense.amount;
        } else {
          var convertedAmount = await _currencyConverter.performQuery(
              currencyAmount: expense, currencyToConvertTo: currentCurrency);
          if (convertedAmount != null) {
            totalExpense += convertedAmount;
          }
        }
      }
    }

    return CurrencyWithValue(currency: currentCurrency, amount: totalExpense);
  }

  Future _tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
      ExpenseFacade expense, DataState requestedDataState) async {
    if (requestedDataState == DataState.RequestedCreation) {
      var totalExpenditureAmountBeforeUpdate = _tripMetaData.totalExpenditure;

      var addedExpenseAmountInCurrentCurrency =
          await _currencyConverter.performQuery(
              currencyAmount: CurrencyWithValue(
                  currency: expense.totalExpense.currency,
                  amount: expense.totalExpense.amount),
              currencyToConvertTo: _tripMetaData.budget.currency);
      if (addedExpenseAmountInCurrentCurrency != null) {
        var totalExpenditureAmountAfterUpdate =
            totalExpenditureAmountBeforeUpdate +
                addedExpenseAmountInCurrentCurrency;
        await _tryUpdateTotalExpenditure(totalExpenditureAmountBeforeUpdate,
            totalExpenditureAmountAfterUpdate);
      }
    } else if (requestedDataState == DataState.RequestedDeletion) {
      var totalExpenditureAmountBeforeUpdate = _tripMetaData.totalExpenditure;

      var updatedExpenseAmountInCurrentCurrency =
          await _currencyConverter.performQuery(
              currencyAmount: CurrencyWithValue(
                  currency: expense.totalExpense.currency,
                  amount: expense.totalExpense.amount),
              currencyToConvertTo: _tripMetaData.budget.currency);
      if (updatedExpenseAmountInCurrentCurrency != null) {
        var totalExpenditureAmountAfterUpdate =
            totalExpenditureAmountBeforeUpdate -
                updatedExpenseAmountInCurrentCurrency;
        await _tryUpdateTotalExpenditure(totalExpenditureAmountBeforeUpdate,
            totalExpenditureAmountAfterUpdate);
      }
    }
  }

  Future _tryUpdateTotalExpenseOnExpenseUpdated(
      CurrencyWithValue expenseBeforeUpdate,
      ExpenseFacade updatedExpense) async {
    var expenseAmountBeforeUpdateInCurrentCurrency =
        await _currencyConverter.performQuery(
            currencyAmount: expenseBeforeUpdate,
            currencyToConvertTo: _tripMetaData.budget.currency);
    if (expenseAmountBeforeUpdateInCurrentCurrency == null) {
      return;
    }
    var totalExpenditureAmountBeforeUpdate = _tripMetaData.totalExpenditure;

    var updatedExpenseAmountInCurrentCurrency =
        await _currencyConverter.performQuery(
            currencyAmount: CurrencyWithValue(
                currency: updatedExpense.totalExpense.currency,
                amount: updatedExpense.totalExpense.amount),
            currencyToConvertTo: _tripMetaData.budget.currency);
    if (updatedExpenseAmountInCurrentCurrency != null) {
      var totalExpenditureAmountAfterUpdate =
          totalExpenditureAmountBeforeUpdate -
              expenseAmountBeforeUpdateInCurrentCurrency +
              updatedExpenseAmountInCurrentCurrency;
      await _tryUpdateTotalExpenditure(totalExpenditureAmountBeforeUpdate,
          totalExpenditureAmountAfterUpdate);
    }
  }

  Future _tryUpdateTotalExpenditure(double currentTotalExpenditureAmount,
      double updatedTotalExpenditureAmount) async {
    if (currentTotalExpenditureAmount != updatedTotalExpenditureAmount) {
      await _tripMetaData.updateTotalExpenditure(updatedTotalExpenditureAmount);
    }
  }

  List<ExpenseFacade> _retrieveAllExpenses() {
    List<ExpenseFacade> allExpenses = [];
    double totalExpense = 0;

    for (var transit in _transits) {
      var expense = transit.expense;
      allExpenses.add(expense);
    }
    for (var lodging in _lodgings) {
      var expense = lodging.expense;
      allExpenses.add(expense);
    }
    for (var expense in _expenses) {
      allExpenses.add(expense);
    }
    return allExpenses;
  }

  final CurrencyConverter _currencyConverter;

  //TODO: update this logic to include itineraries
  static Future<Trip> createFromTripMetadata(
      {required TripMetaData tripMetaData,
      required bool isNewlyCreatedTrip,
      required CurrencyConverter currencyConverter}) async {
    var trip = Trip._createEmptyFromTripMetadata(
        tripMetaData: tripMetaData, currencyConverter: currencyConverter);
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
        var itineraryToUpdate = trip._dailyItineraries
            .firstWhere((element) => element.isOnSameDayAs(itinerary.day));
        itineraryToUpdate.planData = itinerary.planData;
      }

      var transitCollection = await tripDocumentReference
          .collection(FirestoreCollections.transitCollection)
          .get();
      for (var transitDocument in transitCollection.docs) {
        var transit = Transit.fromDocumentSnapshot(
            tripId: tripMetaData.id, documentSnapshot: transitDocument);

        trip._transits.add(transit);
      }

      var lodgingCollection = await tripDocumentReference
          .collection(FirestoreCollections.lodgingCollection)
          .get();
      for (var lodgingDocument in lodgingCollection.docs) {
        var lodging = Lodging.fromDocumentSnapshot(
            tripId: tripMetaData.id, documentSnapshot: lodgingDocument);

        trip._lodgings.add(lodging);
      }

      var expenseCollection = await tripDocumentReference
          .collection(FirestoreCollections.expensesCollection)
          .get();
      for (var expenseDocument in expenseCollection.docs) {
        var expense = Expense.fromDocumentSnapshot(
            tripId: tripMetaData.id, documentSnapshot: expenseDocument);
        trip._expenses.add(expense);
      }

      var planDataListCollection = await tripDocumentReference
          .collection(FirestoreCollections.planDataListCollection)
          .get();
      for (var planDataDocument in planDataListCollection.docs) {
        var planData = await PlanData.fromDocumentSnapshot(
            tripId: tripMetaData.id,
            documentSnapshot: planDataDocument,
            isPlanDataList: true);
        trip._planDataList.add(planData);
      }
    }

    var totalExpenditure = await trip.totalExpenditure;
    trip._tryUpdateTotalExpenditure(
        trip.tripMetaData.totalExpenditure, totalExpenditure.amount);
    trip._initializeWithTransitAndLodgings();
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
            await _tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
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
                await _tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
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
          await _tryUpdateTotalExpenseOnExpenseUpdated(
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
          await _tryUpdateTotalExpenseOnExpenseUpdated(
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
          await _tryUpdateTotalExpenseOnExpenseUpdated(
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

  Trip._createEmptyFromTripMetadata(
      {required TripMetaData tripMetaData,
      required CurrencyConverter currencyConverter})
      : _tripMetaData = tripMetaData,
        _currencyConverter = currencyConverter {
    _createEmptyDailyItineraries();
  }

  void _createEmptyDailyItineraries() {
    var numberOfDays =
        _tripMetaData.endDate.difference(_tripMetaData.startDate).inDays;
    if (_dailyItineraries.isEmpty) {
      for (var dayNumber = 0; dayNumber <= numberOfDays; dayNumber++) {
        var day = tripMetaData.startDate.add(Duration(days: dayNumber));
        var itinerary = Itinerary.empty(day: day, tripId: _tripMetaData.id);
        _dailyItineraries.add(itinerary);
      }
    }
  }

  void _initializeWithTransitAndLodgings() {
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

      await _tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
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
          await _tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
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
      await _tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
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
          await _tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
              lodgingToRemove.expense, DataState.RequestedDeletion);
          await _tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
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
