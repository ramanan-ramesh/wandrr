import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';

/// Aggregates expense data for reporting
class ExpenseAggregator {
  final ApiService<(Money, String), double?> currencyConverter;
  final String defaultCurrency;

  const ExpenseAggregator({
    required this.currencyConverter,
    required this.defaultCurrency,
  });

  /// Calculates total expense per category
  Future<Map<ExpenseCategory, double>> aggregateByCategory(
    Iterable<ExpenseBearingTripEntity> allExpenses,
  ) async {
    final categorizedExpenses = <ExpenseCategory, double>{};

    for (final expense in allExpenses) {
      final totalExpense = await currencyConverter
          .queryData((expense.expense.totalExpense, defaultCurrency));

      if (totalExpense != null) {
        categorizedExpenses[expense.category] =
            (categorizedExpenses[expense.category] ?? 0) + totalExpense;
      }
    }

    return categorizedExpenses;
  }

  /// Calculates total expense per day within date range
  Future<Map<DateTime, double>> aggregateByDay(
    Iterable<ExpenseFacade> allExpenses,
    DateTime startDay,
    DateTime endDay,
  ) async {
    final totalExpensesPerDay = <DateTime, double>{};

    // Aggregate expenses by date
    for (final expense in allExpenses) {
      if (expense.dateTime != null) {
        final expenseDate = _getDateOnly(expense.dateTime!);
        final totalExpense = await currencyConverter
            .queryData((expense.totalExpense, defaultCurrency));

        if (totalExpense != null) {
          totalExpensesPerDay.update(
            expenseDate,
            (value) => value + totalExpense,
            ifAbsent: () => totalExpense,
          );
        }
      }
    }

    // Fill in missing dates with 0
    for (var date = startDay;
        date.isBefore(endDay) || date.isOnSameDayAs(endDay);
        date = date.add(const Duration(days: 1))) {
      totalExpensesPerDay.putIfAbsent(date, () => 0.0);
    }

    // Sort by date
    return Map.fromEntries(
      totalExpensesPerDay.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Extracts date without time component
  DateTime _getDateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
