import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/models/budgeting/debt_data.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/ui_element.dart';

class BudgetingModule implements BudgetingModuleEventHandler {
  final ModelCollectionFacade<TransitFacade> _transitModelCollection;
  final ModelCollectionFacade<LodgingFacade> _lodgingModelCollection;
  final ModelCollectionFacade<ExpenseFacade> _expenseModelCollection;
  final ApiService<(Money, String), double?> currencyConverter;
  String defaultCurrency;
  final String currentUserName;
  Iterable<String> _contributors;

  final _subscriptions = <StreamSubscription>[];

  static Future<BudgetingModuleEventHandler> createInstance(
      ModelCollectionFacade<TransitFacade> transitModelCollection,
      ModelCollectionFacade<LodgingFacade> lodgingModelCollection,
      ModelCollectionFacade<ExpenseFacade> expenseModelCollection,
      ApiService<(Money, String), double?> currencyConverter,
      String defaultCurrency,
      Iterable<String> contributors,
      String currentUserName) async {
    double totalExpenditure = await _calculateTotalExpenseAmount(
        transitModelCollection,
        currencyConverter,
        defaultCurrency,
        lodgingModelCollection,
        expenseModelCollection,
        currentUserName);
    return BudgetingModule._(
        transitModelCollection,
        lodgingModelCollection,
        expenseModelCollection,
        currencyConverter,
        defaultCurrency,
        contributors,
        totalExpenditure,
        currentUserName);
  }

  BudgetingModule._(
      this._transitModelCollection,
      this._lodgingModelCollection,
      this._expenseModelCollection,
      this.currencyConverter,
      this.defaultCurrency,
      Iterable<String> contributors,
      double totalExpenditure,
      this.currentUserName)
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

      var totalExpense = (await currencyConverter
          .queryData((expense.totalExpense, defaultCurrency)))!;

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
      var totalExpense = (await currencyConverter
          .queryData((expense.totalExpense, defaultCurrency)))!;

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
        var totalExpense = (await currencyConverter
            .queryData((expense.totalExpense, defaultCurrency)))!;
        totalExpensesPerDay.update(expenseDate, (value) => value + totalExpense,
            ifAbsent: () => totalExpense);
      }
    }
    for (var date = startDay;
        date.isBefore(endDay) || date.isOnSameDayAs(endDay);
        date = date.add(const Duration(days: 1))) {
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
    var updatedTotalExpenditure = await _calculateTotalExpenseAmount(
        _transitModelCollection,
        currencyConverter,
        defaultCurrency,
        _lodgingModelCollection,
        _expenseModelCollection,
        transitsToExclude: deletedTransits,
        lodgingsToExclude: deletedLodgings,
        currentUserName);
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
        .where((element) => element.dataState == DataState.newUiEntry)
        .firstOrNull;
    expenseUiElementsToSort
        .removeWhere((element) => element.dataState == DataState.newUiEntry);
    switch (expenseSortOption) {
      case ExpenseSortOption.oldToNew:
        {
          expenseUiElementsToSort =
              _sortOnDateTime(expenseUiElementsToSort).toList();
          break;
        }
      case ExpenseSortOption.newToOld:
        {
          expenseUiElementsToSort =
              _sortOnDateTime(expenseUiElementsToSort, isAscendingOrder: false)
                  .toList();
          break;
        }
      case ExpenseSortOption.category:
        {
          expenseUiElementsToSort.sort((a, b) =>
              a.element.category.name.compareTo(b.element.category.name));
          break;
        }
      case ExpenseSortOption.lowToHighCost:
        {
          expenseUiElementsToSort =
              (await _sortOnCost(expenseUiElementsToSort)).toList();
          break;
        }
      case ExpenseSortOption.highToLowCost:
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
      ModelCollectionFacade<TransitFacade> transitModelCollection,
      ApiService<(Money, String), double?> currencyConverter,
      String defaultCurrency,
      ModelCollectionFacade<LodgingFacade> lodgingModelCollection,
      ModelCollectionFacade<ExpenseFacade> expenseModelCollection,
      String currentUserName,
      {Iterable<TransitFacade> transitsToExclude = const [],
      Iterable<LodgingFacade> lodgingsToExclude = const []}) async {
    double totalExpenditure = 0.0;
    var expensesToConsider = <ExpenseFacade>[];
    for (var transit in transitModelCollection.collectionItems) {
      if (!transitsToExclude.any((e) => e.id == transit.id)) {
        var expense = transit.facade.expense;
        if (expense.splitBy.contains(currentUserName)) {
          expensesToConsider.add(expense);
        }
      }
    }
    for (var lodging in lodgingModelCollection.collectionItems) {
      if (!lodgingsToExclude.any((e) => e.id == lodging.id)) {
        var expense = lodging.facade.expense;
        if (expense.splitBy.contains(currentUserName)) {
          expensesToConsider.add(expense);
        }
      }
    }
    for (var expense in expenseModelCollection.collectionItems) {
      var expenseFacade = expense.facade;
      if (expenseFacade.splitBy.contains(currentUserName)) {
        expensesToConsider.add(expenseFacade);
      }
    }
    if (expensesToConsider.isNotEmpty) {
      totalExpenditure = 0.0;
      for (var expense in expensesToConsider) {
        var totalExpense = await currencyConverter
            .queryData((expense.totalExpense, defaultCurrency));
        totalExpenditure += totalExpense!;
      }
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
    var expenseElementsWithConvertedCurrency =
        <UiElement<ExpenseFacade>, double>{};

    for (var expenseUiElement in expenseUiElements) {
      var expenseValue = await currencyConverter
          .queryData((expenseUiElement.element.totalExpense, defaultCurrency));
      expenseElementsWithConvertedCurrency[expenseUiElement] = expenseValue!;
    }

    expenseUiElements.sort((a, b) {
      var comparisonResult = expenseElementsWithConvertedCurrency[a]!
          .compareTo(expenseElementsWithConvertedCurrency[b]!);
      return isAscendingOrder ? comparisonResult : -comparisonResult;
    });

    return expenseUiElements;
  }

  @override
  Future<void> balanceExpensesOnContributorsChanged(
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
      ModelCollectionFacade<T> modelCollection,
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
