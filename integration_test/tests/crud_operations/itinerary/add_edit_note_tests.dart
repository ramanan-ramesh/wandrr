/// Note CRUD integration tests.
///
/// Notes live inside a day's ItineraryPlanData document, edited through the
/// shared ItineraryPlanDataEditor. Add/edit are verified by re-reading the
/// day's plan data from the repository and by checking the Notes viewer tab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/notes.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../../../helpers/test_helpers.dart';
import 'helpers.dart';

final _tripStartDate = DateTime(2025, 9, 24);

/// Adds a new note to the trip's first day via the Creator bottom-sheet's
/// itinerary sub-action, fills it, submits, and verifies the persisted note
/// plus its entry in the Notes viewer tab.
Future<void> runAddNoteTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  final loc = TestHelpers.getAppLocalizations(tester, TripEditorPage);
  await openItinerarySubAction(tester,
      icon: Icons.note_add_rounded, label: loc.note);

  // Exactly one note is expanded (the newly-appended one); the seeded notes
  // stay collapsed, so their editor subtree is not built.
  final noteField = itineraryFormElements.noteEditingField;
  expect(noteField, findsOneWidget,
      reason: 'Exactly one note editor (the new one) must be expanded');
  await TestHelpers.enterText(tester, noteField, 'Buy museum pass online');
  print('[OK] Note form filled');

  await submitItineraryPlanDataAndVerify(tester, onSubmitted: () async {
    final planData = TestHelpers.getTripRepository(tester)
        .activeTrip!
        .itineraryCollection
        .getItineraryForDay(_tripStartDate)
        .planData;
    expect(planData.notes.contains('Buy museum pass online'), isTrue,
        reason: 'New note must be persisted');
    print('[OK] Note persisted');

    await TestHelpers.navigateToItineraryTab(tester, date: _tripStartDate);
    await TestHelpers.tapWidget(tester, find.byIcon(Icons.note_outlined));
    final scrollable = find.descendant(
        of: find.byType(ItineraryNotesViewer), matching: find.byType(ListView));
    final found = await TestHelpers.scrollUntilPresent(
      tester,
      scrollableFinder: scrollable,
      widgetFinder: find.text('Buy museum pass online'),
      reason: 'New note must appear in the Notes viewer tab',
    );
    expect(found, isTrue, reason: 'New note not found in Notes viewer tab');
    print('[OK] Note visible in Notes viewer tab');
  });
}

/// Edits the seeded "Arrive from London" note from the Notes viewer tab and
/// verifies the change is persisted and reflected in the viewer.
Future<void> runEditNoteTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);
  await TestHelpers.navigateToItineraryTab(tester, date: _tripStartDate);
  await TestHelpers.tapWidget(tester, find.byIcon(Icons.note_outlined));

  final noteTile = find.text('Arrive from London');
  expect(noteTile, findsOneWidget,
      reason: 'Seeded "Arrive from London" note must be shown');
  await TestHelpers.tapWidget(tester, noteTile);

  final noteField = itineraryFormElements.noteEditingField;
  await TestHelpers.waitForWidget(tester, noteField);
  print('[OK] Note editor opened for editing');

  expect(tester.widget<TextField>(noteField).controller?.text,
      'Arrive from London',
      reason: 'Editor must be pre-filled with the existing note text');

  await TestHelpers.enterText(tester, noteField, 'Arrive from London early');

  await submitItineraryPlanDataAndVerify(tester, onSubmitted: () async {
    final planData = TestHelpers.getTripRepository(tester)
        .activeTrip!
        .itineraryCollection
        .getItineraryForDay(_tripStartDate)
        .planData;
    expect(planData.notes.contains('Arrive from London early'), isTrue,
        reason: 'Updated note must be persisted');
    print('[OK] Note update persisted');

    final scrollable = find.descendant(
        of: find.byType(ItineraryNotesViewer), matching: find.byType(ListView));
    final found = await TestHelpers.scrollUntilPresent(
      tester,
      scrollableFinder: scrollable,
      widgetFinder: find.text('Arrive from London early'),
      reason: 'Updated note must appear in the Notes viewer tab',
    );
    expect(found, isTrue, reason: 'Updated note not found in Notes viewer tab');
    print('[OK] Updated note visible in Notes viewer tab');
  });
}
