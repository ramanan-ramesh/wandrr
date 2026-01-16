import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/breakdown/budget_breakdown_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/budgeting_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/debt_dummary.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/budget_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/bottom_nav_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/collapsible_sections_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/horizontal_sections.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/section_header.dart';

import '../../helpers/test_helpers.dart';

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
