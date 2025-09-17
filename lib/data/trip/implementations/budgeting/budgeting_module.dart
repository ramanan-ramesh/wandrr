import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
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
  final ModelCollectionModifier<TransitFacade> _transitModelCollection;
  final ModelCollectionModifier<LodgingFacade> _lodgingModelCollection;
  final ModelCollectionModifier<ExpenseFacade> _expenseModelCollection;
  final ApiService<(Money, String), double?> currencyConverter;
  String defaultCurrency;
  final String currentUserName;
  Iterable<String> _contributors;

  final _subscriptions = <StreamSubscription>[];

  static Future<BudgetingModuleEventHandler> createInstance(
      ModelCollectionModifier<TransitFacade> transitModelCollection,
      ModelCollectionModifier<LodgingFacade> lodgingModelCollection,
      ModelCollectionModifier<ExpenseFacade> expenseModelCollection,
      ApiService<(Money, String), double?> currencyConverter,
      String defaultCurrency,
      Iterable<CurrencyData> supportedCurrencies,
      Iterable<String> contributors,
      String currentUserName) async {
    var totalExpenditure = await _calculateTotalExpenseAmount(
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
        supportedCurrencies,
        contributors,
        totalExpenditure,
        currentUserName);
  }

  final Iterable<CurrencyData> supportedCurrencies;

  @override
  Future dispose() async {
    for (final subscription in _subscriptions) {
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
    for (final expense in allExpenses) {
      var splitBy = expense.splitBy;
      if (splitBy.length <= 1) {
        continue;
      }

      var totalExpense = (await currencyConverter
          .queryData((expense.totalExpense, defaultCurrency)))!;

      var averageExpense = totalExpense / splitBy.length;
      var paidBy = expense.paidBy;

      for (final contributor in splitBy) {
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
    for (final owing in contributorsOwing.entries) {
      var amountOwed = owing.value;
      for (final owed in contributorsOwed.entries) {
        if (amountOwed == 0) {
          break;
        }

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

    for (final expense in allExpenses) {
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

    for (final expense in allExpenses) {
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
    var totalExpenditure = 0.0;
    var expensesToConsider = <ExpenseFacade>[];
    for (final transit in transitModelCollection.collectionItems) {
      if (!transitsToExclude.any((e) => e.id == transit.id)) {
        var expense = transit.expense;
        if (expense.splitBy.contains(currentUserName)) {
          expensesToConsider.add(expense);
        }
      }
    }
    for (final lodging in lodgingModelCollection.collectionItems) {
      if (!lodgingsToExclude.any((e) => e.id == lodging.id)) {
        var expense = lodging.expense;
        if (expense.splitBy.contains(currentUserName)) {
          expensesToConsider.add(expense);
        }
      }
    }
    for (final expense in expenseModelCollection.collectionItems) {
      if (expense.splitBy.contains(currentUserName)) {
        expensesToConsider.add(expense);
      }
    }
    if (expensesToConsider.isNotEmpty) {
      totalExpenditure = 0.0;
      for (final expense in expensesToConsider) {
        var totalExpense = await currencyConverter
            .queryData((expense.totalExpense, defaultCurrency));
        totalExpenditure += totalExpense!;
      }
    }
    return totalExpenditure;
  }

  void _subscribeToTotalExpenseReCalculationEvents() {
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

  Iterable<ExpenseFacade> _getAllExpenses() =>
      _transitModelCollection.collectionItems
          .map((transit) => transit.expense)
          .followedBy(_lodgingModelCollection.collectionItems
              .map((lodging) => lodging.expense))
          .followedBy(_expenseModelCollection.collectionItems);

  Iterable<UiElement<ExpenseFacade>> _sortOnDateTime(
      List<UiElement<ExpenseFacade>> expenseUiElements,
      {bool isAscendingOrder = true}) {
    var expensesWithDateTime = <UiElement<ExpenseFacade>>[];
    var expensesWithoutDateTime = <UiElement<ExpenseFacade>>[];
    for (final expenseUiElement in expenseUiElements) {
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

    for (final expenseUiElement in expenseUiElements) {
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
    await _recalculateExpensesOnContributorsChanged<TransitFacade>(
        _transitModelCollection, contributors, writeBatch,
        isLinkedExpense: true);
    await _recalculateExpensesOnContributorsChanged<LodgingFacade>(
        _lodgingModelCollection, contributors, writeBatch,
        isLinkedExpense: true);
    await _recalculateExpensesOnContributorsChanged<ExpenseFacade>(
        _expenseModelCollection, contributors, writeBatch,
        isLinkedExpense: false);

    await writeBatch.commit();
  }

  @override
  void updateCurrency(String defaultCurrency) {
    this.defaultCurrency = defaultCurrency;
  }

  @override
  String formatCurrency(Money money) {
    var currencyData = supportedCurrencies
        .firstWhere((currency) => currency.code == money.currency);
    var amountStr = money.amount.toStringAsFixed(2);
    var parts = amountStr.split('.');
    var integerPart = parts[0];
    var decimalPart = parts[1];

    var intBuffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i != 0 && (integerPart.length - i) % 3 == 0) {
        intBuffer.write(currencyData.thousandsSeparator);
      }
      intBuffer.write(integerPart[i]);
    }
    String formattedAmount;
    if (decimalPart == '00' || decimalPart == '0') {
      formattedAmount = intBuffer.toString();
    } else {
      formattedAmount =
          intBuffer.toString() + currencyData.decimalSeparator + decimalPart;
    }

    if (currencyData.symbolOnLeft) {
      return currencyData.spaceBetweenAmountAndSymbol
          ? '${currencyData.symbol} $formattedAmount'
          : '${currencyData.symbol}$formattedAmount';
    } else {
      return currencyData.spaceBetweenAmountAndSymbol
          ? '$formattedAmount ${currencyData.symbol}'
          : '$formattedAmount${currencyData.symbol}';
    }
  }

  Future _recalculateExpensesOnContributorsChanged<T>(
      ModelCollectionModifier<T> modelCollection,
      Iterable<String> contributors,
      WriteBatch writeBatch,
      {bool isLinkedExpense = false}) async {
    for (final dynamic collectionItem in modelCollection.collectionItems) {
      ExpenseFacade expenseModelFacade;
      if (isLinkedExpense) {
        expenseModelFacade = collectionItem.expense;
      } else {
        expenseModelFacade = collectionItem;
      }

      for (final contributor in contributors) {
        if (!expenseModelFacade.splitBy.contains(contributor)) {
          expenseModelFacade.splitBy.add(contributor);
        }
      }
      for (final contributorSplittingExpense in expenseModelFacade.splitBy) {
        if (!contributors.contains(contributorSplittingExpense)) {
          expenseModelFacade.splitBy.remove(contributorSplittingExpense);
        }
      }
      for (final contributorThatPayed in expenseModelFacade.paidBy.keys) {
        if (!contributors.contains(contributorThatPayed)) {
          expenseModelFacade.paidBy.remove(contributorThatPayed);
        }
      }
      var itemToUpdate = modelCollection.repositoryItemCreator(collectionItem);
      writeBatch.update(itemToUpdate.documentReference, itemToUpdate.toJson());
    }
  }

  BudgetingModule._(
      this._transitModelCollection,
      this._lodgingModelCollection,
      this._expenseModelCollection,
      this.currencyConverter,
      this.defaultCurrency,
      this.supportedCurrencies,
      Iterable<String> contributors,
      double totalExpenditure,
      this.currentUserName)
      : _totalExpenditure = totalExpenditure,
        _contributors = contributors {
    _subscribeToTotalExpenseReCalculationEvents();
  }
}
