import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/app/models/collection_model_facade.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/api_services/currency_converter.dart';
import 'package:wandrr/data/trip/models/budgeting_module.dart';
import 'package:wandrr/data/trip/models/debt_data.dart';
import 'package:wandrr/data/trip/models/expense.dart';
import 'package:wandrr/data/trip/models/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/money.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/presentation/app/extensions.dart';

class BudgetingModule implements BudgetingModuleEventHandler {
  final CollectionModelFacade<TransitFacade> _transitModelCollection;
  final CollectionModelFacade<LodgingFacade> _lodgingModelCollection;
  final CollectionModelFacade<ExpenseFacade> _expenseModelCollection;
  final CurrencyConverterService currencyConverter;
  String defaultCurrency;
  Iterable<String> _contributors;

  final _subscriptions = <StreamSubscription>[];

  static Future<BudgetingModuleEventHandler> createInstance(
      CollectionModelFacade<TransitFacade> transitModelCollection,
      CollectionModelFacade<LodgingFacade> lodgingModelCollection,
      CollectionModelFacade<ExpenseFacade> expenseModelCollection,
      CurrencyConverterService currencyConverter,
      String defaultCurrency,
      Iterable<String> contributors) async {
    double totalExpenditure = await _calculateTotalExpenseAmount(
        transitModelCollection,
        currencyConverter,
        defaultCurrency,
        lodgingModelCollection,
        expenseModelCollection);
    return BudgetingModule._(
        transitModelCollection,
        lodgingModelCollection,
        expenseModelCollection,
        currencyConverter,
        defaultCurrency,
        contributors,
        totalExpenditure);
  }

  BudgetingModule._(
      this._transitModelCollection,
      this._lodgingModelCollection,
      this._expenseModelCollection,
      this.currencyConverter,
      this.defaultCurrency,
      Iterable<String> contributors,
      double totalExpenditure)
      : _totalExpenditure = totalExpenditure,
        _contributors = contributors {
    _subscribeToTotalExpenseReCalculatorEvents();
  }

  @override
  Future dispose() async {
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  @override
  Future<List<DebtData>> retrieveDebtDataList() async {
    var allExpenses = _getAllExpenses();
    var allDebtDataList = <DebtData>[];
    if (_contributors.length == 1 || allExpenses.isEmpty) {
      return allDebtDataList;
    }

    var netBalances = <String, double>{};

    // Calculate net balance for each contributor
    for (var expense in allExpenses) {
      var splitBy = expense.splitBy;
      if (splitBy.length <= 1) {
        continue;
      }

      var totalExpense = (await currencyConverter.performQuery(
          currencyAmount: expense.totalExpense,
          currencyToConvertTo: defaultCurrency))!;

      var averageExpense = totalExpense / splitBy.length;
      var paidBy = expense.paidBy;

      for (var contributor in splitBy) {
        var paidAmount = paidBy[contributor] ?? 0.0;
        var balance = paidAmount - averageExpense;

        netBalances[contributor] = (netBalances[contributor] ?? 0) + balance;
      }
    }

    // Separate contributors into those who owe money and those who are owed money
    var contributorsOwing = <String, double>{};
    var contributorsOwed = <String, double>{};

    netBalances.forEach((contributor, balance) {
      if (balance < 0) {
        contributorsOwing[contributor] = -balance;
      } else if (balance > 0) {
        contributorsOwed[contributor] = balance;
      }
    });

    // Settle debts using a greedy algorithm
    for (var owing in contributorsOwing.entries) {
      var amountOwed = owing.value;
      for (var owed in contributorsOwed.entries) {
        if (amountOwed == 0) break;

        var amountToSettle = amountOwed < owed.value ? amountOwed : owed.value;
        allDebtDataList.add(DebtData(
            owedBy: owing.key,
            owedTo: owed.key,
            money: Money(currency: defaultCurrency, amount: amountToSettle)));

        contributorsOwed[owed.key] =
            contributorsOwed[owed.key]! - amountToSettle;
        amountOwed -= amountToSettle;
      }
    }

    return allDebtDataList;
  }

  @override
  Future<Map<ExpenseCategory, double>> retrieveTotalExpensePerCategory() async {
    var categorizedExpenses = <ExpenseCategory, double>{};
    var allExpenses = _getAllExpenses();

    for (var expense in allExpenses) {
      var totalExpense = (await currencyConverter.performQuery(
          currencyAmount: expense.totalExpense,
          currencyToConvertTo: defaultCurrency))!;

      if (categorizedExpenses.containsKey(expense.category)) {
        categorizedExpenses[expense.category] =
            categorizedExpenses[expense.category]! + totalExpense;
      } else {
        categorizedExpenses[expense.category] = totalExpense;
      }
    }

    return categorizedExpenses;
  }

  @override
  Future<Map<DateTime, double>> retrieveTotalExpensePerDay(
      DateTime startDay, DateTime endDay) async {
    var totalExpensesPerDay = <DateTime, double>{};
    var allExpenses = _getAllExpenses();

    for (var expense in allExpenses) {
      if (expense.dateTime != null) {
        var expenseDateTime = expense.dateTime!;
        var expenseDate = DateTime(
            expenseDateTime.year, expenseDateTime.month, expenseDateTime.day);
        var isExpenseOnOrAfterStartDay = expenseDate.isAfter(startDay) ||
            expenseDate.isOnSameDayAs(startDay);
        var isExpenseOnOrBeforeEndDay =
            expenseDate.isBefore(endDay) || expenseDate.isOnSameDayAs(endDay);
        if (isExpenseOnOrAfterStartDay && isExpenseOnOrBeforeEndDay) {
          var totalExpense = (await currencyConverter.performQuery(
              currencyAmount: expense.totalExpense,
              currencyToConvertTo: defaultCurrency))!;
          totalExpensesPerDay.update(
              expenseDate, (value) => value + totalExpense,
              ifAbsent: () => totalExpense);
        }
      }
    }
    for (var date = startDay;
        date.isBefore(endDay) || date.isOnSameDayAs(endDay);
        date = date.add(Duration(days: 1))) {
      totalExpensesPerDay.putIfAbsent(date, () => 0.0);
    }
    return Map.fromEntries(totalExpensesPerDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)));
  }

  @override
  double get totalExpenditure => _totalExpenditure;
  double _totalExpenditure;

  @override
  Stream<double> get totalExpenditureStream =>
      _totalExpenditureStreamController.stream;
  final StreamController<double> _totalExpenditureStreamController =
      StreamController<double>.broadcast();

  @override
  Future recalculateTotalExpenditure(
      {Iterable<TransitFacade> deletedTransits = const [],
      Iterable<LodgingFacade> deletedLodgings = const []}) async {
    var updatedTotalExpenditure =
        await BudgetingModule._calculateTotalExpenseAmount(
            _transitModelCollection,
            currencyConverter,
            defaultCurrency,
            _lodgingModelCollection,
            _expenseModelCollection,
            transitsToExclude: deletedTransits,
            lodgingsToExclude: deletedLodgings);
    if (_totalExpenditure != updatedTotalExpenditure) {
      _totalExpenditure = updatedTotalExpenditure;
      _totalExpenditureStreamController.add(_totalExpenditure);
    }
  }

  @override
  Future<Iterable<UiElement<ExpenseFacade>>> sortExpenseElements(
      List<UiElement<ExpenseFacade>> expenseUiElements,
      ExpenseSortOption expenseSortOption) async {
    var expenseUiElementsToSort =
        List<UiElement<ExpenseFacade>>.from(expenseUiElements);
    var newUiEntry = expenseUiElementsToSort
        .where((element) => element.dataState == DataState.NewUiEntry)
        .firstOrNull;
    expenseUiElementsToSort
        .removeWhere((element) => element.dataState == DataState.NewUiEntry);
    switch (expenseSortOption) {
      case ExpenseSortOption.OldToNew:
        {
          expenseUiElementsToSort =
              _sortOnDateTime(expenseUiElementsToSort).toList();
          break;
        }
      case ExpenseSortOption.NewToOld:
        {
          expenseUiElementsToSort =
              _sortOnDateTime(expenseUiElementsToSort, isAscendingOrder: false)
                  .toList();
          break;
        }
      case ExpenseSortOption.Category:
        {
          expenseUiElementsToSort.sort((a, b) =>
              a.element.category.name.compareTo(b.element.category.name));
          break;
        }
      case ExpenseSortOption.LowToHighCost:
        {
          expenseUiElementsToSort =
              (await _sortOnCost(expenseUiElementsToSort)).toList();
          break;
        }
      case ExpenseSortOption.HighToLowCost:
        {
          expenseUiElementsToSort = (await _sortOnCost(expenseUiElementsToSort,
                  isAscendingOrder: false))
              .toList();
          break;
        }
    }
    if (newUiEntry != null) {
      expenseUiElementsToSort.insert(0, newUiEntry);
    }
    return expenseUiElementsToSort;
  }

  static Future<double> _calculateTotalExpenseAmount(
      CollectionModelFacade<TransitFacade> transitModelCollection,
      CurrencyConverterService currencyConverter,
      String defaultCurrency,
      CollectionModelFacade<LodgingFacade> lodgingModelCollection,
      CollectionModelFacade<ExpenseFacade> expenseModelCollection,
      {Iterable<TransitFacade> transitsToExclude = const [],
      Iterable<LodgingFacade> lodgingsToExclude = const []}) async {
    double totalExpenditure = 0.0;
    for (var transit in transitModelCollection.collectionItems) {
      if (!transitsToExclude.any((e) => e.id == transit.id)) {
        var totalExpense = await currencyConverter.performQuery(
            currencyAmount: transit.facade.expense.totalExpense,
            currencyToConvertTo: defaultCurrency);
        totalExpenditure += totalExpense!;
      }
    }
    for (var lodging in lodgingModelCollection.collectionItems) {
      if (!lodgingsToExclude.any((e) => e.id == lodging.id)) {
        var totalExpense = await currencyConverter.performQuery(
            currencyAmount: lodging.facade.expense.totalExpense,
            currencyToConvertTo: defaultCurrency);
        totalExpenditure += totalExpense!;
      }
    }
    for (var expense in expenseModelCollection.collectionItems) {
      var totalExpense = await currencyConverter.performQuery(
          currencyAmount: expense.facade.totalExpense,
          currencyToConvertTo: defaultCurrency);
      totalExpenditure += totalExpense!;
    }
    return totalExpenditure;
  }

  void _subscribeToTotalExpenseReCalculatorEvents() {
    _subscriptions
        .add(_transitModelCollection.onDocumentAdded.listen((eventData) async {
      await recalculateTotalExpenditure();
    }));
    _subscriptions.add(
        _transitModelCollection.onDocumentDeleted.listen((eventData) async {
      await recalculateTotalExpenditure();
    }));
    _subscriptions.add(
        _transitModelCollection.onDocumentUpdated.listen((eventData) async {
      await recalculateTotalExpenditure();
    }));
    _subscriptions
        .add(_lodgingModelCollection.onDocumentAdded.listen((eventData) async {
      await recalculateTotalExpenditure();
    }));
    _subscriptions.add(
        _lodgingModelCollection.onDocumentDeleted.listen((eventData) async {
      await recalculateTotalExpenditure();
    }));
    _subscriptions.add(
        _lodgingModelCollection.onDocumentUpdated.listen((eventData) async {
      await recalculateTotalExpenditure();
    }));
    _subscriptions
        .add(_expenseModelCollection.onDocumentAdded.listen((eventData) async {
      await recalculateTotalExpenditure();
    }));
    _subscriptions.add(
        _expenseModelCollection.onDocumentDeleted.listen((eventData) async {
      await recalculateTotalExpenditure();
    }));
    _subscriptions.add(
        _expenseModelCollection.onDocumentUpdated.listen((eventData) async {
      await recalculateTotalExpenditure();
    }));
  }

  Iterable<ExpenseFacade> _getAllExpenses() {
    return _transitModelCollection.collectionItems
        .map((e) => e.facade.expense)
        .followedBy(_lodgingModelCollection.collectionItems
            .map((e) => e.facade.expense))
        .followedBy(
            _expenseModelCollection.collectionItems.map((e) => e.facade));
  }

  Iterable<UiElement<ExpenseFacade>> _sortOnDateTime(
      List<UiElement<ExpenseFacade>> expenseUiElements,
      {bool isAscendingOrder = true}) {
    var expensesWithDateTime = <UiElement<ExpenseFacade>>[];
    var expensesWithoutDateTime = <UiElement<ExpenseFacade>>[];
    for (var expenseUiElement in expenseUiElements) {
      var expense = expenseUiElement.element;
      if (expense.dateTime != null) {
        expensesWithDateTime.add(expenseUiElement);
      } else {
        expensesWithoutDateTime.add(expenseUiElement);
      }
    }
    expenseUiElements =
        List<UiElement<ExpenseFacade>>.from(expensesWithDateTime);
    if (isAscendingOrder) {
      expenseUiElements
          .sort((a, b) => a.element.dateTime!.compareTo(b.element.dateTime!));
    } else {
      expenseUiElements
          .sort((a, b) => b.element.dateTime!.compareTo(a.element.dateTime!));
    }
    expenseUiElements.insertAll(0, expensesWithoutDateTime);
    return expenseUiElements;
  }

  Future<Iterable<UiElement<ExpenseFacade>>> _sortOnCost(
      List<UiElement<ExpenseFacade>> expenseUiElements,
      {bool isAscendingOrder = true}) async {
    for (int i = 0; i < expenseUiElements.length - 1; i++) {
      for (int j = 0; j < expenseUiElements.length - i - 1; j++) {
        var firstElement = expenseUiElements[j];
        var firstExpenseValue = await currencyConverter.performQuery(
            currencyAmount: firstElement.element.totalExpense,
            currencyToConvertTo: defaultCurrency);
        var secondElement = expenseUiElements[j + 1];
        var secondExpenseValue = await currencyConverter.performQuery(
            currencyAmount: secondElement.element.totalExpense,
            currencyToConvertTo: defaultCurrency);

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
    return expenseUiElements;
  }

  @override
  Future<void> tryBalanceExpensesOnContributorsChanged(
      List<String> contributors) async {
    var writeBatch = FirebaseFirestore.instance.batch();
    _contributors = contributors;
    _recalculateExpensesOnContributorsChanged<TransitFacade>(
        _transitModelCollection, contributors, writeBatch,
        isLinkedExpense: true);
    _recalculateExpensesOnContributorsChanged<LodgingFacade>(
        _lodgingModelCollection, contributors, writeBatch,
        isLinkedExpense: true);
    _recalculateExpensesOnContributorsChanged<ExpenseFacade>(
        _expenseModelCollection, contributors, writeBatch,
        isLinkedExpense: false);

    await writeBatch.commit();
  }

  @override
  void updateCurrency(String defaultCurrency) {
    this.defaultCurrency = defaultCurrency;
  }

  void _recalculateExpensesOnContributorsChanged<T>(
      CollectionModelFacade<T> modelCollection,
      Iterable<String> contributors,
      WriteBatch writeBatch,
      {bool isLinkedExpense = false}) async {
    for (var collectionItem in modelCollection.collectionItems) {
      dynamic collectionItemFacade = collectionItem.facade;
      ExpenseFacade expenseModelFacade;
      if (isLinkedExpense) {
        expenseModelFacade = collectionItemFacade.expense;
      } else {
        expenseModelFacade = collectionItemFacade;
      }

      for (var contributor in contributors) {
        if (!expenseModelFacade.splitBy.contains(contributor)) {
          expenseModelFacade.splitBy.add(contributor);
        }
      }
      for (var contributorSplittingExpense in expenseModelFacade.splitBy) {
        if (!contributors.contains(contributorSplittingExpense)) {
          expenseModelFacade.splitBy.remove(contributorSplittingExpense);
        }
      }
      for (var contributorThatPayed in expenseModelFacade.paidBy.keys) {
        if (!contributors.contains(contributorThatPayed)) {
          expenseModelFacade.paidBy.remove(contributorThatPayed);
        }
      }
      var itemToUpdate =
          modelCollection.leafRepositoryItemCreator(collectionItemFacade as T);
      writeBatch.update(
          collectionItem.documentReference, itemToUpdate.toJson());
    }
  }
}
