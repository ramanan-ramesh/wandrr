import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/repositories/api_services/currency_converter.dart';

import 'expense.dart';
import 'lodging.dart';
import 'transit.dart';
import 'trip_metadata.dart';

abstract class BudgetingModuleFacade {
  Future<CurrencyWithValue> get totalExpenditure;
  Future<List<DebtData>> retrieveDebtDataList();
  Future<Map<ExpenseCategory, double>> retrieveTotalExpensePerCategory();
  Future<Map<DateTime?, double>> retrieveTotalExpensePerDay();
}

abstract class BudgetingModuleModifier {
  Future tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
      ExpenseFacade expense, DataState requestedDataState);
  Future tryUpdateTotalExpenseOnExpenseUpdated(
      CurrencyWithValue expenseBeforeUpdate, ExpenseFacade updatedExpense);
}

class BudgetingModule
    implements BudgetingModuleFacade, BudgetingModuleModifier {
  final List<ExpenseFacade> _allExpenses;
  final List<TransitFacade> _allTransits;
  final List<LodgingFacade> _allLodgings;
  final CurrencyConverter _currencyConverter;
  final TripMetaData _tripMetaData;
  final String _currency;

  BudgetingModule(
      {required List<TransitFacade> transits,
      required List<LodgingFacade> lodgings,
      required List<ExpenseFacade> expenses,
      required CurrencyConverter currencyConverter,
      required TripMetaData tripMetaData})
      : _allTransits = transits,
        _tripMetaData = tripMetaData,
        _allLodgings = lodgings,
        _allExpenses = expenses,
        _currencyConverter = currencyConverter,
        _currency = tripMetaData.budget.currency;

  @override
  Future<Map<ExpenseCategory, double>> retrieveTotalExpensePerCategory() async {
    Map<ExpenseCategory, double> categorizedExpenses = {};
    for (var expense in _retrieveAllExpenses()) {
      if (categorizedExpenses.containsKey(expense.category)) {
        if (expense.totalExpense.currency != _currency) {
          var totalExpenseInCurrentCurrency =
              await _currencyConverter.performQuery(
                  currencyAmount: expense.totalExpense,
                  currencyToConvertTo: _currency);
          if (totalExpenseInCurrentCurrency != null) {
            categorizedExpenses[expense.category] =
                categorizedExpenses[expense.category]! +
                    totalExpenseInCurrentCurrency;
          }
        } else {
          categorizedExpenses[expense.category] =
              categorizedExpenses[expense.category]! +
                  expense.totalExpense.amount;
        }
      } else {
        if (expense.totalExpense.currency != _currency) {
          var totalExpenseInCurrentCurrency =
              await _currencyConverter.performQuery(
                  currencyAmount: expense.totalExpense,
                  currencyToConvertTo: _currency);
          if (totalExpenseInCurrentCurrency != null) {
            categorizedExpenses[expense.category] =
                totalExpenseInCurrentCurrency;
          }
        } else {
          categorizedExpenses[expense.category] = expense.totalExpense.amount;
        }
      }
    }

    return categorizedExpenses;
  }

  @override
  Future<List<DebtData>> retrieveDebtDataList() async {
    List<DebtData> allDebtDataList = [];

    for (var expense in _retrieveAllExpenses()) {
      var splitBy = expense.splitBy;
      if (splitBy.length <= 1) {
        continue;
      }
      var currency = expense.totalExpense.currency;
      var paidBy = expense.paidBy;
      var amountsPaidToConsider =
          paidBy.entries.where((element) => splitBy.contains(element.key));
      var totalAmountToSplitBy = amountsPaidToConsider.fold(
          0.0, (previousValue, element) => previousValue + element.value);
      var averageAmountSpent = totalAmountToSplitBy / splitBy.length;

      Map<String, double> usersVsAmountSpentAboveAverage = {},
          usersVsAmountSpentLessThanAverage = {};
      for (var amountPaid in amountsPaidToConsider) {
        var differenceFromAverage = averageAmountSpent - amountPaid.value;
        if (differenceFromAverage < 0) {
          usersVsAmountSpentLessThanAverage[amountPaid.key] =
              -1 * differenceFromAverage;
        } else if (differenceFromAverage > 0) {
          usersVsAmountSpentAboveAverage[amountPaid.key] =
              differenceFromAverage;
        }
      }

      for (var userVsAmountSpentLessThanAverage
          in usersVsAmountSpentLessThanAverage.entries) {
        double carriedAmount = 0;
        var userWhoOwesMoney = userVsAmountSpentLessThanAverage.key;
        for (var userVsAmountSpentAboveAverage in usersVsAmountSpentAboveAverage
            .entries
            .where((element) => element.value > 0)) {
          if (carriedAmount > 0) {
            var differenceInAmounts =
                userVsAmountSpentAboveAverage.value - carriedAmount;
            if (differenceInAmounts > 0) {
              carriedAmount = 0;
              usersVsAmountSpentAboveAverage[
                  userVsAmountSpentAboveAverage.key] = differenceInAmounts;
              allDebtDataList.add(DebtData(
                  owedBy: userWhoOwesMoney,
                  owedTo: userVsAmountSpentAboveAverage.key,
                  currencyWithValue: CurrencyWithValue(
                      currency: currency, amount: carriedAmount)));
              break;
            } else if (differenceInAmounts < 0) {
              usersVsAmountSpentAboveAverage[
                  userVsAmountSpentAboveAverage.key] = 0;
              carriedAmount = differenceInAmounts * -1;
              allDebtDataList.add(DebtData(
                  owedBy: userWhoOwesMoney,
                  owedTo: userVsAmountSpentAboveAverage.key,
                  currencyWithValue: CurrencyWithValue(
                      currency: currency, amount: carriedAmount)));
            } else if (differenceInAmounts == 0) {
              carriedAmount = 0;
              usersVsAmountSpentAboveAverage[
                  userVsAmountSpentAboveAverage.key] = 0;
              allDebtDataList.add(DebtData(
                  owedBy: userWhoOwesMoney,
                  owedTo: userVsAmountSpentAboveAverage.key,
                  currencyWithValue: CurrencyWithValue(
                      currency: currency, amount: carriedAmount)));
              break;
            }
            continue;
          }
          var differenceInAmounts = userVsAmountSpentAboveAverage.value -
              userVsAmountSpentLessThanAverage.value;
          if (differenceInAmounts == 0) {
            usersVsAmountSpentAboveAverage[userVsAmountSpentAboveAverage.key] =
                0;
            allDebtDataList.add(DebtData(
                owedBy: userWhoOwesMoney,
                owedTo: userVsAmountSpentAboveAverage.key,
                currencyWithValue: CurrencyWithValue(
                    currency: currency,
                    amount: userVsAmountSpentLessThanAverage.value)));
            break;
          } else if (differenceInAmounts < 0) {
            usersVsAmountSpentAboveAverage[userVsAmountSpentAboveAverage.key] =
                0;
            carriedAmount = -1 * differenceInAmounts;
            allDebtDataList.add(DebtData(
                owedBy: userWhoOwesMoney,
                owedTo: userVsAmountSpentAboveAverage.key,
                currencyWithValue: CurrencyWithValue(
                    currency: currency,
                    amount: userVsAmountSpentAboveAverage.value)));
          } else if (differenceInAmounts > 0) {
            usersVsAmountSpentAboveAverage[userVsAmountSpentAboveAverage.key] =
                differenceInAmounts;
            allDebtDataList.add(DebtData(
                owedBy: userWhoOwesMoney,
                owedTo: userVsAmountSpentAboveAverage.key,
                currencyWithValue: CurrencyWithValue(
                    currency: currency,
                    amount: userVsAmountSpentLessThanAverage.value)));
          }
        }
      }
    }

    return allDebtDataList;
  }

  @override
  Future<Map<DateTime?, double>> retrieveTotalExpensePerDay() async {
    Map<DateTime?, double> totalExpensesPerDay = {};
    for (var expense in _retrieveAllExpenses()) {
      if (totalExpensesPerDay.containsKey(expense.dateTime)) {
        if (expense.totalExpense.currency != _currency) {
          var totalExpenseInCurrentCurrency =
              await _currencyConverter.performQuery(
                  currencyAmount: expense.totalExpense,
                  currencyToConvertTo: _currency);
          if (totalExpenseInCurrentCurrency != null) {
            totalExpensesPerDay[expense.dateTime] =
                totalExpensesPerDay[expense.dateTime]! +
                    totalExpenseInCurrentCurrency;
          }
        } else {
          totalExpensesPerDay[expense.dateTime] =
              totalExpensesPerDay[expense.dateTime]! +
                  expense.totalExpense.amount;
        }
      } else {
        if (expense.totalExpense.currency != _currency) {
          var totalExpenseInCurrentCurrency =
              await _currencyConverter.performQuery(
                  currencyAmount: expense.totalExpense,
                  currencyToConvertTo: _currency);
          if (totalExpenseInCurrentCurrency != null) {
            totalExpensesPerDay[expense.dateTime] =
                totalExpenseInCurrentCurrency;
          }
        } else {
          totalExpensesPerDay[expense.dateTime] = expense.totalExpense.amount;
        }
      }
    }

    var currentDate = _tripMetaData.startDate;
    for (; !isOnSameDayAs(currentDate, _tripMetaData.endDate);) {
      var expenseForCurrentDate = totalExpensesPerDay.entries
          .where((element) =>
              element.key != null && isOnSameDayAs(element.key!, currentDate))
          .firstOrNull;
      if (expenseForCurrentDate == null) {
        totalExpensesPerDay[currentDate] = 0;
      }
      currentDate = currentDate.add(Duration(days: 1));
    }
    return totalExpensesPerDay;
  }

  bool isOnSameDayAs(DateTime dateTime1, DateTime dateTime2) {
    return dateTime1.day == dateTime2.day &&
        dateTime1.month == dateTime2.month &&
        dateTime1.year == dateTime2.year;
  }

  @override
  Future<CurrencyWithValue> get totalExpenditure async {
    var allExpenses = _retrieveAllExpenses().map((e) => e.totalExpense);
    double totalExpense = 0;

    if (allExpenses.isNotEmpty) {
      for (var expense in allExpenses) {
        if (expense.currency == _currency) {
          totalExpense += expense.amount;
        } else {
          var convertedAmount = await _currencyConverter.performQuery(
              currencyAmount: expense, currencyToConvertTo: _currency);
          if (convertedAmount != null) {
            totalExpense += convertedAmount;
          }
        }
      }
    }

    return CurrencyWithValue(currency: _currency, amount: totalExpense);
  }

  @override
  Future tryUpdateTotalExpenseOnExpenseCreatedOrDeleted(
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

  @override
  Future tryUpdateTotalExpenseOnExpenseUpdated(
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

    for (var transit in _allTransits) {
      var expense = transit.expense;
      allExpenses.add(expense);
    }
    for (var lodging in _allLodgings) {
      var expense = lodging.expense;
      allExpenses.add(expense);
    }
    for (var expense in _allExpenses) {
      allExpenses.add(expense);
    }
    return allExpenses;
  }
}

class DebtData {
  String owedBy, owedTo;
  CurrencyWithValue currencyWithValue;
  DebtData(
      {required this.owedBy,
      required this.owedTo,
      required this.currencyWithValue});
}
