import 'package:wandrr/data/app/models/leaf_repository_item.dart';
import 'package:wandrr/data/app/models/ui_element.dart';

import 'debt_data.dart';
import 'expense.dart';
import 'expense_sort_options.dart';
import 'lodging.dart';
import 'transit.dart';

abstract class BudgetingModuleFacade {
  Future<List<DebtData>> retrieveDebtDataList();

  Future<Map<ExpenseCategory, double>> retrieveTotalExpensePerCategory();

  Future<Map<DateTime, double>> retrieveTotalExpensePerDay(
      DateTime startDay, DateTime endDay);

  Future<Iterable<UiElement<ExpenseFacade>>> sortExpenseElements(
      List<UiElement<ExpenseFacade>> expenseUiElements,
      ExpenseSortOption expenseSortOption);

  Future<void> tryBalanceExpensesOnContributorsChanged(
      List<String> contributors);

  Stream<double> get totalExpenditureStream;

  double get totalExpenditure;
}

abstract class BudgetingModuleEventHandler extends BudgetingModuleFacade
    implements Dispose {
  Future recalculateTotalExpenditure(
      {Iterable<TransitFacade> deletedTransits = const [],
      Iterable<LodgingFacade> deletedLodgings = const []});

  void updateCurrency(String defaultCurrency);
}
