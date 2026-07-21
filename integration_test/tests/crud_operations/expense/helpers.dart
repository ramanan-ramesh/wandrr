import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/presentation/app/widgets/option_grid_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expense_editor.dart';

import '../../../helpers/test_helpers.dart';
import '../helpers.dart';

/// Reusable finders/flows scoped to [ExpenseEditor].
class ExpenseEditorForm {
  final CommonFormElements commonFormElements =
      CommonFormElements(ExpenseEditor);

  Finder get titleField =>
      find.byKey(const ValueKey('ExpenseEditor_Title_TextField'));

  Finder get categoryPicker => find.byType(OptionGridPicker<ExpenseCategory>);

  /// Selects [categoryLabel] from the category picker's modal grid sheet.
  Future<void> selectCategory(WidgetTester tester, String categoryLabel) async {
    await TestHelpers.tapWidget(tester, categoryPicker);
    await tester.pumpAndSettle();
    final option = find.text(categoryLabel);
    expect(option, findsOneWidget,
        reason: 'Category option "$categoryLabel" must be offered');
    await TestHelpers.tapWidget(tester, option);
    print('[OK] Category "$categoryLabel" selected');
  }

  /// Picks [day] (day-of-month) from the single-date "Paid On" picker.
  Future<void> selectDate(WidgetTester tester, int day) async {
    final datePicker = commonFormElements.datePicker;
    await TestHelpers.pickDate(tester, datePicker, day.toString());
    print('[OK] Expense date day=$day selected');
  }
}

/// Opens the Expense creator bottom-sheet and navigates into the [ExpenseEditor].
Future<void> openExpenseCreatorPage(WidgetTester tester) async {
  await openCreatorAndNavigateToEditor(
    tester,
    entityName: 'Expense',
    icon: Icons.money,
    title: 'Expense',
    subTitle: 'Add expense details',
    editorType: ExpenseEditor,
  );
  print('[OK] Expense creator opened');
}

/// Taps the ConflictAwareActionPage submit FAB, awaits the newly-added
/// [StandaloneExpense] from the collection stream, then runs [onExpenseAdded].
Future<void> submitExpenseAndVerify(
  WidgetTester tester,
  ExpenseEditorForm form, {
  required Future<void> Function(StandaloneExpense expense) onExpenseAdded,
}) async {
  final collection =
      TestHelpers.getTripRepository(tester).activeTrip!.expenseCollection;
  final completer = Completer<StandaloneExpense>();
  late StreamSubscription<CollectionItemChangeMetadata<StandaloneExpense>> sub;
  sub = collection.onDocumentAdded.listen((event) async {
    if (event.isFromExplicitAction && !completer.isCompleted) {
      completer.complete(event.collectionItemChange);
      await sub.cancel();
    }
  });

  final fab = form.commonFormElements.createTripEntityButton;
  expect(fab, findsOneWidget,
      reason: 'ConflictAwareActionPage submit FAB must be present and enabled');
  await TestHelpers.tapWidget(tester, fab);
  print('[OK] Tapped submit FAB -> submitted expense');

  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.byType(ExpenseEditor).evaluate().isEmpty) {
      break;
    }
  }
  expect(find.byType(ExpenseEditor), findsNothing,
      reason:
          'ExpenseEditor must be dismissed after Firestore operation completes');
  print('[OK] Bottom-sheet dismissed');

  StandaloneExpense? expense;
  if (completer.isCompleted) {
    expense = await completer.future;
  } else {
    expense = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () async {
        await sub.cancel();
        throw TestFailure(
            'expenseCollection.onDocumentAdded did not fire after editor dismissal');
      },
    );
  }
  await sub.cancel();
  print('[OK] expenseCollection.onDocumentAdded received: $expense');

  await tester.pumpAndSettle();
  await onExpenseAdded(expense);
}
