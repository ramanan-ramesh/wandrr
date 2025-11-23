import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'debt_data.dart';
import 'expense_category.dart';
import 'expense_sort_options.dart';
import 'money.dart';

abstract class BudgetingModuleFacade {
  Future<Iterable<DebtData>> retrieveDebtDataList();

  Future<Map<ExpenseCategory, double>> retrieveTotalExpensePerCategory();

  Future<Map<DateTime, double>> retrieveTotalExpensePerDay(
      DateTime startDay, DateTime endDay);

  Future<Iterable<ExpenseLinkedTripEntity>> sortExpenses(
      Iterable<ExpenseLinkedTripEntity> expenseUiElements,
      ExpenseSortOption expenseSortOption);

  Stream<double> get totalExpenditureStream;

  double get totalExpenditure;

  String formatCurrency(Money money);
}

abstract class BudgetingModuleEventHandler extends BudgetingModuleFacade
    implements Dispose {
  Future recalculateTotalExpenditure(
      {Iterable<TransitFacade> deletedTransits = const [],
      Iterable<LodgingFacade> deletedLodgings = const []});

  void updateCurrency(String defaultCurrency);

  Future<void> balanceExpensesOnContributorsChanged(List<String> contributors);
}
