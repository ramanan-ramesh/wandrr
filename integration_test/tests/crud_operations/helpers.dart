import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/travel_editor.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/paid_by_tab.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/split_by_tab.dart';

import '../../helpers/test_helpers.dart';

/// Taps the add FAB on the current [Scaffold], then opens the creator
/// bottom-sheet entry matching [entityName]/[icon]/[title]/[subTitle] and
/// asserts that [editorType] is visible inside the [DraggableScrollableSheet].
///
/// This is the single entry-point for every "create new entity" test flow:
///   1. Taps the `+` FloatingActionButton on the Scaffold.
///   2. Delegates to [verifyAndOpenTripEntityEditor] for tile selection and
///      editor-presence assertion.
Future<void> openCreatorAndNavigateToEditor(
  WidgetTester tester, {
  required String entityName,
  required IconData icon,
  required String title,
  required String subTitle,
  required Type editorType,
}) async {
  final addFab = find.descendant(
    of: find.byType(Scaffold),
    matching: find.descendant(
      of: find.byType(FloatingActionButton),
      matching: find.byIcon(Icons.add),
    ),
  );
  await TestHelpers.tapWidget(tester, addFab);
  print('[OK] Add FAB tapped – Creator bottom-sheet opening');

  await verifyAndOpenTripEntityEditor(
    tester,
    entityName: entityName,
    icon: icon,
    title: title,
    subTitle: subTitle,
    editorType: editorType,
  );
}

/// Finds and taps the creator bottom-sheet tile whose icon/title/subtitle match,
/// then asserts that [editorType] is visible inside the DraggableScrollableSheet.
///
/// Throws a [TestFailure] immediately if:
///   - the matching tile is not found, or
///   - the expected editor widget is not opened after the tap.
Future<void> verifyAndOpenTripEntityEditor(
  WidgetTester tester, {
  required String entityName,
  required IconData icon,
  required String title,
  required String subTitle,
  required Type editorType,
}) async {
  await tester.pumpAndSettle();

  // Find the tile via its title text — this is unique among the action tiles.
  // The title Text widget is a direct child of the ListTile, so we walk up to
  // the ListTile key to confirm it is one of our action tiles.
  final titleFinder = find.text(title);
  expect(
    titleFinder,
    findsAtLeastNWidgets(1),
    reason: 'Creator bottom-sheet must contain a tile with title "$title" '
        '(entity: "$entityName"). '
        'Ensure the FAB was tapped and the bottom-sheet is open.',
  );

  // Walk up from the title text to the keyed ListTile.
  final matchingTile = find.ancestor(
    of: titleFinder,
    matching: find.byKey(const ValueKey('TripEntityCreator_Action_ListTile')),
  );
  expect(
    matchingTile,
    findsOneWidget,
    reason: 'Title "$title" must be inside a TripEntityCreator_Action_ListTile '
        '(entity: "$entityName").',
  );

  // Confirm that the expected icon and subtitle are also present in the tile.
  expect(
    find.descendant(of: matchingTile, matching: find.byIcon(icon)),
    findsAtLeastNWidgets(1),
    reason: 'Icon $icon must appear in the "$entityName" action tile.',
  );
  expect(
    find.descendant(of: matchingTile, matching: find.text(subTitle)),
    findsAtLeastNWidgets(1),
    reason:
        'Subtitle "$subTitle" must appear in the "$entityName" action tile.',
  );

  print('[OK] "$entityName" tile found in Creator bottom-sheet '
      '(title="$title", subtitle="$subTitle", icon=$icon)');
  await TestHelpers.tapWidget(tester, matchingTile);

  // The bottom-sheet transitions to the editor page; wait for it.
  await tester.pumpAndSettle();

  expect(
    find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byType(editorType),
    ),
    findsOneWidget,
    reason:
        '$editorType must be shown inside the DraggableScrollableSheet after '
        'tapping the "$entityName" tile.',
  );
  print('[OK] $editorType opened inside Creator bottom-sheet');
}

class CommonFormElements {
  final Type editorPage;
  final ExpenseEditorHelpers expenseEditor;

  Finder descendantOfEditorPage(Finder finder) =>
      find.descendant(of: find.byType(editorPage), matching: finder);

  CommonFormElements(this.editorPage)
      : expenseEditor = ExpenseEditorHelpers(editorPage);

  Finder get noteEditingField => descendantOfEditorPage(
      find.byKey(const ValueKey('NoteEditor_TextField')));

  Finder get datePicker =>
      descendantOfEditorPage(find.byType(PlatformDatePicker));

  Finder get dateTimePicker =>
      descendantOfEditorPage(find.byType(PlatformDateTimePicker));

  Finder get dateRangePicker =>
      descendantOfEditorPage(find.byType(PlatformDateRangePicker));

  Finder get createTripEntityButton => find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byIcon(Icons.add_rounded)));

  Finder get updateTripEntityButton => find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byIcon(Icons.check_rounded)));

  /// Selects a date-time value in the [PlatformDateTimePicker] at
  /// [indexOfDateTimePicker].
  ///
  /// The picker uses `flutter_datetime_picker_plus` with a
  /// `DateTimePickerModel` that has 3 columns:
  ///   - **Left (4x wide)**: days — index 0 = model's `currentTime` day.
  ///   - **Middle**: hours (0-23), offset by `minTime.hour` when on minTime's day.
  ///   - **Right**: minutes (0-59), offset by `minTime.minute` when on
  ///     minTime's day and hour.
  ///
  /// [dateTime] is the target date-time to select.
  Future<void> selectDateTime(WidgetTester tester,
      {required DateTime dateTime,
      required DateTime startDateTime,
      int indexOfDateTimePicker = 0}) async {
    // Read the PlatformDateTimePicker widget to get minTime, maxTime, currentTime.
    final pickerWidget = tester.widget<PlatformDateTimePicker>(
        dateTimePicker.at(indexOfDateTimePicker));
    final minTime = pickerWidget.startDateTime;
    final maxTime = pickerWidget.endDateTime;
    final currentTime = pickerWidget.currentDateTime;

    // Reproduce DateTimePickerModel's currentTime resolution:
    //   If currentTime is set → use it.
    //   Else: clamp DateTime.now() to [minTime, maxTime].
    DateTime modelCurrentTime;
    if (currentTime != null) {
      modelCurrentTime = currentTime;
    } else {
      final now = DateTime.now();
      if (minTime.isAfter(now)) {
        modelCurrentTime = minTime;
      } else if (maxTime.isBefore(now)) {
        modelCurrentTime = maxTime;
      } else {
        modelCurrentTime = now;
      }
    }

    // 1. Open the picker.
    await TestHelpers.tapWidget(
        tester, dateTimePicker.at(indexOfDateTimePicker));
    await tester.pumpAndSettle();

    // 2. Locate the 3 CupertinoPicker widgets rendered by the picker route.
    //    They are ordered: [day, hour, minute].
    final pickers = tester
        .widgetList<CupertinoPicker>(find.byType(CupertinoPicker))
        .toList();
    expect(pickers.length, greaterThanOrEqualTo(3),
        reason:
            'DateTimePicker must render at least 3 CupertinoPicker columns');
    final dayPicker = pickers[0];

    // 3. Compute scroll indices matching DateTimePickerModel logic.
    //    Left: index 0 = modelCurrentTime day. Target = modelCurrentTime + N days.
    final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final baseDay = DateTime(
        modelCurrentTime.year, modelCurrentTime.month, modelCurrentTime.day);
    final dayIndex = targetDay.difference(baseDay).inDays;

    //    Middle (hour): if target day == minTime day, index 0 = minTime.hour.
    final minTimeDay = DateTime(minTime.year, minTime.month, minTime.day);
    final onMinTimeDay = targetDay.isAtSameMomentAs(minTimeDay);
    final hourIndex =
        onMinTimeDay ? dateTime.hour - minTime.hour : dateTime.hour;

    //    Right (minute): if target day == minTime day AND hourIndex == 0,
    //    index 0 = minTime.minute.
    final onMinTimeHour = onMinTimeDay && (hourIndex == 0);
    final minuteIndex =
        onMinTimeHour ? dateTime.minute - minTime.minute : dateTime.minute;

    // 4. Scroll each column sequentially. After scrolling the day picker,
    //    the widget rebuilds via setState → refreshScrollOffset(), which
    //    creates **new** FixedExtentScrollController instances. We must
    //    re-query the CupertinoPicker widgets after each pumpAndSettle to
    //    get the current (non-stale) scroll controllers.

    // Helper to scroll a picker column and wait for settle.
    Future<void> scrollPickerColumn(
        FixedExtentScrollController? controller, int targetItem) async {
      if (controller == null) {
        return;
      }
      // Use animateToItem with a short duration rather than jumpToItem.
      // jumpToItem on newly-attached controllers in a test environment may
      // not reliably trigger onSelectedItemChanged / ScrollEndNotification,
      // whereas animateToItem produces a proper scroll animation that
      // pumpAndSettle can track.
      await controller.animateToItem(
        targetItem,
        duration: const Duration(milliseconds: 50),
        curve: Curves.linear,
      );
      await tester.pumpAndSettle();
    }

    // --- Day column ---
    await scrollPickerColumn(dayPicker.scrollController, dayIndex);

    // Re-obtain pickers after day scroll caused a rebuild.
    final pickersAfterDay = tester
        .widgetList<CupertinoPicker>(find.byType(CupertinoPicker))
        .toList();

    // --- Hour column ---
    await scrollPickerColumn(pickersAfterDay[1].scrollController, hourIndex);

    // Re-obtain pickers after hour scroll caused a rebuild.
    final pickersAfterHour = tester
        .widgetList<CupertinoPicker>(find.byType(CupertinoPicker))
        .toList();

    // --- Minute column ---
    await scrollPickerColumn(pickersAfterHour[2].scrollController, minuteIndex);

    // 5. Tap "Done" to confirm the selection.
    await TestHelpers.tapWidget(
        tester,
        find.descendant(
            of: find.byType(CupertinoButton), matching: find.text('Done')));
    print(
        '[OK] DateTime selected: ${dateTime.hourMinuteDateFormat} for date time picker - ${indexOfDateTimePicker + 1}');
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

  Finder get paidByTabContributorTile => descendantOfPaidByTab(
      find.byKey(const ValueKey('PaidByTab_ContributorTile')));

  Finder get splitByContributorTile => descendantOfSplitByByTab(
      find.byKey(const ValueKey('SplitByTab_ContributorTile')));

  Future<void> enterMoneyAmount(WidgetTester tester, Money money) async {
    var textField = descendantOfPaidByTab(
        find.byKey(const Key('ExpenseAmountEditField_TextField')));
    await tester.enterText(textField, money.amount.toString());
    await TestHelpers.tapWidget(
        tester,
        descendantOfPaidByTab(find
            .byKey(const Key('PlatformMoneyEditField_CurrencyPickerButton'))));
    var searchField = descendantOfPaidByTab(
        find.byKey(const Key('PlatformMoneyEditField_TextField')));
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
