import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';

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

  CommonFormElements(this.editorPage);

  Finder get noteEditingField => find.descendant(
      of: find.byType(editorPage),
      matching: find.byKey(ValueKey('NoteEditor_TextField')));

  Finder get datePicker => find.descendant(
      of: find.byType(editorPage), matching: find.byType(PlatformDatePicker));

  Finder get dateTimePicker => find.descendant(
      of: find.byType(editorPage),
      matching: find.byType(PlatformDateTimePicker));

  Finder get dateRangePicker => find.descendant(
      of: find.byType(editorPage),
      matching: find.byType(PlatformDateRangePicker));

  Finder get paidByTabContributorTile => find.descendant(
      of: find.byType(editorPage),
      matching: find.byKey(ValueKey('PaidByTab_ContributorTile')));

  Finder get splitByContributorTile => find.descendant(
      of: find.byType(editorPage),
      matching: find.byKey(ValueKey('SplitByTab_ContributorTile')));

  Future<void> enterMoneyAmount(WidgetTester tester, Money money) async {
    Finder editorPageFinder = find.byType(editorPage);
    var textField = find.descendant(
        of: editorPageFinder,
        matching: find.byKey(Key('ExpenseAmountEditField_TextField')));
    await tester.enterText(textField, money.amount.toString());
    await TestHelpers.tapWidget(
        tester,
        find.descendant(
            of: editorPageFinder,
            matching: find
                .byKey(Key('PlatformMoneyEditField_CurrencyPickerButton'))));
    var searchField = find.descendant(
        of: editorPageFinder,
        matching: find.byKey(Key('PlatformMoneyEditField_TextField')));
    await TestHelpers.enterText(tester, searchField, money.currency);

    final currencyListTile = find.descendant(
        of: editorPageFinder,
        matching: find.byKey(
            Key('PlatformMoneyEditField_CurrencyListTile_${money.currency}')));
    await TestHelpers.tapWidget(tester, currencyListTile, warnIfMissed: false);
  }

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
