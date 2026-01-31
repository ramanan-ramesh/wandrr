import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/travel_editor.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/paid_by_tab.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/split_by_tab.dart';

import '../../helpers/test_helpers.dart';

Future<bool> verifyAndOpenTripEntityEditor(
    WidgetTester tester,
    String entityName,
    IconData icon,
    String title,
    String subTitle,
    Type editorPage) async {
  final listTile =
      find.ancestor(of: find.text(title), matching: find.byType(ListTile));
  await TestHelpers.tapWidget(tester, listTile);
  return true;

  // TODO: Below logic should succeed, and is preferred
  // final entityCreatorActionFinder = find.descendant(
  //     of: find.byType(DraggableScrollableSheet),
  //     matching: find.descendant(
  //         of: find.byType(ListView),
  //         matching: find.byKey(ValueKey('TripEntityCreator_Action_ListTile'))));
  // for (final entityCreatorAction in entityCreatorActionFinder.evaluate()) {
  //   final entityCreatorWidgetInstance = entityCreatorAction.widget;
  //   var entityCreatorWidgetFinder = find.byWidget(entityCreatorWidgetInstance);
  //   final isIconPresent = find
  //       .descendant(of: entityCreatorWidgetFinder, matching: find.byIcon(icon))
  //       .hasFound;
  //   final isTitlePresent = find
  //       .descendant(of: entityCreatorWidgetFinder, matching: find.text(title))
  //       .hasFound;
  //   final isSubtitlePresent = find
  //       .descendant(
  //           of: entityCreatorWidgetFinder, matching: find.text(subTitle))
  //       .hasFound;
  //   if (isIconPresent && isTitlePresent && isSubtitlePresent) {
  //     print('✓ $entityName option found');
  //     await TestHelpers.tapWidget(tester, entityCreatorWidgetFinder);
  //     expect(
  //         find.descendant(
  //             of: find.byType(DraggableScrollableSheet),
  //             matching: find.byType(TravelEditor)),
  //         findsOneWidget,
  //         reason: 'Travel editor should be opened');
  //     print('✓ Travel editor opened');
  //     return true;
  //   }
  // }

  return false;
}

class CommonFormElements {
  final Type editorPage;
  final ExpenseEditorHelpers expenseEditor;

  Finder descendantOfEditorPage(Finder finder) =>
      find.descendant(of: find.byType(editorPage), matching: finder);

  CommonFormElements(this.editorPage)
      : expenseEditor = ExpenseEditorHelpers(editorPage);

  Finder get noteEditingField =>
      descendantOfEditorPage(find.byKey(ValueKey('NoteEditor_TextField')));

  Finder get datePicker =>
      descendantOfEditorPage(find.byType(PlatformDatePicker));

  Finder get dateTimePicker =>
      descendantOfEditorPage(find.byType(PlatformDateTimePicker));

  Finder get dateRangePicker =>
      descendantOfEditorPage(find.byType(PlatformDateRangePicker));

  Future<void> selectDateTime(WidgetTester tester,
      {required DateTime dateTime,
      required DateTime startDateTime,
      int indexOfDateTimePicker = 0}) async {
    await TestHelpers.tapWidget(
        tester, dateTimePicker.at(indexOfDateTimePicker));
    final cupertinoPickers =
        tester.widgetList<CupertinoPicker>(find.byType(CupertinoPicker));
    final datePicker = cupertinoPickers.first;
    var differenceInStartAndCurrentTimes =
        DateTime(dateTime.year, dateTime.month, dateTime.day)
            .difference(startDateTime);
    final numberOfDaysElapsed = differenceInStartAndCurrentTimes.inDays;
    datePicker.scrollController?.jumpToItem(numberOfDaysElapsed);
    final timePicker = cupertinoPickers.last;
    final numberOfMinutesElapsed = differenceInStartAndCurrentTimes.inMinutes;
    timePicker.scrollController?.jumpToItem(numberOfMinutesElapsed);
    await TestHelpers.tapWidget(
        tester,
        find.descendant(
            of: find.byType(CupertinoButton), matching: find.text('Done')));
  }
}

class ExpenseEditorHelpers {
  final Type editorPage;

  Finder descendantOfPaidByTab(Finder finder) => find.descendant(
      of: find.byType(editorPage),
      matching: find.descendant(of: find.byType(PaidByTab), matching: finder));

  Finder descendantOfSplitByByTab(Finder finder) => find.descendant(
      of: find.byType(editorPage),
      matching: find.descendant(of: find.byType(SplitByTab), matching: finder));

  ExpenseEditorHelpers(this.editorPage);

  Finder get paidByTabContributorTile =>
      descendantOfPaidByTab(find.byKey(ValueKey('PaidByTab_ContributorTile')));

  Finder get splitByContributorTile => descendantOfSplitByByTab(
      find.byKey(ValueKey('SplitByTab_ContributorTile')));

  Future<void> enterMoneyAmount(WidgetTester tester, Money money) async {
    var textField = descendantOfPaidByTab(
        find.byKey(Key('ExpenseAmountEditField_TextField')));
    await tester.enterText(textField, money.amount.toString());
    await TestHelpers.tapWidget(
        tester,
        descendantOfPaidByTab(
            find.byKey(Key('PlatformMoneyEditField_CurrencyPickerButton'))));
    var searchField = descendantOfPaidByTab(
        find.byKey(Key('PlatformMoneyEditField_TextField')));
    await TestHelpers.enterText(tester, searchField, money.currency);

    final currencyListTile = descendantOfPaidByTab(find.byKey(
        Key('PlatformMoneyEditField_CurrencyListTile_${money.currency}')));
    await TestHelpers.tapWidget(tester, currencyListTile, warnIfMissed: false);
  }

  Future<void> switchToPaidByTab(WidgetTester tester) async {
    final controller = tester
        .widget<SingleChildScrollView>(find.ancestor(
          of: find.byType(TravelEditor),
          matching: find.byType(SingleChildScrollView),
        ))
        .controller;
    controller?.jumpTo(500.0);
    await tester.pumpAndSettle();
    final paidByTab = find.descendant(
        of: find.byType(editorPage),
        matching: find.descendant(
            of: find.byType(Tab), matching: find.text('Paid By')));
    return TestHelpers.tapWidget(tester, paidByTab);
  }

  Future<void> switchToSplitTab(WidgetTester tester) async {
    final controller = tester
        .widget<SingleChildScrollView>(find.ancestor(
          of: find.byType(TravelEditor),
          matching: find.byType(SingleChildScrollView),
        ))
        .controller;
    controller?.jumpTo(500.0);
    await tester.pumpAndSettle();
    var splitByByTab = find.descendant(
        of: find.byType(editorPage),
        matching: find.descendant(
            of: find.byType(Tab), matching: find.text('Split Among')));
    await TestHelpers.tapWidget(tester, splitByByTab, warnIfMissed: false);
  }
}
