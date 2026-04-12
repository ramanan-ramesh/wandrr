import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/breakdown/breakdown_by_category.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/breakdown/breakdown_by_day.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/breakdown/budget_breakdown_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/budget_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/horizontal_sections.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';
import 'package:wandrr/presentation/trip/widgets/contributor_badge.dart';

import '../../helpers/firebase_emulator_helper.dart';
import '../../helpers/http_overrides/mock_location_api_service.dart';
import '../../helpers/test_config.dart';
import '../../helpers/test_helpers.dart';
import 'expense_list_item_test.dart';
import 'helpers.dart';
import 'layout_structure_tests.dart';
import 'sort_options_tests.dart';

/// Test: BudgetTile displays correctly when expenses are under budget
Future<void> runBudgetTileUnderBudgetTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await tryNavigateToBudgetingPage(tester);
  print('✓ Navigated to Budgeting page');

  // Check for LinearProgressIndicator (shown when under budget)
  final progressIndicator = find.descendant(
      of: find.byType(BudgetTile),
      matching: find.byType(LinearProgressIndicator));
  expect(progressIndicator, findsOneWidget,
      reason: 'Progress indicator should be present for budget display');

  final tripRepo = TestHelpers.getTripRepository(tester);
  final totalExpenditure =
      tripRepo.activeTrip!.budgetingModule.totalExpenditure;
  final expenseToBudgetRatio =
      totalExpenditure / tripRepo.activeTrip!.tripMetadata.budget.amount;

  // Get the progress indicator widget
  final indicator =
      tester.widget<LinearProgressIndicator>(progressIndicator.first);

  // Verify the progress value is not null (has a value)
  expect(indicator.value == expenseToBudgetRatio, isTrue,
      reason: 'Progress indicator should have correct percentage value');
  print(
      '✓ Budget progress indicator correct (${(expenseToBudgetRatio * 100).toStringAsFixed(1)}% used)');

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

  await tryNavigateToBudgetingPage(tester);
  print('✓ Navigated to Budgeting page');

  final context = tester.element(find.byType(TripEditorPage));
  final tripRepo = TestHelpers.getTripRepository(tester);
  var tripMetadata = tripRepo.activeTrip!.tripMetadata;
  final newExpense = StandaloneExpense(
    tripId: tripMetadata.id!,
    title: 'Dummy expense',
    expense: ExpenseFacade(
        currency: TestConfig.testTripCurrency,
        paidBy: const {TestConfig.tripMateUserName: 200.0},
        splitBy: tripMetadata.contributors),
  );
  BlocProvider.of<TripManagementBloc>(context)
      .add(UpdateTripEntity.create(tripEntity: newExpense));
  await Future.delayed(const Duration(milliseconds: 1000));
  await tester.pumpAndSettle();
  print('✓ Over-budget dummy expense added (200 EUR by tripmate)');

  // The test trip has budget of 1500 EUR and expenses totaling around 1500+ EUR
  // So it should be over budget
  // Verify budget display is present
  final progressIndicator = find.descendant(
      of: find.byType(ExpenseListView),
      matching: find.byType(FractionallySizedBox));
  expect(progressIndicator, findsNWidgets(2),
      reason: '2 FractionallySizedBox should be displayed');

  // Get the progress indicator widget
  final budgetPercentage = tripMetadata.budget.amount /
      tripRepo.activeTrip!.budgetingModule.totalExpenditure;
  final excessPercentage = 1.0 - budgetPercentage;
  final indicator1 =
      tester.widget<FractionallySizedBox>(progressIndicator.first);
  expect(indicator1.widthFactor == budgetPercentage, isTrue,
      reason: 'Indicator 1 should have correct percentage value');
  final indicator2 =
      tester.widget<FractionallySizedBox>(progressIndicator.last);
  expect(indicator2.widthFactor == excessPercentage, isTrue,
      reason: 'Progress indicator should have correct percentage value');

  BlocProvider.of<TripManagementBloc>(context)
      .add(UpdateTripEntity.delete(tripEntity: newExpense));
  await Future.delayed(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  print('✓ Budget display found');
  print('✓ Budget indicator present (check for over budget visual indicator)');
}

/// Test: DebtSummaryTile displays debt information
Future<void> runDebtSummaryTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await tryNavigateToBudgetingPage(tester);

  // Find and tap on Debt section to expand it
  final debtSection = find.descendant(
      of: find.byType(HorizontalSectionsList),
      matching: find.byIcon(Icons.money_off_rounded));
  await TestHelpers.tapWidget(tester, debtSection);
  print('✓ Expanded Debt section');

  // Verify debt calculation includes both contributors from test data
  // Test data has 2 contributors: TestConfig.testEmail and TestConfig.tripMateUserName
  // All expenses are paid by testEmail and split between both
  // So tripMate owes testEmail money
  final debtRowContainer =
      find.byKey(const ValueKey('DebtSummaryTile_Debt_Row'));
  expect(find.textContaining('owes'), findsOneWidget,
      reason: 'Debt summary should show one row');
  final contributorBadges = find.descendant(
      of: debtRowContainer, matching: find.byType(ContributorBadge));
  expect(contributorBadges, findsNWidgets(2),
      reason: 'Two contributor badges should be present');
  final personOwingMoney =
      tester.widget<ContributorBadge>(contributorBadges.first);
  expect(
      personOwingMoney.contributorName == TestConfig.tripMateUserName, isTrue,
      reason: 'Person who owes money should be ${TestConfig.tripMateUserName}');
  final personOwedMoney =
      tester.widget<ContributorBadge>(contributorBadges.last);
  expect(personOwedMoney.contributorName == TestConfig.testEmail, isTrue,
      reason: 'Person who is owed money should be ${TestConfig.testEmail}');
  final oweAmount = find.text('745 €');
  expect(oweAmount, findsOneWidget, reason: 'Owe amount should be 745 €');

  print('✓ Debt relationships displayed');
}

/// Test: BudgetBreakdownTile displays breakdown charts
Future<void> runBudgetBreakdownTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await tryNavigateToBudgetingPage(tester);

  // Find and tap on Breakdown section to expand it
  final breakdownSection = find.descendant(
      of: find.byType(HorizontalSectionsList),
      matching: find.byIcon(Icons.pie_chart_rounded));
  await TestHelpers.tapWidget(tester, breakdownSection);
  print('✓ Expanded Breakdown section');

  // Check for BudgetBreakdownTile
  final budgetBreakdownTile = find.byType(BudgetBreakdownTile);
  expect(budgetBreakdownTile, findsOneWidget,
      reason: 'BudgetBreakdownTile should be present');
  print('✓ BudgetBreakdownTile found');

  // Check for tab options (Category and Day by Day)
  final tabs = find.descendant(
      of: find.descendant(
          of: budgetBreakdownTile, matching: find.byType(TabBar)),
      matching: find.byType(Tab));
  final tabBarViewFinder = find.descendant(
      of: budgetBreakdownTile, matching: find.byType(TabBarView));
  final tabBarView = tester.widget<TabBarView>(tabBarViewFinder);
  expect(tabs, findsNWidgets(2), reason: 'TabBar should have 2 tabs');
  final categoryTab = tester.widget<Tab>(tabs.first);
  expect(categoryTab.text, 'Category',
      reason: 'Category tab should have text "Category"');
  final dayByDayTab = tester.widget<Tab>(tabs.last);
  expect(dayByDayTab.text, 'Day by Day',
      reason: 'Day by Day tab should have text "Day by Day"');
  final tabBarItems = tabBarView.children;
  expect(tabBarItems.first is BreakdownByDayChart, isTrue,
      reason: 'First tab should be BreakdownByDayChart');
  expect(tabBarItems.last is BreakdownByCategoryChart, isTrue,
      reason: 'Second tab should be BreakdownByCategoryChart');
  print('✓ Breakdown tabs found (Category and Day by Day)');
}

//TODO: Add test to verify what is exactly displayed in ReadonlyExpenseListItem, and a test to verify contents of BreakdownByDay/BreakdownByCategory charts
void runTests() {
  setUpAll(() async {
    await FirebaseEmulatorHelper.createFirebaseAuthUser(
      email: TestConfig.testEmail,
      password: TestConfig.testPassword,
      shouldAddToFirestore: true,
      shouldSignIn: true,
    );
    await MockApiServices.initialize();
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

  // A test to verify what is exactly displayed in a expense list view item
  testWidgets('Expense list view item displays correct data',
      (WidgetTester tester) async {
    await runExpenseListItemTest(tester);
  });

  testWidgets('DebtSummaryTile displays debt information',
      (WidgetTester tester) async {
    await runDebtSummaryTest(tester);
  });

  testWidgets('BudgetBreakdownTile displays breakdown charts',
      (WidgetTester tester) async {
    await runBudgetBreakdownTest(tester);
  });
}
