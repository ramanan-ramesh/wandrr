import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/trip/models/ui_element.dart';

import '../lodging.dart';
import '../transit.dart';
import 'debt_data.dart';
import 'expense.dart';
import 'expense_sort_options.dart';

abstract class BudgetingModuleFacade {
  Future<List<DebtData>> retrieveDebtDataList();

  Future<Map<ExpenseCategory, double>> retrieveTotalExpensePerCategory();

  Future<Map<DateTime, double>> retrieveTotalExpensePerDay(
      DateTime startDay, DateTime endDay);

  Future<Iterable<UiElement<ExpenseFacade>>> sortExpenseElements(
      List<UiElement<ExpenseFacade>> expenseUiElements,
      ExpenseSortOption expenseSortOption);

  Stream<double> get totalExpenditureStream;

  double get totalExpenditure;
}

abstract class BudgetingModuleEventHandler extends BudgetingModuleFacade
    implements Dispose {
  Future recalculateTotalExpenditure(
      {Iterable<TransitFacade> deletedTransits = const [],
      Iterable<LodgingFacade> deletedLodgings = const []});

  void updateCurrency(String defaultCurrency);

  Future<void> tryBalanceExpensesOnContributorsChanged(
      List<String> contributors);
}
