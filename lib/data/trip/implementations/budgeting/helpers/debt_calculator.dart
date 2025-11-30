import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/debt_data.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';

/// Calculates debt settlements between contributors
class DebtCalculator {
  final ApiService<(Money, String), double?> currencyConverter;
  final String defaultCurrency;

  const DebtCalculator({
    required this.currencyConverter,
    required this.defaultCurrency,
  });

  /// Calculates debt data list from all expenses
  Future<Iterable<DebtData>> calculateDebts(
    Iterable<ExpenseFacade> allExpenses,
    Iterable<String> contributors,
  ) async {
    if (contributors.length == 1 || allExpenses.isEmpty) {
      return [];
    }

    final netBalances = await _calculateNetBalances(allExpenses);
    return _settleDebts(netBalances);
  }

  /// Calculates net balance for each contributor
  Future<Map<String, double>> _calculateNetBalances(
    Iterable<ExpenseFacade> allExpenses,
  ) async {
    final netBalances = <String, double>{};

    for (final expense in allExpenses) {
      final splitBy = expense.splitBy;
      if (splitBy.length <= 1) continue;

      final totalExpense =
          await currencyConverter.queryData((expense.totalExpense, defaultCurrency));
      if (totalExpense == null) continue;

      final averageExpense = totalExpense / splitBy.length;
      final paidBy = expense.paidBy;

      for (final contributor in splitBy) {
        final paidAmount = paidBy[contributor] ?? 0.0;
        final balance = paidAmount - averageExpense;
        netBalances[contributor] = (netBalances[contributor] ?? 0) + balance;
      }
    }

    return netBalances;
  }

  /// Settles debts using a greedy algorithm
  Iterable<DebtData> _settleDebts(Map<String, double> netBalances) {
    final debtList = <DebtData>[];
    final owing = <String, double>{};
    final owed = <String, double>{};

    // Separate contributors into those who owe and those who are owed
    netBalances.forEach((contributor, balance) {
      if (balance < 0) {
        owing[contributor] = -balance;
      } else if (balance > 0) {
        owed[contributor] = balance;
      }
    });

    // Settle debts using greedy approach
    for (final owingEntry in owing.entries) {
      var amountOwed = owingEntry.value;

      for (final owedEntry in owed.entries) {
        if (amountOwed == 0) break;

        final amountToSettle = amountOwed < owedEntry.value
            ? amountOwed
            : owedEntry.value;

        debtList.add(DebtData(
          owedBy: owingEntry.key,
          owedTo: owedEntry.key,
          money: Money(currency: defaultCurrency, amount: amountToSettle),
        ));

        owed[owedEntry.key] = owed[owedEntry.key]! - amountToSettle;
        amountOwed -= amountToSettle;
      }
    }

    return debtList;
  }
}

