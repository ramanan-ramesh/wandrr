import 'dart:async';

import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/data/trip/models/budgeting/debt_data.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/budgeting_service.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';

import 'helpers/currency_formatter.dart';
import 'helpers/debt_calculator.dart';
import 'helpers/expense_aggregator.dart';
import 'helpers/expense_sorter.dart';
import 'helpers/total_expenditure_calculator.dart';

/// Implementation of [BudgetingServiceModifier].
///
/// Subscribes internally to transit / lodging / expense / itinerary collection
/// change events and calls [recalculateTotalExpenditure] automatically.
class BudgetingService implements BudgetingServiceModifier {
  final TripDataFacade _tripData;
  final ApiService<(Money, String), double?> _currencyConverter;
  final String _currentUserName;
  final Iterable<CurrencyData> supportedCurrencies;
  String defaultCurrency;

  // Helper classes – each with single responsibility
  final TotalExpenditureCalculator _expenditureCalculator;
  final DebtCalculator _debtCalculator;
  final ExpenseAggregator _expenseAggregator;
  final ExpenseSorter _expenseSorter;
  final CurrencyFormatter _currencyFormatter;

  // Subscription management
  final List<StreamSubscription> _collectionSubscriptions = [];
  final List<StreamSubscription> _itinerarySubscriptions = [];
  bool _isDisposed = false;

  BudgetingService.create({
    required TripDataFacade tripData,
    required ApiService<(Money, String), double?> currencyConverter,
    required this.supportedCurrencies,
    required String currentUserName,
  })  : _currentUserName = currentUserName,
        _tripData = tripData,
        _currencyConverter = currencyConverter,
        defaultCurrency = tripData.tripMetadata.budget.currency,
        _expenditureCalculator = TotalExpenditureCalculator(currencyConverter),
        _debtCalculator = DebtCalculator(
          currencyConverter: currencyConverter,
          defaultCurrency: tripData.tripMetadata.budget.currency,
        ),
        _expenseAggregator = ExpenseAggregator(
          currencyConverter: currencyConverter,
          defaultCurrency: tripData.tripMetadata.budget.currency,
        ),
        _expenseSorter = ExpenseSorter(),
        _currencyFormatter = CurrencyFormatter(supportedCurrencies) {
    // Trigger the initial recalculation once all collections are loaded.
    // This is self-contained so callers don't need to orchestrate it.
    if (_tripData.isFullyLoadedValue) {
      _subscribeToCollectionChangeEvents();
      recalculateTotalExpenditure();
    } else {
      _tripData.isFullyLoaded.firstWhere((loaded) => loaded).then((_) {
        if (!_isDisposed) {
          recalculateTotalExpenditure();
        }
      });
    }
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    for (final s in _collectionSubscriptions) {
      await s.cancel();
    }
    _collectionSubscriptions.clear();
    for (final s in _itinerarySubscriptions) {
      await s.cancel();
    }
    _itinerarySubscriptions.clear();
    await _totalExpenditureStreamController.close();
  }

  /// Collects all expenses from transit, lodging, standalone expenses, and sights.
  Iterable<ExpenseBearingTripEntity> _collectAllExpenses() sync* {
    yield* _tripData.transitCollection.items;
    yield* _tripData.lodgingCollection.items;
    yield* _tripData.expenseCollection.items;
    for (final itinerary in _tripData.itineraryCollection) {
      yield* itinerary.planData.sights;
    }
  }

  @override
  Future<Iterable<DebtData>> calculateDebt() async {
    final allExpenses = _collectAllExpenses().map((e) => e.expense);
    return _debtCalculator.calculateDebts(
        allExpenses, _tripData.tripMetadata.contributors);
  }

  @override
  Future<Map<ExpenseCategory, double>> groupExpensePerCategory() async {
    return _expenseAggregator.aggregateByCategory(_collectAllExpenses());
  }

  @override
  Future<Map<DateTime, double>> groupExpensePerDay(
      DateTime startDay, DateTime endDay) async {
    final allExpenses = _collectAllExpenses().map((e) => e.expense);
    return _expenseAggregator.aggregateByDay(allExpenses, startDay, endDay);
  }

  @override
  double get totalExpenditure => _totalExpenditure;
  double _totalExpenditure = 0.0;

  @override
  Stream<double> get totalExpenditureStream =>
      _totalExpenditureStreamController.stream;
  final StreamController<double> _totalExpenditureStreamController =
      StreamController<double>.broadcast();

  @override
  Future recalculateTotalExpenditure(
      {Iterable<TransitFacade> deletedTransits = const [],
      Iterable<LodgingFacade> deletedLodgings = const []}) async {
    if (_isDisposed) {
      return;
    }

    final updated = await _expenditureCalculator.calculate(
      transits: _tripData.transitCollection,
      lodgings: _tripData.lodgingCollection,
      expenses: _tripData.expenseCollection,
      itineraries: _tripData.itineraryCollection
          as ItineraryFacadeCollectionEventHandler,
      defaultCurrency: defaultCurrency,
      currentUserName: _currentUserName,
      transitsToExclude: deletedTransits,
      lodgingsToExclude: deletedLodgings,
    );

    if (_totalExpenditure != updated) {
      _totalExpenditure = updated;
      if (!_isDisposed) {
        _totalExpenditureStreamController.add(_totalExpenditure);
      }
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
          (e) async => await _currencyConverter
              .queryData((e.totalExpense, defaultCurrency)),
        );
      case ExpenseSortOption.highToLowCost:
        return _expenseSorter.sortByCost(
          expenseList,
          (e) async => await _currencyConverter
              .queryData((e.totalExpense, defaultCurrency)),
          isAscending: false,
        );
    }
  }

  @override
  void updateCurrency(String defaultCurrency) {
    this.defaultCurrency = defaultCurrency;
  }

  @override
  String formatCurrency(Money money) => _currencyFormatter.format(money);

  // ---------------------------------------------------------------------------
  // Internal subscription management
  // ---------------------------------------------------------------------------

  /// Subscribes to add/update/delete events on transit, lodging and expense
  /// collections so totals are recalculated automatically.
  void _subscribeToCollectionChangeEvents() {
    void subscribeToCollectionUpdates(ModelCollectionFacade collection) {
      _collectionSubscriptions.add(
        collection.onDocumentAdded.listen((_) => recalculateTotalExpenditure()),
      );
      _collectionSubscriptions.add(
        collection.onDocumentDeleted
            .listen((_) => recalculateTotalExpenditure()),
      );
      _collectionSubscriptions.add(
        collection.onDocumentUpdated
            .listen((_) => recalculateTotalExpenditure()),
      );
    }

    subscribeToCollectionUpdates(_tripData.transitCollection);
    subscribeToCollectionUpdates(_tripData.lodgingCollection);
    subscribeToCollectionUpdates(_tripData.expenseCollection);

    _refreshItinerarySubscriptions();
  }

  // Called by the bloc after an itinerary date-range change to pick up
  // newly created / removed itinerary day instances.
  @override
  void refreshItinerarySubscriptions() {
    _refreshItinerarySubscriptions();
  }

  void _refreshItinerarySubscriptions() {
    for (final s in _itinerarySubscriptions) {
      s.cancel();
    }
    _itinerarySubscriptions.clear();

    for (final itinerary in _tripData.itineraryCollection) {
      _itinerarySubscriptions.add(
        itinerary.planDataStream.listen((_) => recalculateTotalExpenditure()),
      );
    }
  }
}
