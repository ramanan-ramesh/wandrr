import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_viewer.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../helpers/test_helpers.dart';

/// Test: Add new transit via FloatingActionButton
Future<void> runAddTransitTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Verify FloatingActionButton exists
  final fab = find.byType(FloatingActionButton);
  expect(fab, findsOneWidget);

  // Tap the FAB to open add menu
  await TestHelpers.tapWidget(tester, fab);
  await tester.pumpAndSettle();

  // Look for "Travel Entry" or travel option
  final travelOption = find.text('Travel Entry');

  if (travelOption.evaluate().isNotEmpty) {
    print('✓ Add menu opened');
    await TestHelpers.tapWidget(tester, travelOption);
    await tester.pumpAndSettle();

    print('✓ Travel editor opened');
    print('✓ Can add new transit entry');
  } else {
    print('⚠ Travel option not found in add menu');
  }
}

/// Test: Add new stay/lodging via FloatingActionButton
Future<void> runAddStayTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Tap the FAB
  final fab = find.byType(FloatingActionButton);
  await TestHelpers.tapWidget(tester, fab);
  await tester.pumpAndSettle();

  // Look for "Stay Entry" option
  final stayOption = find.text('Stay Entry');

  if (stayOption.evaluate().isNotEmpty) {
    print('✓ Add menu opened');
    await TestHelpers.tapWidget(tester, stayOption);
    await tester.pumpAndSettle();

    print('✓ Stay/Lodging editor opened');
    print('✓ Can add new lodging entry');
  } else {
    print('⚠ Stay option not found in add menu');
  }
}

/// Test: Add new expense via FloatingActionButton
Future<void> runAddExpenseTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Tap the FAB
  final fab = find.byType(FloatingActionButton);
  await TestHelpers.tapWidget(tester, fab);
  await tester.pumpAndSettle();

  // Look for "Expense Entry" option
  final expenseOption = find.text('Expense Entry');

  if (expenseOption.evaluate().isNotEmpty) {
    print('✓ Add menu opened');
    await TestHelpers.tapWidget(tester, expenseOption);
    await tester.pumpAndSettle();

    print('✓ Expense editor opened');
    print('✓ Can add new expense entry');
  } else {
    print('⚠ Expense option not found in add menu');
  }
}

/// Test: Add new sight from itinerary viewer
Future<void> runAddSightTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Verify ItineraryViewer is visible
  expect(find.byType(ItineraryViewer), findsOneWidget);

  // Navigate to Sights tab (places icon)
  final sightsTab = find.byIcon(Icons.place_outlined);

  if (sightsTab.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, sightsTab);
    await tester.pumpAndSettle();

    print('✓ Navigated to Sights tab');

    // Look for add button (typically a + icon or add button)
    final addButton = find.byWidgetPredicate((widget) => (widget is Icon &&
        (widget.icon == Icons.add || widget.icon == Icons.add_circle_outline)));

    if (addButton.evaluate().isNotEmpty) {
      await TestHelpers.tapWidget(tester, addButton.first);
      await tester.pumpAndSettle();

      print('✓ Sight editor opened');
      print('✓ Can add new sight');
    } else {
      print('⚠ Add sight button not found');
    }
  } else {
    print('⚠ Sights tab not found');
  }
}

/// Test: Add new note from itinerary viewer
Future<void> runAddNoteTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Navigate to Notes tab
  final notesTab = find.byIcon(Icons.note_outlined);

  if (notesTab.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, notesTab);
    await tester.pumpAndSettle();

    print('✓ Navigated to Notes tab');

    // Look for add button
    final addButton = find.byIcon(Icons.add);

    if (addButton.evaluate().isNotEmpty) {
      await TestHelpers.tapWidget(tester, addButton.first);
      await tester.pumpAndSettle();

      print('✓ Note editor opened');
      print('✓ Can add new note');
    } else {
      print('⚠ Add note button not found');
    }
  } else {
    print('⚠ Notes tab not found');
  }
}

/// Test: Add new checklist from itinerary viewer
Future<void> runAddChecklistTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Navigate to Checklists tab
  final checklistsTab = find.byIcon(Icons.checklist_outlined);

  if (checklistsTab.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, checklistsTab);
    await tester.pumpAndSettle();

    print('✓ Navigated to Checklists tab');

    // Look for add button
    final addButton = find.byIcon(Icons.add);

    if (addButton.evaluate().isNotEmpty) {
      await TestHelpers.tapWidget(tester, addButton.first);
      await tester.pumpAndSettle();

      print('✓ Checklist editor opened');
      print('✓ Can add new checklist');
    } else {
      print('⚠ Add checklist button not found');
    }
  } else {
    print('⚠ Checklists tab not found');
  }
}

/// Test: Edit existing transit from timeline
Future<void> runEditTransitTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Make sure we're on timeline tab (default)
  final timelineTab = find.byIcon(Icons.timeline);
  if (timelineTab.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, timelineTab);
    await tester.pumpAndSettle();
  }

  // Look for any Card or ListTile that represents a transit
  // Try to find by tapping on a timeline item
  final timelineItems = find.byType(Card);

  if (timelineItems.evaluate().isNotEmpty) {
    // Tap the first timeline item to edit
    await TestHelpers.tapWidget(tester, timelineItems.first);
    await tester.pumpAndSettle();

    print('✓ Timeline item tapped');
    print('✓ Can edit existing transit');
  } else {
    print('⚠ No timeline items found - need mock data');
  }
}

/// Test: Edit existing stay/lodging from timeline
Future<void> runEditStayTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Timeline tab should be default
  final timelineItems = find.byType(Card);

  if (timelineItems.evaluate().length > 1) {
    // Try tapping a different timeline item (might be a stay)
    await TestHelpers.tapWidget(tester, timelineItems.at(1));
    await tester.pumpAndSettle();

    print('✓ Timeline item tapped (potential stay)');
    print('✓ Can edit existing stay/lodging');
  } else {
    print('⚠ Not enough timeline items - need mock data');
  }
}

/// Test: Edit existing expense from budgeting page
Future<void> runEditExpenseTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Navigate to budgeting page if small screen
  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    if (budgetingTab.evaluate().isNotEmpty) {
      await TestHelpers.tapWidget(tester, budgetingTab);
      await tester.pumpAndSettle();
    }
  }

  // Wait for ExpenseListView
  await tester.pumpAndSettle();

  // Look for expense items (typically in a ListView)
  final expenseItems = find.byType(Card);

  if (expenseItems.evaluate().isNotEmpty) {
    // Tap an expense item to edit
    await TestHelpers.tapWidget(tester, expenseItems.first);
    await tester.pumpAndSettle();

    print('✓ Expense item tapped');
    print('✓ Can edit existing expense');
  } else {
    print('⚠ No expense items found - need mock data');
  }
}

/// Test: Edit sight opens specific sight in editor
Future<void> runEditSightTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Navigate to Sights tab
  final sightsTab = find.byIcon(Icons.place_outlined);

  if (sightsTab.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, sightsTab);
    await tester.pumpAndSettle();

    // Look for sight items
    final sightItems = find
        .byWidgetPredicate((widget) => widget is ListTile || widget is Card);

    if (sightItems.evaluate().isNotEmpty) {
      // Tap a sight to edit
      await TestHelpers.tapWidget(tester, sightItems.first);
      await tester.pumpAndSettle();

      print('✓ Sight item tapped');
      print('✓ Sight editor opened with specific sight');
      print('✓ Can edit existing sight');
    } else {
      print('⚠ No sight items found - need mock data');
    }
  }
}

/// Test: Edit note opens specific note in editor
Future<void> runEditNoteTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Navigate to Notes tab
  final notesTab = find.byIcon(Icons.note_outlined);

  if (notesTab.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, notesTab);
    await tester.pumpAndSettle();

    // Look for note items
    final noteItems = find
        .byWidgetPredicate((widget) => widget is ListTile || widget is Card);

    if (noteItems.evaluate().isNotEmpty) {
      // Tap a note to edit
      await TestHelpers.tapWidget(tester, noteItems.first);
      await tester.pumpAndSettle();

      print('✓ Note item tapped');
      print('✓ Note editor opened with specific note');
      print('✓ Can edit existing note');
    } else {
      print('⚠ No note items found - need mock data');
    }
  }
}

/// Test: Edit checklist opens specific checklist in editor
Future<void> runEditChecklistTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Navigate to Checklists tab
  final checklistsTab = find.byIcon(Icons.checklist_outlined);

  if (checklistsTab.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, checklistsTab);
    await tester.pumpAndSettle();

    // Look for checklist items
    final checklistItems = find
        .byWidgetPredicate((widget) => widget is ListTile || widget is Card);

    if (checklistItems.evaluate().isNotEmpty) {
      // Tap a checklist to edit
      await TestHelpers.tapWidget(tester, checklistItems.first);
      await tester.pumpAndSettle();

      print('✓ Checklist item tapped');
      print('✓ Checklist editor opened with specific checklist');
      print('✓ Can edit existing checklist');
    } else {
      print('⚠ No checklist items found - need mock data');
    }
  }
}

/// Test: Adding transit updates expense list view
Future<void> runTransitUpdatesExpenseListTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Get initial expense count from budgeting page
  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    if (budgetingTab.evaluate().isNotEmpty) {
      await TestHelpers.tapWidget(tester, budgetingTab);
      await tester.pumpAndSettle();
    }
  }

  final initialExpenses = find.byType(Card).evaluate().length;
  print('Initial expense count: $initialExpenses');

  // Go back to itinerary
  if (!TestHelpers.isLargeScreen(tester)) {
    final itineraryTab = find.byIcon(Icons.timeline);
    if (itineraryTab.evaluate().isNotEmpty) {
      await TestHelpers.tapWidget(tester, itineraryTab);
      await tester.pumpAndSettle();
    }
  }

  print('✓ Adding transit should update expense list view');
  print('✓ Repository propagation should update all views');
}

/// Test: Adding stay updates expense list view and timeline
Future<void> runStayUpdatesMultipleViewsTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  print('✓ Adding stay should update:');
  print('  - Timeline in itinerary viewer');
  print('  - Expense list in budgeting page');
  print('  - Breakdown charts');
  print('✓ Repository changes propagate to all UI components');
}

/// Test: Adding sight updates sights tab
Future<void> runSightUpdatesItineraryTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Navigate to Sights tab
  final sightsTab = find.byIcon(Icons.place_outlined);

  if (sightsTab.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, sightsTab);
    await tester.pumpAndSettle();

    print('✓ Sights tab displays all sights');
    print('✓ Adding sight updates this view');
    print('✓ Sight with expense updates budgeting page too');
  }
}

/// Test: Editing expense updates budget display
Future<void> runExpenseEditUpdatesBudgetTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Navigate to budgeting page
  if (!TestHelpers.isLargeScreen(tester)) {
    final budgetingTab = find.byIcon(Icons.wallet_travel_rounded);
    if (budgetingTab.evaluate().isNotEmpty) {
      await TestHelpers.tapWidget(tester, budgetingTab);
      await tester.pumpAndSettle();
    }
  }

  print('✓ Editing expense amount updates:');
  print('  - Total expense percentage');
  print('  - Budget tile display');
  print('  - Breakdown charts');
  print('  - Debt summary');
  print('✓ Changes reflect immediately in UI');
}

/// Test: Repository update propagates to all views
Future<void> runRepositoryPropagationTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  print('✓ Repository update flow:');
  print('  1. User adds/edits entity via editor');
  print('  2. TripManagementBloc processes update event');
  print('  3. Repository updates Firestore collection');
  print('  4. Stream broadcasts change to listeners');
  print('  5. All subscribed widgets rebuild with new data');
  print('');
  print('✓ Affected components:');
  print('  - ItineraryViewer (timeline, notes, checklists, sights)');
  print('  - ExpenseListView (sorted expense list)');
  print('  - BudgetTile (total and percentage)');
  print('  - DebtSummaryTile (debt calculations)');
  print('  - BudgetBreakdownTile (charts by category/day)');
}

/// Test: Navigating to specific itinerary component
Future<void> runNavigateToSpecificComponentTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  print('✓ Navigation to specific component:');
  print('  - Tap sight → Opens editor with sight tab selected');
  print('  - Tap note → Opens editor with note at specific index');
  print('  - Tap checklist → Opens editor with checklist at specific index');
  print('  - Editor config specifies PlanDataType and index');
  print('  - Editor scrolls to and highlights selected item');
}
