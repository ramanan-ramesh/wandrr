import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';

import '../../helpers/facade_matchers.dart';
import '../../helpers/test_helpers.dart';
import 'helpers.dart';

/// Test: Sort options - Default sort (newToOld)
Future<void> runSortOptionsDefaultTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await tryNavigateToBudgetingPage(tester);

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

  await tryNavigateToBudgetingPage(tester);

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

  await tryNavigateToBudgetingPage(tester);

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

  await tryNavigateToBudgetingPage(tester);

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

  await tryNavigateToBudgetingPage(tester);

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

  await tryNavigateToBudgetingPage(tester);

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

Future<void> _verifyExpensesOrder(
    WidgetTester tester, ExpenseSortOption sortOption) async {
  final expectedExpensesOrder =
      await getSortedExpensesFromRepository(tester, sortOption);
  final readonlyExpenseListItems = await collectExpenseListItemsFromUI(tester,
      numberOfExpectedExpenses: expectedExpensesOrder.length);
  final uiExpenses =
      readonlyExpenseListItems.map((e) => e.expenseBearingTripEntity).toList();

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
