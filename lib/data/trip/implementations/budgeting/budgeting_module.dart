import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/budgeting/helpers/currency_formatter.dart';
import 'package:wandrr/data/trip/implementations/budgeting/helpers/debt_calculator.dart';
import 'package:wandrr/data/trip/implementations/budgeting/helpers/expense_aggregator.dart';
import 'package:wandrr/data/trip/implementations/budgeting/helpers/expense_sorter.dart';
import 'package:wandrr/data/trip/implementations/budgeting/helpers/total_expenditure_calculator.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/data/trip/models/budgeting/debt_data.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

//TODO: BudgetingModule must have an API updateTripMetadata or listen to metadata updates, rather than individually listening to TripDates/Contributors changed/Currency changes
/// Manages budgeting functionality for a trip including expenses, debts, and aggregations
class BudgetingModule implements BudgetingModuleEventHandler {
  final ModelCollectionModifier<TransitFacade> _transitModelCollection;
  final ModelCollectionModifier<LodgingFacade> _lodgingModelCollection;
  final ModelCollectionModifier<StandaloneExpense> _expenseModelCollection;
  final ItineraryFacadeCollectionEventHandler _itineraryCollection;
  final ApiService<(Money, String), double?> currencyConverter;
  String defaultCurrency;
  final String currentUserName;
  Iterable<String> _contributors;
  final Iterable<CurrencyData> supportedCurrencies;

  // Helper classes - each with single responsibility
  final TotalExpenditureCalculator _expenditureCalculator;
  final DebtCalculator _debtCalculator;
  final ExpenseAggregator _expenseAggregator;
  final ExpenseSorter _expenseSorter;
  final CurrencyFormatter _currencyFormatter;

  // Subscription management
  final List<StreamSubscription> _subscriptions = [];

  static Future<BudgetingModuleEventHandler> createInstance(
      ModelCollectionModifier<TransitFacade> transitModelCollection,
      ModelCollectionModifier<LodgingFacade> lodgingModelCollection,
      ModelCollectionModifier<StandaloneExpense> expenseModelCollection,
      ApiService<(Money, String), double?> currencyConverter,
      String defaultCurrency,
      Iterable<CurrencyData> supportedCurrencies,
      Iterable<String> contributors,
      String currentUserName,
      ItineraryFacadeCollectionEventHandler itineraryCollection) async {
    final calculator = TotalExpenditureCalculator(currencyConverter);
    final totalExpenditure = await calculator.calculate(
      transits: transitModelCollection,
      lodgings: lodgingModelCollection,
      expenses: expenseModelCollection,
      itineraries: itineraryCollection,
      defaultCurrency: defaultCurrency,
      currentUserName: currentUserName,
    );

    return BudgetingModule._(
      transitModelCollection,
      lodgingModelCollection,
      expenseModelCollection,
      itineraryCollection,
      currencyConverter,
      defaultCurrency,
      supportedCurrencies,
      contributors,
      totalExpenditure,
      currentUserName,
    );
  }

  @override
  Future dispose() async {
    await _disposeSubscriptions();
  }

  /// Collects all expenses from transit, lodging, standalone expenses, and sights
  Iterable<ExpenseBearingTripEntity> _collectAllExpenses() sync* {
    yield* _transitModelCollection.collectionItems;
    yield* _lodgingModelCollection.collectionItems;
    yield* _expenseModelCollection.collectionItems;
    for (final itinerary in _itineraryCollection) {
      yield* itinerary.planData.sights;
    }
  }

  @override
  Future<Iterable<DebtData>> retrieveDebtDataList() async {
    final allExpenses = _collectAllExpenses().map((expense) => expense.expense);
    return _debtCalculator.calculateDebts(allExpenses, _contributors);
  }

  @override
  Future<Map<ExpenseCategory, double>> retrieveTotalExpensePerCategory() async {
    final allExpenses = _collectAllExpenses();
    return _expenseAggregator.aggregateByCategory(allExpenses);
  }

  @override
  Future<Map<DateTime, double>> retrieveTotalExpensePerDay(
      DateTime startDay, DateTime endDay) async {
    final allExpenses = _collectAllExpenses().map((expense) => expense.expense);
    return _expenseAggregator.aggregateByDay(allExpenses, startDay, endDay);
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
    _subscribeToItinerarySightsExpenseChanges();

    final updatedTotalExpenditure = await _expenditureCalculator.calculate(
      transits: _transitModelCollection,
      lodgings: _lodgingModelCollection,
      expenses: _expenseModelCollection,
      itineraries: _itineraryCollection,
      defaultCurrency: defaultCurrency,
      currentUserName: currentUserName,
      transitsToExclude: deletedTransits,
      lodgingsToExclude: deletedLodgings,
    );

    if (_totalExpenditure != updatedTotalExpenditure) {
      _totalExpenditure = updatedTotalExpenditure;
      _totalExpenditureStreamController.add(_totalExpenditure);
    }
  }

  @override
  Future<Iterable<ExpenseBearingTripEntity>> sortExpenses(
      Iterable<ExpenseBearingTripEntity> expenseUiElements,
      ExpenseSortOption expenseSortOption) async {
    final expenseList = List<ExpenseBearingTripEntity>.from(expenseUiElements);

    switch (expenseSortOption) {
      case ExpenseSortOption.oldToNew:
        return _expenseSorter.sortByDateTime(expenseList);

      case ExpenseSortOption.newToOld:
        return _expenseSorter.sortByDateTime(expenseList, isAscending: false);

      case ExpenseSortOption.category:
        _expenseSorter.sortByCategory(expenseList);
        return expenseList;

      case ExpenseSortOption.lowToHighCost:
        return _expenseSorter.sortByCost(
          expenseList,
          (expense) async => await currencyConverter
              .queryData((expense.totalExpense, defaultCurrency)),
        );

      case ExpenseSortOption.highToLowCost:
        return _expenseSorter.sortByCost(
          expenseList,
          (expense) async => await currencyConverter
              .queryData((expense.totalExpense, defaultCurrency)),
          isAscending: false,
        );
    }
  }

  @override
  Future<void> balanceExpensesOnContributorsChanged(
      Iterable<String> contributors) async {
    final writeBatch = FirebaseFirestore.instance.batch();
    _contributors = contributors;
    await _balanceExpenses(_transitModelCollection, contributors, writeBatch);
    await _balanceExpenses(_lodgingModelCollection, contributors, writeBatch);
    await _balanceExpenses(_expenseModelCollection, contributors, writeBatch);
    await writeBatch.commit();
    for (final itinerary in _itineraryCollection) {
      var updatedPlanData = itinerary.planData;
      for (final sight in updatedPlanData.sights) {
        final expense = sight.expense;
        _balanceContributors(contributors, expense);
      }
      await itinerary.updatePlanData(updatedPlanData);
    }
  }

  @override
  void updateCurrency(String defaultCurrency) {
    this.defaultCurrency = defaultCurrency;
  }

  @override
  String formatCurrency(Money money) {
    return _currencyFormatter.format(money);
  }

  /// Rebalances expenses for all entities when contributors change
  Future<void> _balanceExpenses<T extends ExpenseBearingTripEntity<dynamic>>(
    ModelCollectionModifier<T> modelCollection,
    Iterable<String> contributors,
    WriteBatch writeBatch,
  ) async {
    for (final collectionItem in modelCollection.collectionItems) {
      final expense = collectionItem.expense;
      _balanceContributors(contributors, expense);
      final itemToUpdate =
          modelCollection.repositoryItemCreator(collectionItem);
      writeBatch.update(itemToUpdate.documentReference, itemToUpdate.toJson());
    }
  }

  static void _balanceContributors(
      Iterable<String> contributors, ExpenseFacade expense) {
    for (final contributor in contributors) {
      if (!expense.splitBy.contains(contributor)) {
        expense.splitBy.add(contributor);
      }
    }
    expense.splitBy.removeWhere((c) => !contributors.contains(c));
    expense.paidBy.removeWhere((c, _) => !contributors.contains(c));
  }

  void _addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  void _cancelItinerarySubscriptions() {
    _subscriptions.removeWhere((subscription) {
      if (subscription is StreamSubscription<
          CollectionItemChangeMetadata<ItineraryPlanData>>) {
        subscription.cancel();
        return true;
      }
      return false;
    });
  }

  Future<void> _disposeSubscriptions() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _subscribeToTotalExpenseReCalculationEvents() {
    _addSubscription(_transitModelCollection.onDocumentAdded.listen((_) async {
      await recalculateTotalExpenditure();
    }));
    _addSubscription(
        _transitModelCollection.onDocumentDeleted.listen((_) async {
      await recalculateTotalExpenditure();
    }));
    _addSubscription(
        _transitModelCollection.onDocumentUpdated.listen((_) async {
      await recalculateTotalExpenditure();
    }));
    _addSubscription(_lodgingModelCollection.onDocumentAdded.listen((_) async {
      await recalculateTotalExpenditure();
    }));
    _addSubscription(
        _lodgingModelCollection.onDocumentDeleted.listen((_) async {
      await recalculateTotalExpenditure();
    }));
    _addSubscription(
        _lodgingModelCollection.onDocumentUpdated.listen((_) async {
      await recalculateTotalExpenditure();
    }));
    _addSubscription(_expenseModelCollection.onDocumentAdded.listen((_) async {
      await recalculateTotalExpenditure();
    }));
    _addSubscription(
        _expenseModelCollection.onDocumentDeleted.listen((_) async {
      await recalculateTotalExpenditure();
    }));
    _addSubscription(
        _expenseModelCollection.onDocumentUpdated.listen((_) async {
      await recalculateTotalExpenditure();
    }));
    _subscribeToItinerarySightsExpenseChanges();
  }

  void _subscribeToItinerarySightsExpenseChanges() {
    _cancelItinerarySubscriptions();
    for (final itinerary in _itineraryCollection) {
      _addSubscription(itinerary.planDataStream.listen((_) async {
        await recalculateTotalExpenditure();
      }));
    }
  }

  BudgetingModule._(
    this._transitModelCollection,
    this._lodgingModelCollection,
    this._expenseModelCollection,
    this._itineraryCollection,
    this.currencyConverter,
    this.defaultCurrency,
    this.supportedCurrencies,
    Iterable<String> contributors,
    double totalExpenditure,
    this.currentUserName,
  )   : _contributors = contributors,
        _totalExpenditure = totalExpenditure,
        _expenditureCalculator = TotalExpenditureCalculator(currencyConverter),
        _debtCalculator = DebtCalculator(
          currencyConverter: currencyConverter,
          defaultCurrency: defaultCurrency,
        ),
        _expenseAggregator = ExpenseAggregator(
          currencyConverter: currencyConverter,
          defaultCurrency: defaultCurrency,
        ),
        _expenseSorter = ExpenseSorter(),
        _currencyFormatter = CurrencyFormatter(supportedCurrencies) {
    _subscribeToTotalExpenseReCalculationEvents();
  }
}
