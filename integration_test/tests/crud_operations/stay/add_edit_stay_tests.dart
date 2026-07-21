/// Stay (Lodging) CRUD integration tests.
///
/// Covers add + edit flows for [LodgingFacade] via the Creator bottom-sheet
/// and the itinerary timeline, verified through the lodging collection's
/// change streams (not brittle widget-tree probing).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_viewer.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/lodging/lodging_editor.dart';

import '../../../helpers/test_helpers.dart';
import 'helpers.dart';

final _form = StayEditorForm();

/// Adds a new stay via the Creator bottom-sheet, fills every field, submits,
/// and verifies both the persisted [LodgingFacade] and its check-in timeline
/// entry.
Future<void> runAddStayTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await openStayCreatorPage(tester);

  await _form.selectLocation(tester, 'Amsterdam');
  // Sept 26 -> Sept 27: a gap in the seeded lodgings, so the check-in day is
  // conflict-free (Paris checks out earlier that morning).
  await _form.selectDateRange(tester, checkinDay: 26, checkoutDay: 27);
  await TestHelpers.enterText(
      tester, _form.confirmationIdEditingField, 'AMS-STOP-999');

  await _form.commonFormElements.expenseEditor.switchToPaidByTab(tester);
  final amountField = find.descendant(
    of: _form.commonFormElements.expenseEditor.paidByTabContributorTile.first,
    matching: find.byKey(const ValueKey('ExpenseAmountEditField_TextField')),
  );
  await TestHelpers.enterText(tester, amountField, '80');

  await TestHelpers.enterText(tester, _form.commonFormElements.noteEditingField,
      'Quick overnight stop');
  print('[OK] Stay form filled');

  await submitStayAndVerify(tester, _form, onLodgingAdded: (lodging) async {
    print('[OK] Lodging added: $lodging (id: ${lodging.id})');
    expect(lodging.confirmationId, 'AMS-STOP-999',
        reason: 'Persisted confirmation ID must match');
    expect(lodging.notes, 'Quick overnight stop',
        reason: 'Persisted note must match');
    expect(lodging.expense.totalExpense.amount, 80.0,
        reason: 'Persisted expense amount must match');

    await TestHelpers.navigateToDateInItineraryViewer(
        tester, lodging.checkinDateTime!);
    final scrollable = find.descendant(
        of: find.byType(ItineraryViewer),
        matching: find.byType(SingleChildScrollView));
    final found = await TestHelpers.scrollUntilPresent(
      tester,
      scrollableFinder: scrollable,
      widgetFinder: find.text('AMS-STOP-999'),
      reason: 'Check-in timeline entry must show the confirmation ID',
    );
    expect(found, isTrue,
        reason: 'Check-in timeline entry for the new stay not found');
    print('[OK] Check-in timeline entry verified');
  });
}

/// Edits the seeded Brussels lodging from its check-in timeline entry and
/// verifies the change propagates through the lodging collection's
/// `onDocumentUpdated` stream.
Future<void> runEditStayTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await TestHelpers.navigateToDateInItineraryViewer(
      tester, DateTime(2025, 9, 27));

  final loc = TestHelpers.getAppLocalizations(tester, ItineraryViewer);
  final checkInEntry = find.text(loc.checkIn);
  expect(checkInEntry, findsOneWidget,
      reason: 'Brussels check-in entry must be shown on Sept 27');
  await TestHelpers.tapWidget(tester, checkInEntry);
  await TestHelpers.waitForWidget(tester, find.byType(LodgingEditor));
  print('[OK] LodgingEditor opened for editing (Brussels stay)');

  final confirmationField = _form.confirmationIdEditingField;
  expect(tester.widget<TextFormField>(confirmationField).initialValue,
      'BRU-HTL-789',
      reason: 'Editor must be pre-filled with the existing confirmation ID');

  await TestHelpers.enterText(tester, confirmationField, 'BRU-HTL-UPDATED');

  final collection =
      TestHelpers.getTripRepository(tester).activeTrip!.lodgingCollection;
  final completer = Completer<LodgingFacade>();
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
    if (find.byType(LodgingEditor).evaluate().isEmpty) {
      break;
    }
  }
  expect(find.byType(LodgingEditor), findsNothing,
      reason: 'LodgingEditor must be dismissed after the update completes');

  final updated = completer.isCompleted
      ? await completer.future
      : await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () async {
            await sub.cancel();
            throw TestFailure(
                'lodgingCollection.onDocumentUpdated did not fire after editor dismissal');
          },
        );
  await sub.cancel();
  expect(updated.confirmationId, 'BRU-HTL-UPDATED',
      reason: 'Updated confirmation ID must be persisted');
  print('[OK] Lodging updated: confirmationId = ${updated.confirmationId}');

  await tester.pumpAndSettle();
  final scrollable = find.descendant(
      of: find.byType(ItineraryViewer),
      matching: find.byType(SingleChildScrollView));
  final found = await TestHelpers.scrollUntilPresent(
    tester,
    scrollableFinder: scrollable,
    widgetFinder: find.text('BRU-HTL-UPDATED'),
    reason: 'Updated confirmation ID must be reflected in the timeline',
  );
  expect(found, isTrue, reason: 'Updated check-in timeline entry not found');
  print('[OK] Timeline reflects updated confirmation ID');
}
