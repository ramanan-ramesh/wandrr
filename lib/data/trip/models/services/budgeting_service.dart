import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/trip/models/budgeting/debt_data.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';

/// Read-only facade for budgeting operations exposed to the UI / Bloc layer.
///
/// It's lifecycle-bound to the
/// active trip. Once the trip is deactivated the service must not be used.
abstract class BudgetingServiceFacade {
  Future<Iterable<DebtData>> calculateDebt();

  Future<Map<ExpenseCategory, double>> groupExpensePerCategory();

  Future<Map<DateTime, double>> groupExpensePerDay(
      DateTime startDay, DateTime endDay);

  Future<Iterable<ExpenseBearingTripEntity>> sortExpenses(
      Iterable<ExpenseBearingTripEntity> expenseUiElements,
      ExpenseSortOption expenseSortOption);

  Stream<double> get totalExpenditureStream;

  double get totalExpenditure;

  String formatCurrency(Money money);
}

/// Internal event handler for budgeting operations.
abstract class BudgetingServiceModifier extends BudgetingServiceFacade
    implements Dispose {
  Future recalculateTotalExpenditure(
      {Iterable<TransitFacade> deletedTransits = const [],
      Iterable<LodgingFacade> deletedLodgings = const []});

  void updateCurrency(String defaultCurrency);
}
