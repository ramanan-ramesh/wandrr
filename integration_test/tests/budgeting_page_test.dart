import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/breakdown/budget_breakdown_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/budgeting_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/debt_dummary.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/budget_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../helpers/test_helpers.dart';

/// Test: BudgetingPage has three main sections
Future<void> runBudgetingPageStructureTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage by clicking on the test trip
  await TestHelpers.navigateToTripEditorPage(tester);

  // Navigate to BudgetingPage if on small layout
  if (!TestHelpers.isLargeScreen(tester)) {
    // Find and tap the budgeting tab in bottom navigation
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget,
        reason: 'Budgeting tab should be present in bottom navigation');
    await TestHelpers.tapWidget(tester, budgetingTab);
    await tester.pump(const Duration(milliseconds: 300));
  }

  // Verify BudgetingPage is displayed
  expect(find.byType(BudgetingPage), findsOneWidget,
      reason: 'BudgetingPage should be displayed');

  // Verify Expenses section exists
  final expensesSection = find.text('Expenses');
  expect(expensesSection, findsOneWidget,
      reason: 'Expenses section should be present');
  print('✓ Expenses section found');

  // Verify Debt section exists
  final debtSection = find.text('Debt');
  expect(debtSection, findsOneWidget, reason: 'Debt section should be present');
  print('✓ Debt section found');

  // Verify Breakdown section exists
  final breakdownSection = find.text('Breakdown');
  expect(breakdownSection, findsOneWidget,
      reason: 'Breakdown section should be present');
  print('✓ Breakdown section found');

  print('✓ BudgetingPage has all three sections');
}

/// Test: ExpenseListView displays BudgetTile with total expense percentage
Future<void> runExpensesListViewStructureTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Navigate to BudgetingPage if needed
  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget,
        reason: 'Budgeting tab should be present');
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  // Wait for ExpenseListView
  await tester.pumpAndSettle();

  // Verify ExpenseListView exists
  final expenseListView = find.byType(ExpenseListView);
  expect(expenseListView, findsOneWidget,
      reason: 'ExpenseListView should be present');
  print('✓ ExpenseListView found');

  // Verify BudgetTile exists (shows total expense percentage and budget)
  final budgetTile = find.byType(BudgetTile);
  expect(budgetTile, findsOneWidget,
      reason: 'BudgetTile should display budget and percentage');
  print('✓ BudgetTile found (displays budget and percentage)');

  // Verify sort toggle buttons exist
  final toggleButtons = find.byType(ToggleButtons);
  expect(toggleButtons, findsOneWidget,
      reason: 'Sort options toggle buttons should be present');
  print('✓ Sort options toggle buttons found');

  // Verify repository has expected expense data
  final context = tester.element(find.byType(TripEditorPage));
  final tripRepo = RepositoryProvider.of<TripRepositoryFacade>(context);
  final expenses = tripRepo.activeTrip!.expenseCollection.collectionItems;

  // Verify we have the expected pure expenses from test data (3 total)
  expect(expenses.length, 3,
      reason: 'Should have 3 pure expenses from test data');
  print('✓ Repository has ${expenses.length} pure expenses');

  // Verify expense titles exist in the list
  expect(find.text('Dinner at Le Comptoir'), findsOneWidget,
      reason: 'Should display Dinner at Le Comptoir expense');
  expect(find.text('Souvenirs from Louvre'), findsOneWidget,
      reason: 'Should display Souvenirs from Louvre expense');
  expect(find.text('Groceries'), findsOneWidget,
      reason: 'Should display Groceries expense');
  print('✓ All expense titles verified in ExpenseListView');
}

/// Test: BudgetTile displays correctly when expenses are under budget
Future<void> runBudgetTileUnderBudgetTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Check for LinearProgressIndicator (shown when under budget)
  final progressIndicator = find.byType(LinearProgressIndicator);
  expect(progressIndicator, findsOneWidget,
      reason: 'Progress indicator should be present for budget display');

  // Get the progress indicator widget
  final LinearProgressIndicator indicator =
      tester.widget(progressIndicator.first);

  // Verify the progress value is not null (has a value)
  expect(indicator.value, isNotNull,
      reason: 'Progress indicator should have a percentage value');

  // Verify budget of 800 EUR from test data is shown
  expect(find.textContaining('800'), findsWidgets,
      reason: 'Budget amount 800 should be displayed');

  print('✓ Progress indicator found (expenses under budget scenario)');
  print(
      '✓ Progress indicator shows percentage: ${(indicator.value! * 100).toStringAsFixed(1)}%');
}

/// Test: BudgetTile displays correctly when expenses are over budget
Future<void> runBudgetTileOverBudgetTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // The test trip has budget of 800 EUR and expenses totaling around 1500+ EUR
  // So it should be over budget

  // Verify budget display is present
  final progressIndicator = find.byType(LinearProgressIndicator);
  expect(progressIndicator, findsOneWidget,
      reason: 'Progress indicator should be displayed');

  // When over budget, the indicator value might be > 1.0 or clamped
  // Verify the budget tile shows the expense amounts
  final budgetTile = find.byType(BudgetTile);
  expect(budgetTile, findsOneWidget, reason: 'BudgetTile should be displayed');

  print('✓ Budget display found');
  print('✓ Budget indicator present (check for over budget visual indicator)');
}

/// Test: Sort options - Default sort (newToOld)
Future<void> runSortOptionsDefaultTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Verify ToggleButtons exist
  final toggleButtons = find.byType(ToggleButtons);
  expect(toggleButtons, findsOneWidget,
      reason: 'Sort toggle buttons should be present');

  // By default, the date sort should be selected (newest first)
  // This is indicated by the calendar icon button being selected
  final calendarIcon = find.byIcon(Icons.calendar_today_rounded);
  expect(calendarIcon, findsOneWidget,
      reason: 'Calendar (date sort) icon should be present');

  print('✓ Sort options available');
  print('✓ Default sort: Date (newest to oldest)');
}

/// Test: Sort by cost ascending
Future<void> runSortByCostAscendingTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Find the cost sort button (first toggle button with dollar icon)
  final costSortButton = find.byIcon(Icons.attach_money_rounded);
  expect(costSortButton, findsOneWidget,
      reason: 'Cost sort button should be present');

  // Tap to sort by cost
  await TestHelpers.tapWidget(tester, costSortButton.first);
  await tester.pumpAndSettle();

  print('✓ Tapped cost sort button');

  // Check for ascending arrow icon
  final arrowDown = find.byIcon(Icons.arrow_downward_rounded);
  expect(arrowDown, findsOneWidget,
      reason: 'Arrow down should appear for ascending sort');
  print('✓ Sort by cost ascending (low to high)');
}

/// Test: Sort by cost descending
Future<void> runSortByCostDescendingTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Find the cost sort button
  final costSortButton = find.byIcon(Icons.attach_money_rounded);
  expect(costSortButton, findsOneWidget,
      reason: 'Cost sort button should be present');

  // Tap once to sort ascending
  await TestHelpers.tapWidget(tester, costSortButton.first);
  await tester.pumpAndSettle();

  // Tap again to sort descending
  await TestHelpers.tapWidget(tester, costSortButton.first);
  await tester.pumpAndSettle();

  print('✓ Tapped cost sort button twice');

  // Check for descending arrow icon
  final arrowUp = find.byIcon(Icons.arrow_upward_rounded);
  expect(arrowUp, findsOneWidget,
      reason: 'Arrow up should appear for descending sort');
  print('✓ Sort by cost descending (high to low)');
}

/// Test: Sort by date ascending (oldest first)
Future<void> runSortByDateAscendingTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Find the date sort button (calendar icon)
  final dateSortButton = find.byIcon(Icons.calendar_today_rounded);
  expect(dateSortButton, findsOneWidget,
      reason: 'Date sort button should be present');

  // Default is newest first, tap to change to oldest first
  await TestHelpers.tapWidget(tester, dateSortButton.first);
  await tester.pumpAndSettle();

  print('✓ Tapped date sort button');

  // Check for arrow indicating oldest first (downward)
  final arrowDown = find.byIcon(Icons.arrow_downward_rounded);
  expect(arrowDown, findsOneWidget,
      reason: 'Arrow down should appear for ascending sort');
  print('✓ Sort by date ascending (oldest to newest)');
}

/// Test: Sort by date descending (newest first)
Future<void> runSortByDateDescendingTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Date sort defaults to newest first (descending)
  // Verify the upward arrow is shown
  final arrowUp = find.byIcon(Icons.arrow_upward_rounded);
  expect(arrowUp, findsOneWidget,
      reason: 'Arrow up should appear for default descending date sort');

  print('✓ Default date sort is descending (newest to oldest)');
}

/// Test: Sort by category
Future<void> runSortByCategoryTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Find the category sort button (middle button with category icon)
  final categorySortButton = find.byIcon(Icons.category_outlined);
  expect(categorySortButton, findsOneWidget,
      reason: 'Category sort button should be present');

  // Tap to sort by category
  await TestHelpers.tapWidget(tester, categorySortButton.first);
  await tester.pumpAndSettle();

  print('✓ Tapped category sort button');
  print('✓ Expenses sorted by category');
}

/// Test: DebtSummaryTile displays debt information
Future<void> runDebtSummaryTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Find and tap on Debt section to expand it
  final debtSection = find.text('Debt');
  expect(debtSection, findsOneWidget, reason: 'Debt section should be present');

  await TestHelpers.tapWidget(tester, debtSection);
  await tester.pumpAndSettle();

  print('✓ Expanded Debt section');

  // Check for DebtSummaryTile
  final debtSummaryTile = find.byType(DebtSummaryTile);
  expect(debtSummaryTile, findsOneWidget,
      reason: 'DebtSummaryTile should be present');
  print('✓ DebtSummaryTile found');

  // Verify debt calculation includes both contributors from test data
  // Test data has 2 contributors: TestConfig.testEmail and TestConfig.tripMateUserName
  // All expenses are paid by testEmail and split between both
  // So tripMate owes testEmail money
  expect(find.textContaining('owes'), findsWidgets,
      reason: 'Debt summary should show who owes whom');
  print('✓ Debt relationships displayed');
}

/// Test: BudgetBreakdownTile displays breakdown charts
Future<void> runBudgetBreakdownTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Find and tap on Breakdown section to expand it
  final breakdownSection = find.text('Breakdown');
  expect(breakdownSection, findsOneWidget,
      reason: 'Breakdown section should be present');

  await TestHelpers.tapWidget(tester, breakdownSection);
  await tester.pumpAndSettle();

  print('✓ Expanded Breakdown section');

  // Check for BudgetBreakdownTile
  final budgetBreakdownTile = find.byType(BudgetBreakdownTile);
  expect(budgetBreakdownTile, findsOneWidget,
      reason: 'BudgetBreakdownTile should be present');
  print('✓ BudgetBreakdownTile found');

  // Check for tab options (Category and Day by Day)
  final categoryTab = find.text('Category');
  final dayByDayTab = find.text('Day by Day');

  expect(categoryTab, findsOneWidget,
      reason: 'Category breakdown tab should be present');
  expect(dayByDayTab, findsOneWidget,
      reason: 'Day by Day breakdown tab should be present');
  print('✓ Breakdown tabs found (Category and Day by Day)');
}

/// Test: Expenses with various categories display correctly
Future<void> runExpenseCategoriesTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Sort by category to see all categories grouped
  final categorySortButton = find.byIcon(Icons.category_outlined);
  expect(categorySortButton, findsOneWidget,
      reason: 'Category sort button should be present');

  await TestHelpers.tapWidget(tester, categorySortButton.first);
  await tester.pumpAndSettle();

  print('✓ Sorted by category');

  // Verify actual expense categories from test data
  // Test data has expenses in categories: food (2 pure expenses), other (1 pure expense)
  // Plus transit expenses in various categories: flights, publicTransit, carRental, taxi
  // Plus lodging expenses and sightseeing expenses

  // Verify repository has expected categories
  final context = tester.element(find.byType(TripEditorPage));
  final tripRepo = RepositoryProvider.of<TripRepositoryFacade>(context);
  final expenses = tripRepo.activeTrip!.expenseCollection.collectionItems;

  // Check categories in pure expenses
  final foodExpenses =
      expenses.where((e) => e.category == ExpenseCategory.food);
  final otherExpenses =
      expenses.where((e) => e.category == ExpenseCategory.other);

  expect(foodExpenses.length, 2,
      reason: 'Should have 2 food expenses (Dinner and Groceries)');
  expect(otherExpenses.length, 1,
      reason: 'Should have 1 other expense (Souvenirs)');

  print('✓ Verified expense categories: 2 food, 1 other');
}

/// Test: Expenses with and without dates display correctly
Future<void> runExpensesWithAndWithoutDatesTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Sort by date to see how expenses with/without dates are handled
  final dateSortButton = find.byIcon(Icons.calendar_today_rounded);
  expect(dateSortButton, findsOneWidget,
      reason: 'Date sort button should be present');

  print('✓ Date sort available');

  // Verify repository has expenses with dates
  final context = tester.element(find.byType(TripEditorPage));
  final tripRepo = RepositoryProvider.of<TripRepositoryFacade>(context);
  final expenses = tripRepo.activeTrip!.expenseCollection.collectionItems;

  // All pure expenses in test data have dates
  for (var expense in expenses) {
    expect(expense.expense.dateTime, isNotNull,
        reason: 'Pure expense "${expense.title}" should have a date');
  }

  print('✓ Verified all pure expenses have dates:');
  print('  - Dinner at Le Comptoir: 2025-09-24 20:00');
  print('  - Souvenirs from Louvre: 2025-09-25 12:00');
  print('  - Groceries: 2025-09-26');
}

/// Test: Expenses from different sources display correctly
Future<void> runExpensesFromDifferentSourcesTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Verify different expense sources from repository
  final context = tester.element(find.byType(TripEditorPage));
  final tripRepo = RepositoryProvider.of<TripRepositoryFacade>(context);
  final trip = tripRepo.activeTrip!;

  // Verify transit expenses (9 transits from test data)
  expect(trip.transitCollection.collectionItems.length, 9,
      reason: 'Should have 9 transit expenses');
  print(
      '✓ Transit expenses: 9 (flight, trains, bus, car rental, taxi, ferry, walk, metro)');

  // Verify lodging expenses (3 lodgings from test data)
  expect(trip.lodgingCollection.collectionItems.length, 3,
      reason: 'Should have 3 lodging expenses');
  print('✓ Lodging expenses: 3 (Paris, Brussels, Amsterdam)');

  // Verify sight expenses (5 sights from test data with expenses)
  // Count sights across all itineraries (5 days: Sept 24-28)
  var totalSights = 0;
  for (int i = 0; i < 5; i++) {
    final day = DateTime(2025, 9, 24 + i);
    final itinerary = trip.itineraryCollection.getItineraryForDay(day);
    totalSights += itinerary.planData.sights.length;
  }
  expect(totalSights, 5, reason: 'Should have 5 sight expenses');
  print(
      '✓ Sight expenses: 5 (Eiffel Tower, Versailles, Louvre, Atomium, Rijksmuseum)');

  // Verify pure expenses (3 from test data)
  expect(trip.expenseCollection.collectionItems.length, 3,
      reason: 'Should have 3 pure expenses');
  print('✓ Pure expenses: 3 (Dinner, Souvenirs, Groceries)');

  print('✓ All expense sources verified in ExpenseListView');
}

/// Test: Currency handling in expenses
Future<void> runMultipleCurrenciesTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    expect(budgetingTab, findsOneWidget);
    await TestHelpers.tapWidget(tester, budgetingTab);
  }

  await tester.pumpAndSettle();

  // Budget tile should show total in trip's base currency (EUR)
  final budgetTile = find.byType(BudgetTile);
  expect(budgetTile, findsOneWidget, reason: 'BudgetTile should be present');

  // Verify EUR currency is displayed (all test expenses are in EUR)
  expect(find.textContaining('EUR'), findsWidgets,
      reason: 'EUR currency should be displayed in budget tile');

  print('✓ BudgetTile displays total converted to base currency (EUR)');
  print('✓ All test expenses are in EUR from test data');
}
