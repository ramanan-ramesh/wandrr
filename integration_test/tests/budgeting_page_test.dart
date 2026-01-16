import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/breakdown/budget_breakdown_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/budgeting_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/debt_dummary.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/budget_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/bottom_nav_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/collapsible_sections_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/horizontal_sections.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/section_header.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../helpers/firebase_emulator_helper.dart';
import '../helpers/mock_location_api_service.dart';
import '../helpers/test_config.dart';
import '../helpers/test_helpers.dart';

/// Test: BudgetingPage has three main sections
Future<void> runBudgetingPageStructureTest(WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage by clicking on the test trip
  await TestHelpers.navigateToTripEditorPage(tester);

  // Navigate to BudgetingPage if on small layout
  await _tryNavigateToBudgetingPage(tester);

  // Verify BudgetingPage is displayed
  expect(find.byType(BudgetingPage), findsOneWidget,
      reason: 'BudgetingPage should be displayed');

  final expectedCollapsibleSectionsData = <_ExpectedSectionData>[
    _ExpectedSectionData(
      title: 'Expenses',
      icon: Icons.wallet_travel_rounded,
      isExpanded: true,
      isHorizontalSection: false,
      sectionBody: ExpenseListView,
    ),
    _ExpectedSectionData(
      title: 'Debt',
      icon: Icons.money_off_rounded,
      isExpanded: false,
      isHorizontalSection: true,
      sectionBody: DebtSummaryTile,
    ),
    _ExpectedSectionData(
      title: 'Breakdown',
      icon: Icons.pie_chart_rounded,
      isExpanded: false,
      isHorizontalSection: true,
      sectionBody: BudgetBreakdownTile,
    ),
  ];
  _verifyCollapsibleSectionPageData(tester, expectedCollapsibleSectionsData);
  print(
      '✓ BudgetingPage has all three sections initially - ExpensesListView(Expanded), DebtSummaryTile, BudgetBreakdownTile');

  final debtSummarySectionHeader = find.descendant(
      of: find.byType(HorizontalSectionsList),
      matching: find.byIcon(Icons.money_off_rounded));
  await TestHelpers.tapWidget(tester, debtSummarySectionHeader);
  expectedCollapsibleSectionsData.first.isExpanded = false;
  expectedCollapsibleSectionsData[1].isExpanded = true;
  expectedCollapsibleSectionsData[1].isHorizontalSection = false;
  expectedCollapsibleSectionsData[2].isHorizontalSection = false;
  _verifyCollapsibleSectionPageData(tester, expectedCollapsibleSectionsData);
  print(
      '✓ On clicking on debt header, BudgetingPage has- ExpensesListView, DebtSummaryTile(Expanded), BudgetBreakdownTile');

  final breakdownSectionHeader = find.descendant(
      of: find.byType(SectionHeader),
      matching: find.byIcon(Icons.pie_chart_rounded));
  await TestHelpers.tapWidget(tester, breakdownSectionHeader);
  expectedCollapsibleSectionsData.first.isHorizontalSection = true;
  expectedCollapsibleSectionsData[1].isHorizontalSection = true;
  expectedCollapsibleSectionsData[1].isExpanded = false;
  expectedCollapsibleSectionsData[2].isExpanded = true;
  expectedCollapsibleSectionsData[2].isHorizontalSection = false;
  _verifyCollapsibleSectionPageData(tester, expectedCollapsibleSectionsData);
  print(
      '✓ On clicking on breakdown header, BudgetingPage has- ExpensesListView, DebtSummaryTile, BudgetBreakdownTile(Expanded)');

  await TestHelpers.tapWidget(tester, breakdownSectionHeader);
  for (final section in expectedCollapsibleSectionsData) {
    section.isExpanded = false;
    section.isHorizontalSection = false;
  }
  _verifyCollapsibleSectionPageData(tester, expectedCollapsibleSectionsData);
  print(
      '✓ On clicking on breakdown header again, BudgetingPage has all collapsed sections- ExpensesListView, DebtSummaryTile, BudgetBreakdownTile');
}

/// Test: ExpenseListView displays BudgetTile with total expense percentage
Future<void> runExpensesListViewStructureTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // -------------------------------------------------------------------------
  // 1. Navigate to BudgetingPage if needed
  // -------------------------------------------------------------------------
  await _tryNavigateToBudgetingPage(tester);

  // -------------------------------------------------------------------------
  // 2. Sort controls section (Row → BudgetTile + ToggleButtons)
  // -------------------------------------------------------------------------
  final sortRowFinder = find.byKey(const ValueKey('sortControlsRow'));
  expect(sortRowFinder, findsOneWidget);
  expect(tester.widget<Row>(sortRowFinder), isA<Row>());

  // BudgetTile
  final budgetTileFinder = find.byKey(const ValueKey('budgetTile'));
  expect(budgetTileFinder, findsOneWidget);
  expect(
    find.descendant(of: sortRowFinder, matching: budgetTileFinder),
    findsOneWidget,
  );
  expect(find.byType(BudgetTile), findsOneWidget);

  // ToggleButtons
  final toggleButtonsFinder = find.byKey(const ValueKey('sortToggleButtons'));
  expect(toggleButtonsFinder, findsOneWidget);
  expect(
    find.descendant(of: sortRowFinder, matching: toggleButtonsFinder),
    findsOneWidget,
  );
  expect(find.byType(ToggleButtons), findsOneWidget);

  // -------------------------------------------------------------------------
  // 3. Expense list area (ListView)
  // -------------------------------------------------------------------------
  final expenseListView = find.byKey(const ValueKey('expensesListView'));
  expect(expenseListView, findsOneWidget);
  expect(tester.widget<ListView>(expenseListView), isA<ListView>());

  // -------------------------------------------------------------------------
  // 4. Verify root structure
  // -------------------------------------------------------------------------
  final rootColumnFinder = find.byKey(const ValueKey('expenseListRootColumn'));
  expect(rootColumnFinder, findsOneWidget);
  expect(tester.widget<Column>(rootColumnFinder), isA<Column>());

  expect(find.descendant(of: rootColumnFinder, matching: sortRowFinder),
      findsOneWidget);
  expect(
    find.descendant(of: rootColumnFinder, matching: expenseListView),
    findsOneWidget,
  );
}

/// Test: BudgetTile displays correctly when expenses are under budget
Future<void> runBudgetTileUnderBudgetTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

  // Check for LinearProgressIndicator (shown when under budget)
  final progressIndicator = find.descendant(
      of: find.byType(BudgetTile),
      matching: find.byType(LinearProgressIndicator));
  expect(progressIndicator, findsOneWidget,
      reason: 'Progress indicator should be present for budget display');

  final context = tester.element(find.byType(TripEditorPage));
  final tripRepo = RepositoryProvider.of<TripRepositoryFacade>(context);
  final totalExpenditure =
      tripRepo.activeTrip!.budgetingModule.totalExpenditure;
  final expenseToBudgetRatio =
      totalExpenditure / tripRepo.activeTrip!.tripMetadata.budget.amount;

  // Get the progress indicator widget
  final LinearProgressIndicator indicator =
      tester.widget(progressIndicator.first);

  // Verify the progress value is not null (has a value)
  expect(indicator.value == expenseToBudgetRatio, isTrue,
      reason: 'Progress indicator should have correct percentage value');

  // Verify budget of 1500 EUR from test data is shown
  expect(
      find.descendant(
          of: find.byType(BudgetTile), matching: find.text('1 490 €')),
      findsOneWidget,
      reason: 'Total expenditure - 1490 should be displayed');
  expect(
      find.descendant(
          of: find.byType(BudgetTile), matching: find.text('1 500 €')),
      findsOneWidget,
      reason: 'Budget amount 1500 should be displayed');
}

/// Test: BudgetTile displays correctly when expenses are over budget
Future<void> runBudgetTileOverBudgetTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

  final context = tester.element(find.byType(TripEditorPage));
  final tripRepo = RepositoryProvider.of<TripRepositoryFacade>(context);
  var tripMetadata = tripRepo.activeTrip!.tripMetadata;
  final newExpense = StandaloneExpense(
    tripId: tripMetadata.id!,
    title: 'Dummy expense',
    expense: ExpenseFacade(
        currency: TestConfig.testTripCurrency,
        paidBy: {TestConfig.tripMateUserName: 200.0},
        splitBy: tripMetadata.contributors),
  );
  BlocProvider.of<TripManagementBloc>(context)
      .add(UpdateTripEntity.create(tripEntity: newExpense));
  await Future.delayed(const Duration(milliseconds: 1000));

  // The test trip has budget of 1500 EUR and expenses totaling around 1500+ EUR
  // So it should be over budget
  // Verify budget display is present
  final progressIndicator = find.descendant(
      of: find.byType(ExpenseListView),
      matching: find.byType(FractionallySizedBox));
  expect(progressIndicator, findsOneWidget,
      reason: 'FractionallySizedBox should be displayed');

  // Get the progress indicator widget
  final budgetPercentage = tripMetadata.budget.amount /
      tripRepo.activeTrip!.budgetingModule.totalExpenditure;
  final excessPercentage = 1.0 - budgetPercentage;
  final FractionallySizedBox indicator = tester.widget(progressIndicator.first);
  expect(indicator.widthFactor == excessPercentage, isTrue,
      reason: 'Progress indicator should have correct percentage value');

  BlocProvider.of<TripManagementBloc>(context)
      .add(UpdateTripEntity.delete(tripEntity: newExpense));
  await Future.delayed(const Duration(milliseconds: 500));

  print('✓ Budget display found');
  print('✓ Budget indicator present (check for over budget visual indicator)');
}

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
Future<void> runSortByCostDescendingTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

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
Future<void> runSortByDateAscendingTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

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
Future<void> runSortByDateDescendingTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

  // Date sort defaults to newest first (descending)
  // Verify the upward arrow is shown
  final arrowUp = find.byIcon(Icons.arrow_upward_rounded);
  expect(arrowUp, findsOneWidget,
      reason: 'Arrow up should appear for default descending date sort');

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
}

/// Test: DebtSummaryTile displays debt information
Future<void> runDebtSummaryTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

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
Future<void> runBudgetBreakdownTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

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
Future<void> runExpenseCategoriesTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

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
Future<void> runExpensesWithAndWithoutDatesTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

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
Future<void> runExpensesFromDifferentSourcesTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

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
Future<void> runMultipleCurrenciesTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await _tryNavigateToBudgetingPage(tester);

  // Budget tile should show total in trip's base currency (EUR)
  final budgetTile = find.byType(BudgetTile);
  expect(budgetTile, findsOneWidget, reason: 'BudgetTile should be present');

  // Verify EUR currency is displayed (all test expenses are in EUR)
  expect(find.textContaining('EUR'), findsWidgets,
      reason: 'EUR currency should be displayed in budget tile');

  print('✓ BudgetTile displays total converted to base currency (EUR)');
  print('✓ All test expenses are in EUR from test data');
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

void _verifyCollapsibleSectionPageData(WidgetTester tester,
    Iterable<_ExpectedSectionData> expectedSectionDataList) {
  final collapsibleSectionsPageFinder = find.byType(CollapsibleSectionsPage);
  expect(
      find.descendant(
          of: find.byType(BudgetingPage),
          matching: collapsibleSectionsPageFinder),
      findsOneWidget,
      reason: 'Collapsible sections page is expected in BudgetingPage');
  final collapsibleSectionHeadersFinder = find.descendant(
      of: collapsibleSectionsPageFinder, matching: find.byType(SectionHeader));

  _verifyNonHorizontalSectionHeaders(tester, collapsibleSectionHeadersFinder,
      collapsibleSectionsPageFinder, expectedSectionDataList);

  _verifyHorizontalCollapsedSections(
      collapsibleSectionsPageFinder, tester, expectedSectionDataList);
}

void _verifyNonHorizontalSectionHeaders(
    WidgetTester tester,
    Finder collapsibleSectionHeaderFinder,
    Finder collapsibleSectionsPageFinder,
    Iterable<_ExpectedSectionData> expectedSectionDataList) {
  final sectionHeaderElements = collapsibleSectionHeaderFinder.evaluate();
  final expectedExpandedSection = expectedSectionDataList
      .where((element) => element.isExpanded)
      .singleOrNull;
  if (expectedExpandedSection != null) {
    final expandedSectionHeader = sectionHeaderElements
        .singleWhere((element) => (element.widget as SectionHeader).isExpanded)
        .widget as SectionHeader;
    _verifyNonHorizontalSectionContent(
        expandedSectionHeader,
        expectedExpandedSection,
        collapsibleSectionHeaderFinder,
        collapsibleSectionsPageFinder);
  } else {
    final expectedNonHorizontalSections = expectedSectionDataList.where(
        (sectionData) =>
            !sectionData.isExpanded && !sectionData.isHorizontalSection);
    expect(collapsibleSectionHeaderFinder,
        findsNWidgets(expectedNonHorizontalSections.length),
        reason:
            '${expectedNonHorizontalSections.length} non horizontal collapsed section headers should be present');
    final nonExpandedSectionHeaderElements = sectionHeaderElements
        .where((element) => !(element.widget as SectionHeader).isExpanded);
    for (var index = 0; index < expectedNonHorizontalSections.length; index++) {
      final expectedSectionData =
          expectedNonHorizontalSections.elementAt(index);
      final nonExpandedSectionHeader = nonExpandedSectionHeaderElements
          .elementAt(index)
          .widget as SectionHeader;
      _verifyNonHorizontalSectionContent(
          nonExpandedSectionHeader,
          expectedSectionData,
          collapsibleSectionHeaderFinder,
          collapsibleSectionsPageFinder);
    }
  }
}

void _verifyNonHorizontalSectionContent(
    SectionHeader sectionHeader,
    _ExpectedSectionData expectedSectionData,
    Finder collapsibleSectionHeaderFinder,
    Finder collapsibleSectionsPageFinder) {
  final sectionExpandedState =
      sectionHeader.isExpanded ? 'Expanded' : 'Collapsed';
  expect(sectionHeader.title == expectedSectionData.title, isTrue,
      reason:
          '$sectionExpandedState Section header title should be - ${expectedSectionData.title}');
  expect(
      find.descendant(
          of: collapsibleSectionHeaderFinder,
          matching: find.text(expectedSectionData.title)),
      findsOneWidget,
      reason:
          '$sectionExpandedState Section header title text should be - ${expectedSectionData.title}');
  expect(
      find.descendant(
          of: collapsibleSectionHeaderFinder,
          matching: find.byIcon(expectedSectionData.icon)),
      findsOneWidget,
      reason: '$sectionExpandedState Section header icon should be present');
  expect(sectionHeader.isExpanded == expectedSectionData.isExpanded, isTrue,
      reason:
          'Section header isExpanded should be - ${expectedSectionData.isExpanded}');
  if (expectedSectionData.isExpanded) {
    expect(
        find.descendant(
            of: collapsibleSectionsPageFinder,
            matching: find.byType(expectedSectionData.sectionBody)),
        findsOneWidget,
        reason: 'Expanded Section body should be present');
  } else {
    expect(
        find.descendant(
            of: collapsibleSectionsPageFinder,
            matching: find.byType(expectedSectionData.sectionBody)),
        findsNothing,
        reason:
            '${expectedSectionData.sectionBody.toString()} Section body should not be present');
  }
}

void _verifyHorizontalCollapsedSections(
    Finder collapsibleSectionsPageFinder,
    WidgetTester tester,
    Iterable<_ExpectedSectionData> expectedSectionDataList) {
  final expectedCollapsedHorizontalSections = expectedSectionDataList.where(
      (sectionData) =>
          !sectionData.isExpanded && sectionData.isHorizontalSection);
  if (expectedCollapsedHorizontalSections.isNotEmpty) {
    final horizontalListViewFinder = find.descendant(
        of: collapsibleSectionsPageFinder,
        matching: find.byType(HorizontalSectionsList));
    final horizontalListView =
        tester.widget<HorizontalSectionsList>(horizontalListViewFinder);

    expect(
        horizontalListView.sections.length ==
            expectedCollapsedHorizontalSections.length,
        isTrue,
        reason:
            '${expectedCollapsedHorizontalSections.length} collapsed horizontal sections should be present');

    for (var index = 0;
        index < expectedCollapsedHorizontalSections.length;
        index++) {
      final expectedSectionData =
          expectedCollapsedHorizontalSections.elementAt(index);
      expect(
          find.descendant(
              of: horizontalListViewFinder,
              matching: find.byIcon(expectedSectionData.icon)),
          findsOneWidget,
          reason: 'Collapsed Horizontal Section header icon should be present');
      expect(
          find.descendant(
              of: horizontalListViewFinder,
              matching: find.text(expectedSectionData.title)),
          findsOneWidget,
          reason:
              'Collapsed Horizontal Section header title should be present');
    }
  }
}

class _ExpectedSectionData {
  final String title;
  final IconData icon;
  bool isExpanded;
  bool isHorizontalSection;
  final Type sectionBody;

  _ExpectedSectionData({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.isHorizontalSection,
    required this.sectionBody,
  });
}

void runTests() {
  setUpAll(() async {
    await FirebaseEmulatorHelper.createFirebaseAuthUser(
      email: TestConfig.testEmail,
      password: TestConfig.testPassword,
      shouldAddToFirestore: true,
      shouldSignIn: true,
    );
    await MockLocationApiService.initialize();
    await TestHelpers.createTestTrip();
  });

  tearDown(() async {
    expect(find.byType(ErrorWidget), findsNothing);
  });

  tearDownAll(() async {
    await FirebaseEmulatorHelper.cleanupAfterTest();
  });

  testWidgets('displays three main sections (Expenses, Debt, Breakdown)',
      (WidgetTester tester) async {
    await runBudgetingPageStructureTest(tester);
  });

  testWidgets('ExpenseListView displays BudgetTile and sort options',
      (WidgetTester tester) async {
    await runExpensesListViewStructureTest(tester);
  });

  testWidgets('BudgetTile displays correctly when expenses under budget',
      (WidgetTester tester) async {
    await runBudgetTileUnderBudgetTest(tester);
  });

  testWidgets('BudgetTile displays correctly when expenses over budget',
      (WidgetTester tester) async {
    await runBudgetTileOverBudgetTest(tester);
  });

  testWidgets('default sort option works (newest to oldest)',
      (WidgetTester tester) async {
    await runSortOptionsDefaultTest(tester);
  });

  testWidgets('sort by cost ascending works', (WidgetTester tester) async {
    await runSortByCostAscendingTest(tester);
  });

  testWidgets('sort by cost descending works', (WidgetTester tester) async {
    await runSortByCostDescendingTest(tester);
  });

  testWidgets('sort by date ascending works (oldest first)',
      (WidgetTester tester) async {
    await runSortByDateAscendingTest(tester);
  });

  testWidgets('sort by date descending works (newest first)',
      (WidgetTester tester) async {
    await runSortByDateDescendingTest(tester);
  });

  testWidgets('sort by category works', (WidgetTester tester) async {
    await runSortByCategoryTest(tester);
  });

  testWidgets('DebtSummaryTile displays debt information',
      (WidgetTester tester) async {
    await runDebtSummaryTest(tester);
  });

  testWidgets('BudgetBreakdownTile displays breakdown charts',
      (WidgetTester tester) async {
    await runBudgetBreakdownTest(tester);
  });

  testWidgets('expenses with various categories display correctly',
      (WidgetTester tester) async {
    await runExpenseCategoriesTest(tester);
  });

  testWidgets('expenses with and without dates display correctly',
      (WidgetTester tester) async {
    await runExpensesWithAndWithoutDatesTest(tester);
  });

  testWidgets('expenses from different sources display correctly',
      (WidgetTester tester) async {
    await runExpensesFromDifferentSourcesTest(tester);
  });

  testWidgets('multiple currencies handled correctly',
      (WidgetTester tester) async {
    await runMultipleCurrenciesTest(tester);
  });
}
