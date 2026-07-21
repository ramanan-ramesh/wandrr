/// Expense (StandaloneExpense) CRUD integration tests.
///
/// Covers add + edit flows via the Creator bottom-sheet and the Budgeting
/// page's expense list, verified through the expense collection's change
/// streams (not brittle widget-tree probing).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expense_editor.dart';

import '../../../helpers/test_helpers.dart';
import '../helpers.dart';
import 'helpers.dart';

final _form = ExpenseEditorForm();

/// Adds a new standalone expense via the Creator bottom-sheet, fills every
/// field, submits, and verifies both the persisted [StandaloneExpense] and
/// its entry in the budgeting expense list.
Future<void> runAddExpenseTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await openExpenseCreatorPage(tester);

  await TestHelpers.enterText(tester, _form.titleField, 'Museum tickets');
  await _form.selectCategory(tester, 'Sightseeing');

  await _form.commonFormElements.expenseEditor.switchToPaidByTab(tester);
  final amountField = find.descendant(
    of: _form.commonFormElements.expenseEditor.paidByTabContributorTile.first,
    matching: find.byKey(const ValueKey('ExpenseAmountEditField_TextField')),
  );
  await TestHelpers.enterText(tester, amountField, '35');

  await TestHelpers.enterText(
      tester, _form.commonFormElements.noteEditingField, 'Two tickets');
  print('[OK] Expense form filled');

  await submitExpenseAndVerify(tester, _form, onExpenseAdded: (expense) async {
    print('[OK] Expense added: $expense (id: ${expense.id})');
    expect(expense.title, 'Museum tickets',
        reason: 'Persisted title must match');
    expect(expense.category, ExpenseCategory.sightseeing,
        reason: 'Persisted category must match');
    expect(expense.expense.description, 'Two tickets',
        reason: 'Persisted description must match');
    expect(expense.expense.totalExpense.amount, 35.0,
        reason: 'Persisted amount must match');

    await TestHelpers.navigateToBudgetingTab(tester);
    await verifyExpenseListEntry(
      tester,
      expectedTitle: 'Museum tickets',
      expectedCategoryIcon: Icons.attractions_rounded,
    );
  });
}

/// Edits the seeded "Dinner at Le Comptoir" expense from the budgeting list
/// and verifies the change propagates through the expense collection's
/// `onDocumentUpdated` stream.
Future<void> runEditExpenseTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);
  await TestHelpers.navigateToBudgetingTab(tester);

  final listView = find.byKey(const ValueKey('ExpensesListView_ListView'));
  final listScrollable =
      find.ancestor(of: listView, matching: find.byType(ListView)).first;
  await TestHelpers.scrollUntilPresent(
    tester,
    scrollableFinder: listScrollable,
    widgetFinder: find.text('Dinner at Le Comptoir'),
    reason: 'Seeded expense must be present in the list',
  );

  await TestHelpers.tapWidget(tester, find.text('Dinner at Le Comptoir'));
  await TestHelpers.waitForWidget(tester, find.byType(ExpenseEditor));
  print('[OK] ExpenseEditor opened for editing (Dinner at Le Comptoir)');

  expect(tester.widget<TextField>(_form.titleField).controller?.text,
      'Dinner at Le Comptoir',
      reason: 'Editor must be pre-filled with the existing title');

  await TestHelpers.enterText(tester, _form.titleField, 'Dinner - updated');

  final collection =
      TestHelpers.getTripRepository(tester).activeTrip!.expenseCollection;
  final completer = Completer<StandaloneExpense>();
  late StreamSubscription sub;
  sub = collection.onDocumentUpdated.listen((event) async {
    if (event.isFromExplicitAction && !completer.isCompleted) {
      completer.complete(event.collectionItemChange.afterUpdate);
      await sub.cancel();
    }
  });

  final fab = _form.commonFormElements.updateTripEntityButton;
  expect(fab, findsOneWidget, reason: 'Update FAB must be present and enabled');
  await TestHelpers.tapWidget(tester, fab);

  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.byType(ExpenseEditor).evaluate().isEmpty) {
      break;
    }
  }
  expect(find.byType(ExpenseEditor), findsNothing,
      reason: 'ExpenseEditor must be dismissed after the update completes');

  final updated = completer.isCompleted
      ? await completer.future
      : await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () async {
            await sub.cancel();
            throw TestFailure(
                'expenseCollection.onDocumentUpdated did not fire after editor dismissal');
          },
        );
  await sub.cancel();
  expect(updated.title, 'Dinner - updated',
      reason: 'Updated title must be persisted');
  print('[OK] Expense updated: title = ${updated.title}');

  await tester.pumpAndSettle();
  await verifyExpenseListEntry(
    tester,
    expectedTitle: 'Dinner - updated',
    expectedCategoryIcon: Icons.fastfood_rounded,
  );
}
