import 'dart:async';

import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/lodging.dart';
import 'package:wandrr/contracts/model_collection.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/repositories/api_services/currency_converter.dart';

import 'data_states.dart';
import 'expense.dart';
import 'repository_pattern.dart';
import 'transit.dart';

enum ExpenseSortOption {
  Category,
  LowToHighCost,
  HighToLowCost,
  OldToNew,
  NewToOld
}

abstract class BudgetingModuleFacade {
  Future<List<DebtData>> retrieveDebtDataList();

  Future<Map<ExpenseCategory, double>> retrieveTotalExpensePerCategory();

  Future<Map<DateTime?, double>> retrieveTotalExpensePerDay();

  Future<void> sortExpenseElements(
      List<UiElement<ExpenseModelFacade>> expenseUiElements,
      ExpenseSortOption expenseSortOption);
}

abstract class BudgetingModuleEventHandler extends BudgetingModuleFacade
    implements Dispose {
  Future recalculateTotalExpenditure(
      TripMetadataModelFacade newTripMetadata,
      Iterable<TransitModelFacade> deletedTransits,
      Iterable<LodgingModelFacade> deletedLodgings);

  static BudgetingModuleEventHandler createInstance(
      ModelCollectionFacade<TransitModelFacade> transitModelCollection,
      ModelCollectionFacade<LodgingModelFacade> lodgingModelCollection,
      ModelCollectionFacade<ExpenseModelFacade> expenseModelCollection,
      CurrencyConverter currencyConverter,
      RepositoryPattern<TripMetadataModelFacade> tripMetadata) {
    return _BudgetingModule(transitModelCollection, lodgingModelCollection,
        expenseModelCollection, currencyConverter, tripMetadata);
  }
}

class _BudgetingModule implements BudgetingModuleEventHandler {
  ModelCollectionFacade<TransitModelFacade> _transitModelCollection;
  ModelCollectionFacade<LodgingModelFacade> _lodgingModelCollection;
  ModelCollectionFacade<ExpenseModelFacade> _expenseModelCollection;
  final CurrencyConverter currencyConverter;
  RepositoryPattern<TripMetadataModelFacade> _tripMetadata;

  final _subscriptions = <StreamSubscription>[];

  _BudgetingModule(
      this._transitModelCollection,
      this._lodgingModelCollection,
      this._expenseModelCollection,
      this.currencyConverter,
      this._tripMetadata) {
    _subscriptions
        .add(_transitModelCollection.onDocumentAdded.listen((eventData) async {
      await _recalculateTotalExpenditureOnAddOrDelete(eventData,
          isLinkedExpense: true);
    }));
    _subscriptions.add(
        _transitModelCollection.onDocumentDeleted.listen((eventData) async {
      await _recalculateTotalExpenditureOnAddOrDelete(eventData,
          deleted: true, isLinkedExpense: true);
    }));
    _subscriptions.add(
        _transitModelCollection.onDocumentUpdated.listen((eventData) async {
      await _recalculateTotalExpenditureOnUpdate(eventData,
          isLinkedExpense: true);
    }));
    _subscriptions
        .add(_lodgingModelCollection.onDocumentAdded.listen((eventData) async {
      await _recalculateTotalExpenditureOnAddOrDelete(eventData,
          isLinkedExpense: true);
    }));
    _subscriptions.add(
        _lodgingModelCollection.onDocumentDeleted.listen((eventData) async {
      await _recalculateTotalExpenditureOnAddOrDelete(eventData,
          deleted: true, isLinkedExpense: true);
    }));
    _subscriptions.add(
        _lodgingModelCollection.onDocumentUpdated.listen((eventData) async {
      await _recalculateTotalExpenditureOnUpdate(eventData);
    }));
    _subscriptions
        .add(_expenseModelCollection.onDocumentAdded.listen((eventData) async {
      await _recalculateTotalExpenditureOnAddOrDelete(eventData);
    }));
    _subscriptions.add(
        _expenseModelCollection.onDocumentDeleted.listen((eventData) async {
      await _recalculateTotalExpenditureOnAddOrDelete(eventData, deleted: true);
    }));
    _subscriptions.add(
        _expenseModelCollection.onDocumentUpdated.listen((eventData) async {
      await _recalculateTotalExpenditureOnUpdate(eventData);
    }));
  }

  @override
  Future dispose() async {
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  @override
  Future<List<DebtData>> retrieveDebtDataList() {
    // TODO: implement retrieveDebtDataList
    throw UnimplementedError();
  }

  @override
  Future<Map<ExpenseCategory, double>> retrieveTotalExpensePerCategory() {
    // TODO: implement retrieveTotalExpensePerCategory
    throw UnimplementedError();
  }

  @override
  Future<Map<DateTime?, double>> retrieveTotalExpensePerDay() {
    // TODO: implement retrieveTotalExpensePerDay
    throw UnimplementedError();
  }

  @override
  Future recalculateTotalExpenditure(
      TripMetadataModelFacade newTripMetadata,
      Iterable<TransitModelFacade> deletedTransits,
      Iterable<LodgingModelFacade> deletedLodgings) async {
    var currentTripMetadata = _tripMetadata.clone();
    var totalExpenditure = currentTripMetadata.totalExpenditure;
    for (var transit in deletedTransits) {
      var expenseInCurrentCurrency = await currencyConverter.performQuery(
          currencyAmount: transit.expense.totalExpense,
          currencyToConvertTo: currentTripMetadata.budget.currency);
      totalExpenditure -= expenseInCurrentCurrency!;
    }
    for (var lodging in deletedLodgings) {
      var expenseInCurrentCurrency = await currencyConverter.performQuery(
          currencyAmount: lodging.expense.totalExpense,
          currencyToConvertTo: currentTripMetadata.budget.currency);
      totalExpenditure -= expenseInCurrentCurrency!;
    }
    currentTripMetadata.totalExpenditure = totalExpenditure;
    await _tripMetadata.tryUpdate(currentTripMetadata);
  }

  @override
  Future<void> sortExpenseElements(
      List<UiElement<ExpenseModelFacade>> expenseUiElements,
      ExpenseSortOption expenseSortOption) async {
    var newUiEntries = expenseUiElements
        .where((element) => element.dataState == DataState.NewUiEntry)
        .toList();
    expenseUiElements
        .removeWhere((element) => element.dataState == DataState.NewUiEntry);
    switch (expenseSortOption) {
      case ExpenseSortOption.OldToNew:
        {
          _sortOnDateTime(expenseUiElements);
          break;
        }
      case ExpenseSortOption.NewToOld:
        {
          _sortOnDateTime(expenseUiElements, isAscendingOrder: false);
          break;
        }
      case ExpenseSortOption.Category:
        {
          expenseUiElements.sort((a, b) =>
              a.element.category.name.compareTo(b.element.category.name));
          break;
        }
      case ExpenseSortOption.LowToHighCost:
        {
          await _sortOnCost(expenseUiElements);
          break;
        }
      case ExpenseSortOption.HighToLowCost:
        {
          await _sortOnCost(expenseUiElements, isAscendingOrder: false);
          break;
        }
    }
    expenseUiElements.addAll(newUiEntries);
  }

  void _sortOnDateTime(List<UiElement<ExpenseModelFacade>> expenseUiElements,
      {bool isAscendingOrder = true}) {
    var expensesWithDateTime = <UiElement<ExpenseModelFacade>>[];
    var expensesWithoutDateTime = <UiElement<ExpenseModelFacade>>[];
    for (var expenseUiElement in expenseUiElements) {
      var expense = expenseUiElement.element;
      if (expense.dateTime != null) {
        expensesWithDateTime.add(expenseUiElement);
      } else {
        expensesWithoutDateTime.add(expenseUiElement);
      }
    }
    expenseUiElements =
        List<UiElement<ExpenseModelFacade>>.from(expensesWithDateTime);
    if (isAscendingOrder) {
      expenseUiElements
          .sort((a, b) => a.element.dateTime!.compareTo(b.element.dateTime!));
    } else {
      expenseUiElements
          .sort((a, b) => b.element.dateTime!.compareTo(a.element.dateTime!));
    }
    expenseUiElements.addAll(expensesWithoutDateTime);
    expenseUiElements = List.from(expenseUiElements);
  }

  Future _sortOnCost(List<UiElement<ExpenseModelFacade>> expenseUiElements,
      {bool isAscendingOrder = true}) async {
    for (int i = 0; i < expenseUiElements.length - 1; i++) {
      for (int j = 0; j < expenseUiElements.length - i - 1; j++) {
        var tripCurrency = _tripMetadata.facade.budget.currency;
        var firstElement = expenseUiElements[j];
        var firstExpenseValue = await currencyConverter.performQuery(
            currencyAmount: firstElement.element.totalExpense,
            currencyToConvertTo: tripCurrency);
        var secondElement = expenseUiElements[j + 1];
        var secondExpenseValue = await currencyConverter.performQuery(
            currencyAmount: secondElement.element.totalExpense,
            currencyToConvertTo: tripCurrency);

        int comparisonResult =
            firstExpenseValue!.compareTo(secondExpenseValue!);
        var shouldSwapElements =
            isAscendingOrder ? comparisonResult > 0 : comparisonResult < 0;
        if (shouldSwapElements) {
          var temp = expenseUiElements[j];
          expenseUiElements[j] = expenseUiElements[j + 1];
          expenseUiElements[j + 1] = temp;
        }
      }
    }
  }

  Future<void> _recalculateTotalExpenditureOnUpdate(
      CollectionModificationData<UpdateData<RepositoryPattern>> eventData,
      {bool isLinkedExpense = false}) async {
    var modifiedItemAfterUpdate =
        eventData.modifiedCollectionItem.afterUpdate.clone();
    ExpenseModelFacade expenseAfterUpdate = isLinkedExpense
        ? modifiedItemAfterUpdate.expense
        : modifiedItemAfterUpdate;
    var modifiedItemBeforeUpdate =
        eventData.modifiedCollectionItem.beforeUpdate.clone();
    ExpenseModelFacade expenseBeforeUpdate = isLinkedExpense
        ? modifiedItemBeforeUpdate.expense
        : modifiedItemBeforeUpdate;
    if (expenseBeforeUpdate != expenseAfterUpdate) {
      var currentTripMetadata = _tripMetadata.clone();
      var currentExpense = currentTripMetadata.totalExpenditure;
      var defaultCurrency = currentTripMetadata.budget.currency;
      var postUpdatedExpenseInDefaultCurrency =
          await currencyConverter.performQuery(
              currencyAmount: expenseAfterUpdate.totalExpense,
              currencyToConvertTo: defaultCurrency);
      var preUpdatedExpenseInDefaultCurrency =
          await currencyConverter.performQuery(
              currencyAmount: expenseBeforeUpdate.totalExpense,
              currencyToConvertTo: defaultCurrency);
      var updatedTotalExpense = currentExpense -
          preUpdatedExpenseInDefaultCurrency! +
          postUpdatedExpenseInDefaultCurrency!;
      currentTripMetadata.totalExpenditure = updatedTotalExpense;
      await _tripMetadata.tryUpdate(currentTripMetadata);
    }
  }

  Future<void> _recalculateTotalExpenditureOnAddOrDelete(
      CollectionModificationData<RepositoryPattern> eventData,
      {bool deleted = false,
      bool isLinkedExpense = false}) async {
    var tripMetadata = _tripMetadata.clone();
    var currentExpense = tripMetadata.totalExpenditure;
    var defaultCurrency = tripMetadata.budget.currency;
    var modifiedItem = eventData.modifiedCollectionItem.clone();
    ExpenseModelFacade addedExpense =
        isLinkedExpense ? modifiedItem.expense : modifiedItem;
    if (addedExpense.totalExpense.amount != 0) {
      var convertedCurrencyAmount = await currencyConverter.performQuery(
          currencyAmount: addedExpense.totalExpense,
          currencyToConvertTo: defaultCurrency);
      double updatedTotalExpense = currentExpense;
      if (deleted) {
        updatedTotalExpense -= convertedCurrencyAmount!;
      } else {
        updatedTotalExpense += convertedCurrencyAmount!;
      }
      tripMetadata.totalExpenditure = updatedTotalExpense;
      await _tripMetadata.tryUpdate(tripMetadata);
    }
  }
}

// class BudgetingModule
//     implements BudgetingModuleFacade, BudgetingModuleModifier {
//   final List<ExpenseModelFacade> _allExpenses;
//   final List<TransitModelFacade> _allTransits;
//   final List<LodgingModelFacade> _allLodgings;
//   final CurrencyConverter _currencyConverter;
//   final TripMetadataModelFacade _tripMetaData;
//   final String _currency;
//
//   BudgetingModule(
//       {required List<TransitModelFacade> transits,
//       required List<LodgingModelFacade> lodgings,
//       required List<ExpenseModelFacade> expenses,
//       required CurrencyConverter currencyConverter,
//       required TripMetadataModelFacade tripMetaData})
//       : _allTransits = transits,
//         _tripMetaData = tripMetaData,
//         _allLodgings = lodgings,
//         _allExpenses = expenses,
//         _currencyConverter = currencyConverter,
//         _currency = tripMetaData.budget.currency;
//
//   @override
//   Future<Map<ExpenseCategory, double>> retrieveTotalExpensePerCategory() async {
//     Map<ExpenseCategory, double> categorizedExpenses = {};
//     for (var expense in _retrieveAllExpenses()) {
//       if (categorizedExpenses.containsKey(expense.category)) {
//         if (expense.totalExpense.currency != _currency) {
//           var totalExpenseInCurrentCurrency =
//               await _currencyConverter.performQuery(
//                   currencyAmount: expense.totalExpense,
//                   currencyToConvertTo: _currency);
//           if (totalExpenseInCurrentCurrency != null) {
//             categorizedExpenses[expense.category] =
//                 categorizedExpenses[expense.category]! +
//                     totalExpenseInCurrentCurrency;
//           }
//         } else {
//           categorizedExpenses[expense.category] =
//               categorizedExpenses[expense.category]! +
//                   expense.totalExpense.amount;
//         }
//       } else {
//         if (expense.totalExpense.currency != _currency) {
//           var totalExpenseInCurrentCurrency =
//               await _currencyConverter.performQuery(
//                   currencyAmount: expense.totalExpense,
//                   currencyToConvertTo: _currency);
//           if (totalExpenseInCurrentCurrency != null) {
//             categorizedExpenses[expense.category] =
//                 totalExpenseInCurrentCurrency;
//           }
//         } else {
//           categorizedExpenses[expense.category] = expense.totalExpense.amount;
//         }
//       }
//     }
//
//     return categorizedExpenses;
//   }
//
//   @override
//   Future<List<DebtData>> retrieveDebtDataList() async {
//     List<DebtData> allDebtDataList = [];
//
//     for (var expense in _retrieveAllExpenses()) {
//       var splitBy = expense.splitBy;
//       if (splitBy.length <= 1) {
//         continue;
//       }
//       var currency = expense.totalExpense.currency;
//       var paidBy = expense.paidBy;
//       var amountsPaidToConsider =
//           paidBy.entries.where((element) => splitBy.contains(element.key));
//       var totalAmountToSplitBy = amountsPaidToConsider.fold(
//           0.0, (previousValue, element) => previousValue + element.value);
//       var averageAmountSpent = totalAmountToSplitBy / splitBy.length;
//
//       Map<String, double> usersVsAmountSpentAboveAverage = {},
//           usersVsAmountSpentLessThanAverage = {};
//       for (var amountPaid in amountsPaidToConsider) {
//         var differenceFromAverage = averageAmountSpent - amountPaid.value;
//         if (differenceFromAverage < 0) {
//           usersVsAmountSpentLessThanAverage[amountPaid.key] =
//               -1 * differenceFromAverage;
//         } else if (differenceFromAverage > 0) {
//           usersVsAmountSpentAboveAverage[amountPaid.key] =
//               differenceFromAverage;
//         }
//       }
//
//       for (var userVsAmountSpentLessThanAverage
//           in usersVsAmountSpentLessThanAverage.entries) {
//         double carriedAmount = 0;
//         var userWhoOwesMoney = userVsAmountSpentLessThanAverage.key;
//         for (var userVsAmountSpentAboveAverage in usersVsAmountSpentAboveAverage
//             .entries
//             .where((element) => element.value > 0)) {
//           if (carriedAmount > 0) {
//             var differenceInAmounts =
//                 userVsAmountSpentAboveAverage.value - carriedAmount;
//             if (differenceInAmounts > 0) {
//               carriedAmount = 0;
//               usersVsAmountSpentAboveAverage[
//                   userVsAmountSpentAboveAverage.key] = differenceInAmounts;
//               allDebtDataList.add(DebtData(
//                   owedBy: userWhoOwesMoney,
//                   owedTo: userVsAmountSpentAboveAverage.key,
//                   currencyWithValue: CurrencyWithValue(
//                       currency: currency, amount: carriedAmount)));
//               break;
//             } else if (differenceInAmounts < 0) {
//               usersVsAmountSpentAboveAverage[
//                   userVsAmountSpentAboveAverage.key] = 0;
//               carriedAmount = differenceInAmounts * -1;
//               allDebtDataList.add(DebtData(
//                   owedBy: userWhoOwesMoney,
//                   owedTo: userVsAmountSpentAboveAverage.key,
//                   currencyWithValue: CurrencyWithValue(
//                       currency: currency, amount: carriedAmount)));
//             } else if (differenceInAmounts == 0) {
//               carriedAmount = 0;
//               usersVsAmountSpentAboveAverage[
//                   userVsAmountSpentAboveAverage.key] = 0;
//               allDebtDataList.add(DebtData(
//                   owedBy: userWhoOwesMoney,
//                   owedTo: userVsAmountSpentAboveAverage.key,
//                   currencyWithValue: CurrencyWithValue(
//                       currency: currency, amount: carriedAmount)));
//               break;
//             }
//             continue;
//           }
//           var differenceInAmounts = userVsAmountSpentAboveAverage.value -
//               userVsAmountSpentLessThanAverage.value;
//           if (differenceInAmounts == 0) {
//             usersVsAmountSpentAboveAverage[userVsAmountSpentAboveAverage.key] =
//                 0;
//             allDebtDataList.add(DebtData(
//                 owedBy: userWhoOwesMoney,
//                 owedTo: userVsAmountSpentAboveAverage.key,
//                 currencyWithValue: CurrencyWithValue(
//                     currency: currency,
//                     amount: userVsAmountSpentLessThanAverage.value)));
//             break;
//           } else if (differenceInAmounts < 0) {
//             usersVsAmountSpentAboveAverage[userVsAmountSpentAboveAverage.key] =
//                 0;
//             carriedAmount = -1 * differenceInAmounts;
//             allDebtDataList.add(DebtData(
//                 owedBy: userWhoOwesMoney,
//                 owedTo: userVsAmountSpentAboveAverage.key,
//                 currencyWithValue: CurrencyWithValue(
//                     currency: currency,
//                     amount: userVsAmountSpentAboveAverage.value)));
//           } else if (differenceInAmounts > 0) {
//             usersVsAmountSpentAboveAverage[userVsAmountSpentAboveAverage.key] =
//                 differenceInAmounts;
//             allDebtDataList.add(DebtData(
//                 owedBy: userWhoOwesMoney,
//                 owedTo: userVsAmountSpentAboveAverage.key,
//                 currencyWithValue: CurrencyWithValue(
//                     currency: currency,
//                     amount: userVsAmountSpentLessThanAverage.value)));
//           }
//         }
//       }
//     }
//
//     return allDebtDataList;
//   }
//
//   @override
//   Future<Map<DateTime?, double>> retrieveTotalExpensePerDay() async {
//     Map<DateTime?, double> totalExpensesPerDay = {};
//     for (var expense in _retrieveAllExpenses()) {
//       if (totalExpensesPerDay.containsKey(expense.dateTime)) {
//         if (expense.totalExpense.currency != _currency) {
//           var totalExpenseInCurrentCurrency =
//               await _currencyConverter.performQuery(
//                   currencyAmount: expense.totalExpense,
//                   currencyToConvertTo: _currency);
//           if (totalExpenseInCurrentCurrency != null) {
//             totalExpensesPerDay[expense.dateTime] =
//                 totalExpensesPerDay[expense.dateTime]! +
//                     totalExpenseInCurrentCurrency;
//           }
//         } else {
//           totalExpensesPerDay[expense.dateTime] =
//               totalExpensesPerDay[expense.dateTime]! +
//                   expense.totalExpense.amount;
//         }
//       } else {
//         if (expense.totalExpense.currency != _currency) {
//           var totalExpenseInCurrentCurrency =
//               await _currencyConverter.performQuery(
//                   currencyAmount: expense.totalExpense,
//                   currencyToConvertTo: _currency);
//           if (totalExpenseInCurrentCurrency != null) {
//             totalExpensesPerDay[expense.dateTime] =
//                 totalExpenseInCurrentCurrency;
//           }
//         } else {
//           totalExpensesPerDay[expense.dateTime] = expense.totalExpense.amount;
//         }
//       }
//     }
//
//     var currentDate = _tripMetaData.startDate!;
//     do {
//       var expenseForCurrentDate = totalExpensesPerDay.entries
//           .where((element) =>
//               element.key != null && isOnSameDayAs(element.key!, currentDate))
//           .firstOrNull;
//       if (expenseForCurrentDate == null) {
//         totalExpensesPerDay[currentDate] = 0;
//       }
//       currentDate = currentDate.add(Duration(days: 1));
//     } while (!(currentDate.day == _tripMetaData.endDate!.day &&
//         currentDate.year == _tripMetaData.endDate!.year &&
//         currentDate.month == _tripMetaData.endDate!.month));
//     return totalExpensesPerDay;
//   }
//
//   bool isOnSameDayAs(DateTime dateTime1, DateTime dateTime2) {
//     return dateTime1.day == dateTime2.day &&
//         dateTime1.month == dateTime2.month &&
//         dateTime1.year == dateTime2.year;
//   }
//
//   @override
//   Future<CurrencyWithValue> get totalExpenditure async {
//     var allExpenses = _retrieveAllExpenses().map((e) => e.totalExpense);
//     double totalExpense = 0;
//
//     if (allExpenses.isNotEmpty) {
//       for (var expense in allExpenses) {
//         if (expense.currency == _currency) {
//           totalExpense += expense.amount;
//         } else {
//           var convertedAmount = await _currencyConverter.performQuery(
//               currencyAmount: expense, currencyToConvertTo: _currency);
//           if (convertedAmount != null) {
//             totalExpense += convertedAmount;
//           }
//         }
//       }
//     }
//
//     return CurrencyWithValue(currency: _currency, amount: totalExpense);
//   }
//
//   @override
//   Future tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
//       ExpenseModelFacade expense, DataState requestedDataState) async {
//     if (requestedDataState == DataState.RequestedCreation) {
//       var totalExpenditureAmountBeforeUpdate = _tripMetaData.totalExpenditure;
//
//       var addedExpenseAmountInCurrentCurrency =
//           await _currencyConverter.performQuery(
//               currencyAmount: CurrencyWithValue(
//                   currency: expense.totalExpense.currency,
//                   amount: expense.totalExpense.amount),
//               currencyToConvertTo: _tripMetaData.budget.currency);
//       if (addedExpenseAmountInCurrentCurrency != null) {
//         var totalExpenditureAmountAfterUpdate =
//             totalExpenditureAmountBeforeUpdate +
//                 addedExpenseAmountInCurrentCurrency;
//         await _tryUpdateTotalExpenditure(totalExpenditureAmountBeforeUpdate,
//             totalExpenditureAmountAfterUpdate);
//       }
//     } else if (requestedDataState == DataState.RequestedDeletion) {
//       var totalExpenditureAmountBeforeUpdate = _tripMetaData.totalExpenditure;
//
//       var updatedExpenseAmountInCurrentCurrency =
//           await _currencyConverter.performQuery(
//               currencyAmount: CurrencyWithValue(
//                   currency: expense.totalExpense.currency,
//                   amount: expense.totalExpense.amount),
//               currencyToConvertTo: _tripMetaData.budget.currency);
//       if (updatedExpenseAmountInCurrentCurrency != null) {
//         var totalExpenditureAmountAfterUpdate =
//             totalExpenditureAmountBeforeUpdate -
//                 updatedExpenseAmountInCurrentCurrency;
//         await _tryUpdateTotalExpenditure(totalExpenditureAmountBeforeUpdate,
//             totalExpenditureAmountAfterUpdate);
//       }
//     }
//   }
//
//   @override
//   Future tryUpdateTotalExpenseOnExpenseUpdated(
//       CurrencyWithValue expenseBeforeUpdate,
//       ExpenseModelFacade updatedExpense) async {
//     var expenseAmountBeforeUpdateInCurrentCurrency =
//         await _currencyConverter.performQuery(
//             currencyAmount: expenseBeforeUpdate,
//             currencyToConvertTo: _tripMetaData.budget.currency);
//     if (expenseAmountBeforeUpdateInCurrentCurrency == null) {
//       return;
//     }
//     var totalExpenditureAmountBeforeUpdate = _tripMetaData.totalExpenditure;
//
//     var updatedExpenseAmountInCurrentCurrency =
//         await _currencyConverter.performQuery(
//             currencyAmount: CurrencyWithValue(
//                 currency: updatedExpense.totalExpense.currency,
//                 amount: updatedExpense.totalExpense.amount),
//             currencyToConvertTo: _tripMetaData.budget.currency);
//     if (updatedExpenseAmountInCurrentCurrency != null) {
//       var totalExpenditureAmountAfterUpdate =
//           totalExpenditureAmountBeforeUpdate -
//               expenseAmountBeforeUpdateInCurrentCurrency +
//               updatedExpenseAmountInCurrentCurrency;
//       await _tryUpdateTotalExpenditure(totalExpenditureAmountBeforeUpdate,
//           totalExpenditureAmountAfterUpdate);
//     }
//   }
//
//   Future _tryUpdateTotalExpenditure(double currentTotalExpenditureAmount,
//       double updatedTotalExpenditureAmount) async {
//     if (currentTotalExpenditureAmount != updatedTotalExpenditureAmount) {
//       await _tripMetaData.updateTotalExpenditure(updatedTotalExpenditureAmount);
//     }
//   }
//
//   List<ExpenseModelFacade> _retrieveAllExpenses() {
//     List<ExpenseModelFacade> allExpenses = [];
//
//     for (var transit in _allTransits) {
//       var expense = transit.expense;
//       allExpenses.add(expense);
//     }
//     for (var lodging in _allLodgings) {
//       var expense = lodging.expense;
//       allExpenses.add(expense);
//     }
//     for (var expense in _allExpenses) {
//       allExpenses.add(expense);
//     }
//     return allExpenses;
//   }
// }

class DebtData {
  String owedBy, owedTo;
  CurrencyWithValue currencyWithValue;

  DebtData(
      {required this.owedBy,
      required this.owedTo,
      required this.currencyWithValue});
}
