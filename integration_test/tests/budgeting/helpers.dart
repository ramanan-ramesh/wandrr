import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/readonly_expense.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/bottom_nav_bar.dart';

import '../../helpers/test_config.dart';
import '../../helpers/test_helpers.dart';

Future<void> tryNavigateToBudgetingPage(WidgetTester tester) async {
  if (!TestHelpers.isLargeScreen(tester)) {
    // Find and tap the budgeting tab in bottom navigation
    final budgetingTab = find.descendant(
        of: find.byType(BottomNavBar),
        matching: find.byIcon(Icons.wallet_travel_rounded));
    await TestHelpers.tapWidget(tester, budgetingTab);
  }
}

Future<List<ReadonlyExpenseListItem>> collectExpenseListItemsFromUI(
    WidgetTester tester,
    {int? numberOfExpectedExpenses}) async {
  final scrollableFinder = find.descendant(
    of: find.byType(ExpenseListView),
    matching: find.byType(ListView),
  );
  expect(scrollableFinder, findsOneWidget);

  // Use the helper with timeout to collect expense items
  final expenseWidgets =
      await TestHelpers.collectWidgetsByScrolling<ReadonlyExpenseListItem>(
    tester: tester,
    scrollableFinder: scrollableFinder,
    widgetFinder: find.byType(ReadonlyExpenseListItem),
    getUniqueId: (widget) => widget.expenseBearingTripEntity is SightFacade
        ? '${(widget.expenseBearingTripEntity as SightFacade).day.itineraryDateFormat}_${widget.expenseBearingTripEntity.id}'
        : widget.expenseBearingTripEntity.id!,
    expectedCount: numberOfExpectedExpenses,
    timeout: const Duration(seconds: 30),
  );

  return expenseWidgets;
}

Future<List<ExpenseBearingTripEntity>> getSortedExpensesFromRepository(
    WidgetTester tester, ExpenseSortOption expenseSortOption) async {
  final tripRepo = TestHelpers.getTripRepository(tester);
  final currencyConverter =
      TestHelpers.getApiServicesRepository(tester).currencyConverter;
  var activeTrip = tripRepo.activeTrip!;
  final allExpenses = <ExpenseBearingTripEntity>[];
  allExpenses.addAll(activeTrip.expenseCollection.collectionItems);
  allExpenses.addAll(activeTrip.transitCollection.collectionItems);
  allExpenses.addAll(activeTrip.lodgingCollection.collectionItems);
  allExpenses.addAll(activeTrip.itineraryCollection
      .expand((itinerary) => itinerary.planData.sights));
  allExpenses.removeWhere((expense) =>
      expense.expense.paidBy.values
          .fold(0.0, (previousValue, element) => previousValue + element) ==
      0);

  if (expenseSortOption == ExpenseSortOption.lowToHighCost) {
    final totalAmounts = <ExpenseBearingTripEntity, double>{};
    for (final expenseBearingTripEntity in allExpenses) {
      final expenseAmount = await _calculateTotalExpenseInTripCurrency(
          expenseBearingTripEntity.expense, currencyConverter);
      totalAmounts[expenseBearingTripEntity] = expenseAmount;
    }

    allExpenses.sort((a, b) {
      final aTotal = totalAmounts[a]!;
      final bTotal = totalAmounts[b]!;
      return aTotal.compareTo(bTotal);
    });
  } else if (expenseSortOption == ExpenseSortOption.highToLowCost) {
    final totalAmounts = <ExpenseBearingTripEntity, double>{};
    for (final expenseBearingTripEntity in allExpenses) {
      final expenseAmount = await _calculateTotalExpenseInTripCurrency(
          expenseBearingTripEntity.expense, currencyConverter);
      totalAmounts[expenseBearingTripEntity] = expenseAmount;
    }

    allExpenses.sort((a, b) {
      final aTotal = totalAmounts[a]!;
      final bTotal = totalAmounts[b]!;
      return bTotal.compareTo(aTotal);
    });
  } else if (expenseSortOption == ExpenseSortOption.newToOld) {
    final expensesWithDateTime =
        allExpenses.where((e) => e.expense.dateTime != null).toList();
    final expensesWithoutDateTime =
        allExpenses.where((e) => e.expense.dateTime == null);
    expensesWithDateTime.sort((a, b) {
      final aDate = a.expense.dateTime!;
      final bDate = b.expense.dateTime!;
      return bDate.compareTo(aDate);
    });
    return [...expensesWithDateTime, ...expensesWithoutDateTime];
  } else if (expenseSortOption == ExpenseSortOption.oldToNew) {
    final expensesWithDateTime =
        allExpenses.where((e) => e.expense.dateTime != null).toList();
    final expensesWithoutDateTime =
        allExpenses.where((e) => e.expense.dateTime == null);
    expensesWithDateTime.sort((a, b) {
      final aDate = a.expense.dateTime!;
      final bDate = b.expense.dateTime!;
      return aDate.compareTo(bDate);
    });
    return [...expensesWithDateTime, ...expensesWithoutDateTime];
  } else if (expenseSortOption == ExpenseSortOption.category) {
    allExpenses.sort((a, b) {
      final aCat = a.category.name;
      final bCat = b.category.name;
      return aCat.compareTo(bCat);
    });
  }

  return allExpenses;
}

Future<double> _calculateTotalExpenseInTripCurrency(ExpenseFacade expense,
    ApiService<(Money, String), double?> currencyConverter) async {
  final totalAmount = expense.paidBy.values
      .fold(0.0, (previousValue, element) => previousValue + element);
  var totalAmountInTripCurrency = await currencyConverter.queryData((
    Money(currency: expense.currency, amount: totalAmount),
    TestConfig.testTripCurrency
  ));
  return totalAmountInTripCurrency!;
}
