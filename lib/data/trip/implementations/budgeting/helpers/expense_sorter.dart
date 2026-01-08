import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Handles sorting of expense-linked trip entities
class ExpenseSorter {
  /// Sorts expenses by date and time
  Iterable<ExpenseBearingTripEntity> sortByDateTime(
    List<ExpenseBearingTripEntity> expenses, {
    bool isAscending = true,
  }) {
    final withDateTime = <ExpenseBearingTripEntity>[];
    final withoutDateTime = <ExpenseBearingTripEntity>[];

    for (final expense in expenses) {
      if (expense.expense.dateTime != null) {
        withDateTime.add(expense);
      } else {
        withoutDateTime.add(expense);
      }
    }

    withDateTime.sort((a, b) {
      final comparison = a.expense.dateTime!.compareTo(b.expense.dateTime!);
      return isAscending ? comparison : -comparison;
    });

    return [...withDateTime, ...withoutDateTime];
  }

  /// Sorts expenses by category name
  void sortByCategory(List<ExpenseBearingTripEntity> expenses) {
    expenses.sort((a, b) => a.category.name.compareTo(b.category.name));
  }

  /// Sorts expenses by cost after currency conversion
  Future<Iterable<ExpenseBearingTripEntity>> sortByCost(
    List<ExpenseBearingTripEntity> expenses,
    Future<double?> Function(ExpenseFacade) getCost, {
    bool isAscending = true,
  }) async {
    final expenseWithCost = <ExpenseBearingTripEntity, double>{};

    for (final expense in expenses) {
      final cost = await getCost(expense.expense);
      expenseWithCost[expense] = cost ?? 0.0;
    }

    expenses.sort((a, b) {
      final comparison = expenseWithCost[a]!.compareTo(expenseWithCost[b]!);
      return isAscending ? comparison : -comparison;
    });

    return expenses;
  }
}
