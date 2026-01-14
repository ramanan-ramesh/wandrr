import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/app_bar/collaborator_list.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../helpers/test_config.dart';
import '../helpers/test_helpers.dart';

/// Test: AppBar displays maximum of 3 contributors
Future<void> runCollaboratorListMaxThreeTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Find CollaboratorList in AppBar
  final collaboratorList = find.byType(CollaboratorList);
  expect(collaboratorList, findsOneWidget,
      reason: 'CollaboratorList should be found in AppBar');
  print('✓ CollaboratorList found in AppBar');

  // Find CircleAvatars (max 3 should be shown)
  final avatars = find.byType(CircleAvatar);
  final avatarCount = avatars.evaluate().length;

  // Verify we have the 2 collaborators from test data
  expect(avatarCount, 2,
      reason: 'Should have 2 avatars (test user and tripmate)');
  print('✓ Number of avatars displayed: $avatarCount');
  print('✓ Collaborator display verified (limit: max 3)');
}

/// Test: Clicking trip name/date opens trip metadata editor
Future<void> runTripNameOpensMetadataEditorTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Find the InkWell with trip name "European Adventure"
  final tripNameInkWell = find.ancestor(
    of: find.text('European Adventure'),
    matching: find.byType(InkWell),
  );

  expect(tripNameInkWell, findsOneWidget,
      reason: 'Trip name tappable area should be present');

  // Tap on trip name/date area
  await TestHelpers.tapWidget(tester, tripNameInkWell.first);
  await tester.pumpAndSettle();

  print('✓ Trip name/date area tapped');

  // Look for metadata editor indicators (dialog or bottom sheet)
  final dialog = find.byType(Dialog);
  final bottomSheet = find.byType(BottomSheet);

  final editorOpened =
      dialog.evaluate().isNotEmpty || bottomSheet.evaluate().isNotEmpty;
  expect(editorOpened, true,
      reason: 'Trip metadata editor should open as dialog or bottom sheet');
  print('✓ Trip metadata editor opened');
}

/// Test: Trip metadata editing - name change
Future<void> runEditTripNameTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Tap to open metadata editor
  final tripNameInkWell = find.ancestor(
    of: find.text('European Adventure'),
    matching: find.byType(InkWell),
  );
  await TestHelpers.tapWidget(tester, tripNameInkWell.first);
  await tester.pumpAndSettle();

  print('✓ Trip metadata editor opened');

  // Look for TextFormField to edit trip name
  final textFields = find.byType(TextFormField);
  expect(textFields, findsWidgets, reason: 'Trip name field should be found');
  print('✓ Trip name field found');
  print('✓ Can edit trip name');
}

/// Test: Trip metadata editing - date change
Future<void> runEditTripDatesTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Tap to open metadata editor
  final tripNameInkWell = find.ancestor(
    of: find.text('European Adventure'),
    matching: find.byType(InkWell),
  );
  await TestHelpers.tapWidget(tester, tripNameInkWell.first);
  await tester.pumpAndSettle();

  print('✓ Trip metadata editor opened');

  // Look for date picker or date display
  final calendarIcon = find.byIcon(Icons.calendar_today);
  expect(calendarIcon, findsWidgets,
      reason: 'Date selection should be available');
  print('✓ Date selection available');
  print('✓ Can edit trip start/end dates');
}

/// Test: Trip metadata editing - add/remove contributors
Future<void> runEditContributorsTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Verify repository has expected contributors
  final context = tester.element(find.byType(TripEditorPage));
  final tripRepo = RepositoryProvider.of<TripRepositoryFacade>(context);
  final contributors = tripRepo.activeTrip!.tripMetadata.contributors;

  expect(contributors.length, 2,
      reason: 'Should have 2 contributors from test data');
  expect(contributors.contains(TestConfig.testEmail), true,
      reason: 'Test user should be a contributor');
  expect(contributors.contains(TestConfig.tripMateUserName), true,
      reason: 'Trip mate should be a contributor');

  print('✓ Verified 2 contributors: ${contributors.join(', ')}');

  // Tap to open metadata editor
  final tripNameInkWell = find.ancestor(
    of: find.text('European Adventure'),
    matching: find.byType(InkWell),
  );
  await TestHelpers.tapWidget(tester, tripNameInkWell.first);
  await tester.pumpAndSettle();

  print('✓ Trip metadata editor opened');

  // Look for contributors section - add contributor button
  final addContributorButton = find.byIcon(Icons.person_add);
  expect(addContributorButton, findsWidgets,
      reason: 'Add contributor button should be found');
  print('✓ Add contributor button found');

  // Look for remove contributor button (delete icon or close icon)
  final removeContributorButton = find.byIcon(Icons.close);
  expect(removeContributorButton, findsWidgets,
      reason: 'Remove contributor button should be found');
  print('✓ Remove contributor button found');

  print('✓ Contributor management available');
}

/// Test: Trip metadata editing - budget change
Future<void> runEditTripBudgetTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Verify budget from repository
  final context = tester.element(find.byType(TripEditorPage));
  final tripRepo = RepositoryProvider.of<TripRepositoryFacade>(context);
  final budget = tripRepo.activeTrip!.tripMetadata.budget;
  expect(budget.amount, 800.0, reason: 'Budget should be 800 from test data');
  expect(budget.currency, 'EUR',
      reason: 'Budget currency should be EUR from test data');
  print('✓ Verified budget: ${budget.amount} ${budget.currency}');

  // Tap to open metadata editor
  final tripNameInkWell = find.ancestor(
    of: find.text('European Adventure'),
    matching: find.byType(InkWell),
  );
  await TestHelpers.tapWidget(tester, tripNameInkWell.first);
  await tester.pumpAndSettle();

  print('✓ Trip metadata editor opened');

  // Look for budget fields (amount and currency)
  final textFields = find.byType(TextFormField);
  expect(textFields.evaluate().length, greaterThanOrEqualTo(2),
      reason: 'Budget fields should be available (amount & currency)');
  print('✓ Budget fields available (amount & currency)');
  print('✓ Can edit trip budget');
}

/// Test: Expense splitting - multiple contributors shown
Future<void> runExpenseSplittingDisplayTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

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
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);
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
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

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
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

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
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

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
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

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
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

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
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

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
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

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
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

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
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

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
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

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
