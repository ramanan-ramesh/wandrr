/// Checklist CRUD integration tests.
///
/// Checklists live inside a day's ItineraryPlanData document, edited through
/// the shared ItineraryPlanDataEditor. Add/edit are verified by re-reading
/// the day's plan data from the repository and by checking the Checklists
/// viewer tab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/editor/checklists.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/checklists.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../../../helpers/test_helpers.dart';
import 'helpers.dart';

final _tripStartDate = DateTime(2025, 9, 24);

/// Adds a new checklist to the trip's first day via the Creator bottom-sheet's
/// itinerary sub-action, fills its title + one item, submits, and verifies
/// the persisted checklist plus its entry in the Checklists viewer tab.
Future<void> runAddChecklistTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  final loc = TestHelpers.getAppLocalizations(tester, TripEditorPage);
  await openItinerarySubAction(tester,
      icon: Icons.checklist_rounded, label: loc.checklist);

  // Exactly one checklist is expanded (the newly-appended one); the seeded
  // "Day 1" checklist stays collapsed, so its editor subtree is not built.
  final titleField = find.descendant(
      of: find.byType(ItineraryChecklistsEditor),
      matching: find.byType(TextFormField));
  expect(titleField, findsOneWidget,
      reason: 'Exactly one checklist editor (the new one) must be expanded');
  await TestHelpers.enterText(tester, titleField, 'Packing list');

  final addItemButton = find.descendant(
      of: find.byType(ItineraryChecklistsEditor),
      matching: find.widgetWithText(ElevatedButton, loc.addItem));
  await TestHelpers.tapWidget(tester, addItemButton);

  final itemField = find
      .descendant(
          of: find.byType(ItineraryChecklistsEditor),
          matching: find.byType(TextFormField))
      .last;
  await TestHelpers.enterText(tester, itemField, 'Passport');
  print('[OK] Checklist form filled');

  await submitItineraryPlanDataAndVerify(tester, onSubmitted: () async {
    final planData = TestHelpers.getTripRepository(tester)
        .activeTrip!
        .itineraryCollection
        .getItineraryForDay(_tripStartDate)
        .planData;
    final checklist =
        planData.checkLists.firstWhere((c) => c.title == 'Packing list');
    expect(checklist.items.map((i) => i.item), contains('Passport'),
        reason: 'New checklist item must be persisted');
    print('[OK] Checklist persisted: $checklist');

    await TestHelpers.navigateToItineraryTab(tester, date: _tripStartDate);
    await TestHelpers.tapWidget(tester, find.byIcon(Icons.checklist_outlined));
    final scrollable = find.descendant(
        of: find.byType(ItineraryChecklistTab),
        matching: find.byType(ListView));
    final found = await TestHelpers.scrollUntilPresent(
      tester,
      scrollableFinder: scrollable,
      widgetFinder: find.text('Packing list'),
      reason: 'New checklist must appear in the Checklists viewer tab',
    );
    expect(found, isTrue,
        reason: 'New checklist not found in Checklists viewer tab');
    print('[OK] Checklist visible in Checklists viewer tab');
  });
}

/// Edits the seeded "Day 1" checklist from the Checklists viewer tab (via its
/// edit icon), toggles an item, and verifies the change is persisted and
/// reflected in the viewer's progress indicator.
Future<void> runEditChecklistTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);
  await TestHelpers.navigateToItineraryTab(tester, date: _tripStartDate);
  await TestHelpers.tapWidget(tester, find.byIcon(Icons.checklist_outlined));

  final checklistTile = find.text('Day 1');
  expect(checklistTile, findsOneWidget,
      reason: 'Seeded "Day 1" checklist must be shown');
  final editButton = find.descendant(
      of: find.byType(ItineraryChecklistTab),
      matching: find.byIcon(Icons.edit_outlined));
  await TestHelpers.tapWidget(tester, editButton.first);

  final titleField = find.descendant(
      of: find.byType(ItineraryChecklistsEditor),
      matching: find.byType(TextFormField));
  await TestHelpers.waitForWidget(tester, titleField);
  print('[OK] Checklist editor opened for editing (Day 1)');

  expect(
      tester.widget<TextFormField>(titleField.first).controller?.text, 'Day 1',
      reason: 'Editor must be pre-filled with the existing checklist title');

  final checkbox = find.descendant(
      of: find.byType(ItineraryChecklistsEditor),
      matching: find.byType(Checkbox));
  expect(checkbox, findsAtLeastNWidgets(1));
  await TestHelpers.tapWidget(tester, checkbox.first, warnIfMissed: false);

  await submitItineraryPlanDataAndVerify(tester, onSubmitted: () async {
    final planData = TestHelpers.getTripRepository(tester)
        .activeTrip!
        .itineraryCollection
        .getItineraryForDay(_tripStartDate)
        .planData;
    final checklist = planData.checkLists.firstWhere((c) => c.title == 'Day 1');
    expect(checklist.items.first.isChecked, isTrue,
        reason: 'Toggled item must be persisted as checked');
    print('[OK] Checklist item toggle persisted');

    final progressText = find.text('1/2');
    final scrollable = find.descendant(
        of: find.byType(ItineraryChecklistTab),
        matching: find.byType(ListView));
    final found = await TestHelpers.scrollUntilPresent(
      tester,
      scrollableFinder: scrollable,
      widgetFinder: progressText,
      reason: 'Checklist progress must reflect the toggled item',
    );
    expect(found, isTrue,
        reason: 'Updated checklist progress not found in viewer tab');
    print('[OK] Updated checklist progress visible in viewer tab');
  });
}
