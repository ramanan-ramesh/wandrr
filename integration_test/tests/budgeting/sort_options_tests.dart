import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/readonly_expense.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/bottom_nav_bar.dart';

import '../../helpers/facade_matchers.dart';
import '../../helpers/test_config.dart';
import '../../helpers/test_helpers.dart';

/// Test: Sort options - Default sort (newToOld)
Future<void> runSortOptionsDefaultTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

  // Verify ToggleButtons exist
  final sortToggleButtonsContainer = find.byKey(ValueKey('sortToggleButtons'));

  //Verify sort by cost button
  final sortByCostButtonContainer = find.descendant(
      of: sortToggleButtonsContainer,
      matching: find.byKey(ValueKey('expenseListView_sortByCost')));
  final sortByCostAscendingButton = find.descendant(
      of: sortByCostButtonContainer,
      matching: find.byIcon(Icons.arrow_downward_rounded));
  expect(
      find.descendant(
          of: sortByCostButtonContainer,
          matching: find.byIcon(Icons.attach_money_rounded)),
      findsOneWidget,
      reason: 'Cost sort button should be present');
  expect(sortByCostAscendingButton, findsOneWidget,
      reason: 'Default sort option for cost must be ascending order');

  // By default, the date sort should be selected (newest first)
  // This is indicated by the calendar icon button being selected
  final sortByDateButtonContainer = find.descendant(
      of: sortToggleButtonsContainer,
      matching: find.byKey(ValueKey('expenseListView_sortByDate')));
  final sortByDateNewestFirstButton = find.descendant(
      of: sortByDateButtonContainer,
      matching: find.byIcon(Icons.arrow_upward_rounded));
  expect(
      find.descendant(
          of: sortByDateButtonContainer,
          matching: find.byIcon(Icons.calendar_today_rounded)),
      findsOneWidget,
      reason: 'Date sort button should be present');
  expect(sortByDateNewestFirstButton, findsOneWidget,
      reason: 'Default sort option for date must be newest first');

  //Sort by category button
  expect(
      find.descendant(
          of: sortToggleButtonsContainer,
          matching: find.byIcon(Icons.category_outlined)),
      findsOneWidget,
      reason: 'Category sort button should be present');

  print(
      '✓ Sort options available - Cost(Lowest first), Category, Date(Newest First)');
}

/// Test: Sort by cost ascending
Future<void> runSortByCostAscendingTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

  // Find the cost sort button (first toggle button with dollar icon)
  final costSortButton = find.byIcon(Icons.attach_money_rounded);
  expect(costSortButton, findsOneWidget,
      reason: 'Cost sort button should be present');
  await TestHelpers.tapWidget(tester, costSortButton);
  final arrowDown = find.descendant(
      of: find.byKey(ValueKey('expenseListView_sortByCost')),
      matching: find.byIcon(Icons.arrow_downward_rounded));
  expect(arrowDown, findsOneWidget,
      reason: 'Arrow down should appear for ascending sort');
  print('✓ Sort by cost ascending (low to high) by default');

  await _verifyExpensesOrder(tester, ExpenseSortOption.lowToHighCost);
  print('✓ Expenses sorted by cost (low to high)');
}

/// Test: Sort by cost descending
Future<void> runSortByCostDescendingTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

  // Find the cost sort button
  final costSortButton = find.byIcon(Icons.attach_money_rounded);
  await TestHelpers.tapWidget(tester, costSortButton);
  await TestHelpers.tapWidget(tester, costSortButton);
  final arrowUp = find.descendant(
      of: find.byKey(ValueKey('expenseListView_sortByCost')),
      matching: find.byIcon(Icons.arrow_upward_rounded));
  expect(arrowUp, findsOneWidget,
      reason: 'Arrow up should appear for descending sort');
  print('✓ Sort by cost descending (high to low)');

  await _verifyExpensesOrder(tester, ExpenseSortOption.highToLowCost);
  print('✓ Expenses sorted by cost (high to low)');
}

/// Test: Sort by date ascending (oldest first)
Future<void> runSortByDateAscendingTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

  // Find the date sort button (calendar icon)
  final dateSortButton = find.byKey(ValueKey('expenseListView_sortByDate'));
  await TestHelpers.tapWidget(tester, dateSortButton);
  final arrowDown = find.descendant(
      of: dateSortButton, matching: find.byIcon(Icons.arrow_downward_rounded));
  expect(arrowDown, findsOneWidget,
      reason: 'Arrow down should appear for ascending sort');
  print('✓ Sort by date ascending (oldest to newest)');

  await _verifyExpensesOrder(tester, ExpenseSortOption.oldToNew);
  print('✓ Expenses sorted by date (oldest first)');
}

/// Test: Sort by date descending (newest first)
Future<void> runSortByDateDescendingTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

  // Date sort defaults to newest first (descending)
  // Verify the upward arrow is shown
  final dateSortButton = find.byKey(ValueKey('expenseListView_sortByDate'));
  final arrowUp = find.descendant(
      of: dateSortButton, matching: find.byIcon(Icons.arrow_upward_rounded));
  expect(arrowUp, findsOneWidget,
      reason: 'Arrow up should appear for default descending date sort');

  await _verifyExpensesOrder(tester, ExpenseSortOption.newToOld);
  print('✓ Default date sort is descending (newest to oldest)');
}

/// Test: Sort by category
Future<void> runSortByCategoryTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

  // Find the category sort button (middle button with category icon)
  final categorySortButton = find.byIcon(Icons.category_outlined);
  expect(categorySortButton, findsOneWidget,
      reason: 'Category sort button should be present');

  // Tap to sort by category
  await TestHelpers.tapWidget(tester, categorySortButton.first);
  await tester.pumpAndSettle();

  print('✓ Tapped category sort button');
  print('✓ Expenses sorted by category');

  await _verifyExpensesOrder(tester, ExpenseSortOption.category);
  print('✓ Expenses sorted by category');
}

Future<void> _tryNavigateToBudgetingPage(WidgetTester tester) async {
  if (!TestHelpers.isLargeScreen(tester)) {
    // Find and tap the budgeting tab in bottom navigation
    final budgetingTab = find.descendant(
        of: find.byType(BottomNavBar),
        matching: find.byIcon(Icons.wallet_travel_rounded));
    await TestHelpers.tapWidget(tester, budgetingTab);
  }
}

Future<void> _verifyExpensesOrder(
    WidgetTester tester, ExpenseSortOption sortOption) async {
  final expectedExpensesOrder =
      await _getSortedExpensesFromRepository(tester, sortOption);
  final uiExpenses =
      await _collectExpensesFromUI(tester, expectedExpensesOrder.length);

  expect(uiExpenses.length == expectedExpensesOrder.length, isTrue,
      reason: 'UI expenses should match repository expenses');

  if (sortOption == ExpenseSortOption.newToOld ||
      sortOption == ExpenseSortOption.oldToNew) {
    expectedExpensesOrder
        .removeWhere((expense) => expense.expense.dateTime == null);
  }

  for (var index = 0; index < expectedExpensesOrder.length; index++) {
    final expectedExpense = expectedExpensesOrder[index];
    Matcher? expenseMatcher;
    final uiExpense = uiExpenses[index];
    if (expectedExpense is TransitFacade && uiExpense is TransitFacade) {
      expenseMatcher = matchesTransit(expectedExpense);
    } else if (expectedExpense is LodgingFacade && uiExpense is LodgingFacade) {
      expenseMatcher = matchesLodging(expectedExpense);
    } else if (expectedExpense is StandaloneExpense &&
        uiExpense is StandaloneExpense) {
      expenseMatcher = matchesStandaloneExpense(expectedExpense);
    } else if (expectedExpense is SightFacade && uiExpense is SightFacade) {
      expenseMatcher = matchesSight(expectedExpense);
    } else {
      fail(' The expense type at $index from the ListView is not correct');
    }

    expect(uiExpense, expenseMatcher,
        reason: 'UI expenses should match repository expenses');
  }
}

Future<List<ExpenseBearingTripEntity>> _collectExpensesFromUI(
    WidgetTester tester, int numberOfExpectedExpenses) async {
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
        ? widget.expenseBearingTripEntity.title
        : widget.expenseBearingTripEntity.id!,
    expectedCount: numberOfExpectedExpenses,
    timeout: const Duration(seconds: 30),
  );

  return expenseWidgets.map((e) => e.expenseBearingTripEntity).toList();
}

Future<List<ExpenseBearingTripEntity>> _getSortedExpensesFromRepository(
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
