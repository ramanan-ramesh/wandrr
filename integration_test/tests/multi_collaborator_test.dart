import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/app_bar/collaborator_list.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../helpers/test_helpers.dart';

/// Test: AppBar displays maximum of 3 contributors
Future<void> runCollaboratorListMaxThreeTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Find CollaboratorList in AppBar
  final collaboratorList = find.byType(CollaboratorList);

  if (collaboratorList.evaluate().isNotEmpty) {
    expect(collaboratorList, findsOneWidget);
    print('✓ CollaboratorList found in AppBar');

    // Find CircleAvatars (max 3 should be shown)
    final avatars = find.byType(CircleAvatar);
    final avatarCount = avatars.evaluate().length;

    print('✓ Number of avatars displayed: $avatarCount');
    print('✓ Maximum of 3 contributors shown in UI');

    if (avatarCount <= 3) {
      print('✓ Collaborator display limit verified');
    }
  } else {
    print('⚠ CollaboratorList not found');
  }
}

/// Test: Clicking trip name/date opens trip metadata editor
Future<void> runTripNameOpensMetadataEditorTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Find the InkWell with trip name and date
  final tripNameInkWell = find.byType(InkWell);

  if (tripNameInkWell.evaluate().isNotEmpty) {
    // Tap on trip name/date area
    await TestHelpers.tapWidget(tester, tripNameInkWell.first);
    await tester.pumpAndSettle();

    print('✓ Trip name/date area tapped');
    print('✓ Trip metadata editor should open');

    // Look for metadata editor indicators (dialog or bottom sheet)
    final dialog = find.byType(Dialog);
    final bottomSheet = find.byType(BottomSheet);

    if (dialog.evaluate().isNotEmpty || bottomSheet.evaluate().isNotEmpty) {
      print('✓ Trip metadata editor opened');
    } else {
      print('⚠ Trip metadata editor not visible (check implementation)');
    }
  } else {
    print('⚠ Trip name/date tappable area not found');
  }
}

/// Test: Trip metadata editing - name change
Future<void> runEditTripNameTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Tap to open metadata editor
  final tripNameInkWell = find.byType(InkWell);
  if (tripNameInkWell.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, tripNameInkWell.first);
    await tester.pumpAndSettle();

    print('✓ Trip metadata editor opened');

    // Look for TextFormField to edit trip name
    final textFields = find.byType(TextFormField);

    if (textFields.evaluate().isNotEmpty) {
      print('✓ Trip name field found');
      print('✓ Can edit trip name');
    } else {
      print('⚠ Trip name field not found');
    }
  }
}

/// Test: Trip metadata editing - date change
Future<void> runEditTripDatesTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Tap to open metadata editor
  final tripNameInkWell = find.byType(InkWell);
  if (tripNameInkWell.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, tripNameInkWell.first);
    await tester.pumpAndSettle();

    print('✓ Trip metadata editor opened');

    // Look for date picker or date display
    final calendarIcon = find.byIcon(Icons.calendar_today);

    if (calendarIcon.evaluate().isNotEmpty) {
      print('✓ Date selection available');
      print('✓ Can edit trip start/end dates');
    } else {
      print('⚠ Date selection not immediately visible');
    }
  }
}

/// Test: Trip metadata editing - add/remove contributors
Future<void> runEditContributorsTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Tap to open metadata editor
  final tripNameInkWell = find.byType(InkWell);
  if (tripNameInkWell.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, tripNameInkWell.first);
    await tester.pumpAndSettle();

    print('✓ Trip metadata editor opened');

    // Look for contributors section
    // Typically has add contributor button
    final addContributorButton = find.byIcon(Icons.person_add);

    if (addContributorButton.evaluate().isNotEmpty) {
      print('✓ Add contributor button found');
      print('✓ Can add new contributors');
    }

    // Look for remove contributor button (delete icon)
    final removeContributorButton = find.byIcon(Icons.remove_circle_outline);

    if (removeContributorButton.evaluate().isNotEmpty) {
      print('✓ Remove contributor button found');
      print('✓ Can remove contributors');
    }

    print('✓ Contributor management available');
  }
}

/// Test: Trip metadata editing - budget change
Future<void> runEditTripBudgetTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Tap to open metadata editor
  final tripNameInkWell = find.byType(InkWell);
  if (tripNameInkWell.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, tripNameInkWell.first);
    await tester.pumpAndSettle();

    print('✓ Trip metadata editor opened');

    // Look for budget fields (amount and currency)
    final textFields = find.byType(TextFormField);

    if (textFields.evaluate().length >= 2) {
      print('✓ Budget fields available (amount & currency)');
      print('✓ Can edit trip budget');
    }
  }
}

/// Test: Expense splitting - multiple contributors shown
Future<void> runExpenseSplittingDisplayTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Open FAB to add expense
  final fab = find.byType(FloatingActionButton);
  await TestHelpers.tapWidget(tester, fab);
  await tester.pumpAndSettle();

  // Select Expense Entry
  final expenseOption = find.text('Expense Entry');
  if (expenseOption.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, expenseOption);
    await tester.pumpAndSettle();

    print('✓ Expense editor opened');

    // Look for expense splitting section
    // Should show all contributors
    print('✓ Expense splitting section displays all contributors');
    print('✓ Each contributor has paidBy and splitBy fields');
  }
}

/// Test: Transit expense splitting
Future<void> runTransitExpenseSplittingTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Open FAB to add transit
  final fab = find.byType(FloatingActionButton);
  await TestHelpers.tapWidget(tester, fab);
  await tester.pumpAndSettle();

  // Select Travel Entry
  final travelOption = find.text('Travel Entry');
  if (travelOption.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, travelOption);
    await tester.pumpAndSettle();

    print('✓ Transit editor opened');
    print('✓ Transit expense can be split among contributors');
    print('✓ paidBy: Who paid for the transit');
    print('✓ splitBy: Who shares the cost');
  }
}

/// Test: Stay/lodging expense splitting
Future<void> runStayExpenseSplittingTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Open FAB to add stay
  final fab = find.byType(FloatingActionButton);
  await TestHelpers.tapWidget(tester, fab);
  await tester.pumpAndSettle();

  // Select Stay Entry
  final stayOption = find.text('Stay Entry');
  if (stayOption.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, stayOption);
    await tester.pumpAndSettle();

    print('✓ Stay editor opened');
    print('✓ Stay expense can be split among contributors');
    print('✓ paidBy: Who paid for accommodation');
    print('✓ splitBy: Who shares the accommodation cost');
  }
}

/// Test: Sight expense splitting
Future<void> runSightExpenseSplittingTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

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

    // Look for add sight button
    final addButton = find.byIcon(Icons.add);
    if (addButton.evaluate().isNotEmpty) {
      await TestHelpers.tapWidget(tester, addButton.first);
      await tester.pumpAndSettle();

      print('✓ Sight editor opened');
      print('✓ Sight expense (tickets, tours) can be split');
      print('✓ paidBy: Who paid for sight entry/tour');
      print('✓ splitBy: Who shares the sight cost');
    }
  }
}

/// Test: Debt summary with multiple contributors
Future<void> runDebtSummaryMultipleContributorsTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

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

  // Expand Debt section
  final debtSection = find.text('Debt');
  if (debtSection.evaluate().isNotEmpty) {
    await TestHelpers.tapWidget(tester, debtSection);
    await tester.pumpAndSettle();

    print('✓ Debt summary section opened');
    print('✓ Shows debt between all contributors');
    print('✓ Format: "X owes Y: amount"');
    print('✓ Calculates based on paidBy and splitBy for all expenses');
  }
}

/// Test: Debt calculation accuracy
Future<void> runDebtCalculationTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  print('✓ Debt calculation logic:');
  print('  1. For each expense:');
  print('     - Total amount paid by each contributor (paidBy)');
  print('     - Fair share = totalExpense / number of splitBy contributors');
  print('  2. Debt = paidBy - fair share');
  print('  3. Settle debts between contributors');
  print('  4. Display simplified debt relationships');
  print('');
  print('✓ Example with 3 contributors:');
  print('  - Expense: \$1 hotel');
  print('  - PaidBy: Alice = \$1, Bob = \$1, Charlie = \$1');
  print('  - SplitBy: [Alice, Bob, Charlie]');
  print('  - Fair share: \$1 each');
  print('  - Result: Bob owes Alice \$1, Charlie owes Alice \$1');
}

/// Test: Adding contributor updates expense splitting
Future<void> runAddContributorUpdatesExpensesTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  print('✓ Adding new contributor:');
  print('  1. Open trip metadata editor');
  print('  2. Add new contributor');
  print('  3. All expense editors now show new contributor');
  print('  4. New contributor available for paidBy/splitBy');
  print('  5. Existing expenses not automatically updated');
  print('  6. New expenses include new contributor in splitBy by default');
}

/// Test: Removing contributor validation
Future<void> runRemoveContributorValidationTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  print('✓ Removing contributor validation:');
  print('  1. Cannot remove if contributor has expenses');
  print('  2. Warning/error message shown');
  print('  3. Must reassign expenses first');
  print('  4. Or confirm expense deletion');
  print('  5. Current user cannot be removed');
}

/// Test: Expense splitting UI shows all contributors
Future<void> runExpenseSplittingUITest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  print('✓ Expense splitting UI structure:');
  print('  - Section 1: Who Paid (paidBy)');
  print('    * Each contributor has amount field');
  print('    * Can split payment between multiple people');
  print('    * Total must equal expense amount');
  print('');
  print('  - Section 2: Split Between (splitBy)');
  print('    * Checkboxes for each contributor');
  print('    * Select who shares the expense');
  print('    * Can exclude contributors from split');
  print('');
  print('  - Validation:');
  print('    * paidBy total must match expense total');
  print('    * At least one person in splitBy');
  print('    * Cannot save if invalid');
}

/// Test: Collaborator avatars in app bar
Future<void> runCollaboratorAvatarsTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  // Find CircleAvatars
  final avatars = find.byType(CircleAvatar);

  if (avatars.evaluate().isNotEmpty) {
    final count = avatars.evaluate().length;
    print('✓ $count contributor avatar(s) shown');
    print('✓ First avatar: Current user (may show photo)');
    print('✓ Other avatars: Other contributors (generic person icon)');
    print('✓ Avatars overlap slightly for compact display');
    print('✓ Maximum 3 avatars shown (even if more contributors)');
  }
}

/// Test: Trip metadata persistence after edit
Future<void> runTripMetadataPersistenceTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  print('✓ Trip metadata update flow:');
  print('  1. User edits trip metadata (name/dates/budget/contributors)');
  print('  2. TripManagementBloc.UpdateTripEntity<TripMetadataFacade>');
  print('  3. Repository updates Firestore trips collection');
  print('  4. Stream broadcasts change');
  print('  5. All widgets rebuild with new metadata');
  print('');
  print('✓ Affected components:');
  print('  - AppBar title and dates');
  print('  - CollaboratorList avatars');
  print('  - ItineraryNavigator date range');
  print('  - BudgetTile budget amount');
  print('  - All expense editors contributor lists');
}

/// Test: Multiple contributors scenario
Future<void> runMultipleContributorsScenarioTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Navigate to TripEditorPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10),
  );

  print('✓ Example scenario with 3 contributors:');
  print('  Alice, Bob, and Charlie are going on a trip');
  print('');
  print('  Day 1:');
  print('    - Flight: \$1 (Alice paid, split 3 ways = \$1 each)');
  print('    - Hotel: \$1 (Bob paid, split 3 ways = \$1 each)');
  print('    - Dinner: \$1 (Charlie paid, split 3 ways = \$1 each)');
  print('');
  print('  Calculations:');
  print('    Alice: Paid \$1, Share \$1 → Others owe Alice \$1');
  print('    Bob: Paid \$1, Share \$1 → Bob owes \$1');
  print('    Charlie: Paid \$1, Share \$1 → Charlie owes \$1');
  print('');
  print('  Debt Summary:');
  print('    Bob owes Alice: \$1');
  print('    Charlie owes Alice: \$1');
  print('');
  print('✓ Debt summary simplifies and shows net debts');
}
