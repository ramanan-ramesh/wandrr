import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/breakdown/budget_breakdown_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/budgeting_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/debt_dummary.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/budget_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';
import 'package:wandrr/presentation/trip/widgets/chrome_tab.dart';

import '../../helpers/test_helpers.dart';
import 'helpers.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

/// REQ-BP-001: BudgetingPage renders a ChromeTabBar with three tabs.
Future<void> runBudgetingPageStructureTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);
  await tryNavigateToBudgetingPage(tester);

  expect(find.byType(BudgetingPage), findsOneWidget,
      reason: 'BudgetingPage should be displayed');

  // Verify the Chrome tab bar is present.
  final chromeTabs = find.byType(ChromeTabBar);
  expect(chromeTabs, findsOneWidget,
      reason: 'ChromeTabBar should be present in BudgetingPage');

  // All three tab icons must be present in the tab bar.
  for (final icon in [
    Icons.wallet_travel_rounded,
    Icons.money_off_rounded,
    Icons.pie_chart_rounded,
  ]) {
    expect(
      find.descendant(of: chromeTabs, matching: find.byIcon(icon)),
      findsOneWidget,
      reason: 'Tab icon $icon should be present in ChromeTabBar',
    );
  }
  print(
      '✓ BudgetingPage: ChromeTabBar with 3 tabs (Expenses, Debt, Breakdown)');

  // Expenses tab is active by default — ExpenseListView must be in tree.
  expect(find.byType(ExpenseListView), findsOneWidget,
      reason: 'ExpenseListView should be visible on the default Expenses tab');
  print('✓ Expenses tab active by default');

  // Switch to Debt tab and verify DebtSummaryTile appears.
  await TestHelpers.tapWidget(
      tester,
      find.descendant(
          of: chromeTabs, matching: find.byIcon(Icons.money_off_rounded)));
  await tester.pumpAndSettle();
  expect(find.byType(DebtSummaryTile), findsOneWidget,
      reason: 'DebtSummaryTile should be visible on the Debt tab');
  print('✓ Debt tab shows DebtSummaryTile');

  // Switch to Breakdown tab and verify BudgetBreakdownTile appears.
  await TestHelpers.tapWidget(
      tester,
      find.descendant(
          of: chromeTabs, matching: find.byIcon(Icons.pie_chart_rounded)));
  await tester.pumpAndSettle();
  expect(find.byType(BudgetBreakdownTile), findsOneWidget,
      reason: 'BudgetBreakdownTile should be visible on the Breakdown tab');
  print('✓ Breakdown tab shows BudgetBreakdownTile');
}

/// REQ-BP-002: ExpenseListView displays BudgetTile and sort controls.
Future<void> runExpensesListViewStructureTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);
  await tryNavigateToBudgetingPage(tester);

  // Sort controls row.
  final sortRowFinder = find.byKey(const ValueKey('SortControls_Row'));
  expect(sortRowFinder, findsOneWidget);
  expect(tester.widget<Row>(sortRowFinder), isA<Row>());

  // BudgetTile.
  final budgetTileFinder =
      find.byKey(const ValueKey('ExpenseListView_BudgetTile'));
  expect(budgetTileFinder, findsOneWidget);
  expect(
    find.descendant(of: sortRowFinder, matching: budgetTileFinder),
    findsOneWidget,
  );
  expect(find.byType(BudgetTile), findsOneWidget);

  // ToggleButtons.
  final toggleButtonsFinder =
      find.byKey(const ValueKey('ExpenseListView_Sorting_ToggleButtons'));
  expect(toggleButtonsFinder, findsOneWidget);
  expect(
    find.descendant(of: sortRowFinder, matching: toggleButtonsFinder),
    findsOneWidget,
  );
  expect(find.byType(ToggleButtons), findsOneWidget);

  // Expense list ListView.
  final expenseListView =
      find.byKey(const ValueKey('ExpensesListView_ListView'));
  expect(expenseListView, findsOneWidget);
  expect(tester.widget<ListView>(expenseListView), isA<ListView>());

  // Root Column.
  final rootColumnFinder =
      find.byKey(const ValueKey('ExpenseListView_Root_Column'));
  expect(rootColumnFinder, findsOneWidget);
  expect(tester.widget<Column>(rootColumnFinder), isA<Column>());
  expect(find.descendant(of: rootColumnFinder, matching: sortRowFinder),
      findsOneWidget);
  expect(
    find.descendant(of: rootColumnFinder, matching: expenseListView),
    findsOneWidget,
  );
}
