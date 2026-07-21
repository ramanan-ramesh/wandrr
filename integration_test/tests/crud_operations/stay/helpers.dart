import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/lodging/lodging_editor.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

import '../../../helpers/test_helpers.dart';
import '../helpers.dart';

/// Reusable finders/flows scoped to [LodgingEditor].
class StayEditorForm {
  final CommonFormElements commonFormElements =
      CommonFormElements(LodgingEditor);

  Finder get locationAutoCompleteTextField => find.descendant(
      of: find.descendant(
          of: find.byType(LodgingEditor),
          matching: find.byType(PlatformGeoLocationAutoComplete)),
      matching: find.byKey(const ValueKey('PlatformAutoComplete_TextField')));

  /// Location options are rendered in an Overlay, so search globally by key.
  Finder get locationOption =>
      find.byKey(const ValueKey('PlatformAutoComplete_ListTile'));

  Finder get confirmationIdEditingField => find.descendant(
      of: find.byType(LodgingEditor),
      matching:
          find.byKey(const ValueKey('LodgingEditor_ConfirmationId_TextField')));

  /// Both check-in and check-out sections open the same date-range dialog;
  /// this returns the date button (always tagged with the calendar icon).
  Finder get dateRangeButton => find.descendant(
      of: find.byType(LodgingEditor),
      matching: find.byIcon(Icons.calendar_today_rounded));

  /// Enters [locationName] and taps the first matching auto-complete option.
  Future<void> selectLocation(WidgetTester tester, String locationName) async {
    await TestHelpers.enterText(
        tester, locationAutoCompleteTextField, locationName);
    // The auto-complete debounces for 500 ms before querying.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(locationOption, findsAtLeastNWidgets(1),
        reason: 'At least one location option must appear for "$locationName"');
    await TestHelpers.tapWidget(tester, locationOption.first);
    print('[OK] Location "$locationName" selected');
  }

  /// Opens the check-in/check-out range dialog and selects [checkinDay] ->
  /// [checkoutDay] (day-of-month integers within the same displayed month).
  /// Default check-in/out times (14:00 / 11:00) are applied automatically.
  Future<void> selectDateRange(
    WidgetTester tester, {
    required int checkinDay,
    required int checkoutDay,
  }) async {
    await TestHelpers.tapWidget(tester, dateRangeButton.first);
    await tester.pumpAndSettle();

    final dialog = find.byType(CalendarDatePicker2WithActionButtons);
    expect(dialog, findsOneWidget,
        reason: 'Stay date-range dialog must be shown');

    await TestHelpers.tapWidget(
        tester,
        find.descendant(
            of: dialog, matching: find.text(checkinDay.toString())));
    await TestHelpers.tapWidget(
        tester,
        find.descendant(
            of: dialog, matching: find.text(checkoutDay.toString())));

    final confirmButton =
        find.descendant(of: dialog, matching: find.text('Confirm'));
    await TestHelpers.tapWidget(tester, confirmButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    print('[OK] Stay date range $checkinDay -> $checkoutDay selected');
  }
}

/// Opens the Stay creator bottom-sheet and navigates into the [LodgingEditor].
Future<void> openStayCreatorPage(WidgetTester tester) async {
  await openCreatorAndNavigateToEditor(
    tester,
    entityName: 'Stay',
    icon: Icons.hotel,
    title: 'Stay',
    subTitle: 'Add lodging details',
    editorType: LodgingEditor,
  );
  print('[OK] Stay creator opened');
}

/// Taps the ConflictAwareActionPage submit FAB, awaits the newly-added
/// [LodgingFacade] from the collection stream, then runs [onLodgingAdded].
Future<void> submitStayAndVerify(
  WidgetTester tester,
  StayEditorForm form, {
  required Future<void> Function(LodgingFacade lodging) onLodgingAdded,
}) async {
  final collection =
      TestHelpers.getTripRepository(tester).activeTrip!.lodgingCollection;
  final completer = Completer<LodgingFacade>();
  late StreamSubscription<CollectionItemChangeMetadata<LodgingFacade>> sub;
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
  print('[OK] Tapped submit FAB -> submitted stay');

  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.byType(LodgingEditor).evaluate().isEmpty) {
      break;
    }
  }

  expect(find.byType(LodgingEditor), findsNothing,
      reason:
          'LodgingEditor must be dismissed after Firestore operation completes');
  print('[OK] Bottom-sheet dismissed');

  LodgingFacade? lodging;
  if (completer.isCompleted) {
    lodging = await completer.future;
  } else {
    lodging = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () async {
        await sub.cancel();
        throw TestFailure(
            'lodgingCollection.onDocumentAdded did not fire after editor dismissal');
      },
    );
  }
  await sub.cancel();
  print('[OK] lodgingCollection.onDocumentAdded received: $lodging');

  await tester.pumpAndSettle();
  await onLodgingAdded(lodging);
}
