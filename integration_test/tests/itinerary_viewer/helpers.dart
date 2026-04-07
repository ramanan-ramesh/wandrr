import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/checklists.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/notes.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/sights.dart';

import '../../helpers/test_helpers.dart';

Future<void> verifyItineraryPlanData(
    WidgetTester tester, ExpectedItineraryData expectedItineraryData) async {
  final sightsTab = find.byIcon(Icons.place_outlined);
  expect(sightsTab, findsOneWidget, reason: 'Sights tab should be present');
  await TestHelpers.tapWidget(tester, sightsTab);

  final sightsListWidget = find.descendant(
      of: find.byType(ItinerarySightsViewer), matching: find.byType(ListView));

  // Verify exact sight details
  for (final sight in expectedItineraryData.sights) {
    expect(
        find.descendant(of: sightsListWidget, matching: find.text(sight.name)),
        findsOneWidget,
        reason: 'Should display ${sight.name} sight name');
    if (sight.location != null) {
      expect(
          find.descendant(
              of: sightsListWidget, matching: find.text(sight.location!)),
          findsOneWidget,
          reason: 'Should display ${sight.location} sight location');
    }
    expect(
        find.descendant(of: sightsListWidget, matching: find.text(sight.time)),
        findsOneWidget,
        reason: 'Should display ${sight.time} sight time');
    expect(
        find.descendant(
            of: sightsListWidget, matching: find.text(sight.expense)),
        findsOneWidget,
        reason: 'Should display ${sight.expense} sight price');
  }
  print(
      '✓ Sights tab displays exact sight details (name, location and expense)');

  // === VERIFY NOTES TAB ===
  final notesTab = find.byIcon(Icons.note_outlined);
  expect(notesTab, findsOneWidget, reason: 'Notes tab should be present');
  await TestHelpers.tapWidget(tester, notesTab);

  // Verify exact notes
  final notesListWidget = find.descendant(
      of: find.byType(ItineraryNotesViewer), matching: find.byType(ListView));
  for (final note in expectedItineraryData.notes) {
    expect(find.descendant(of: notesListWidget, matching: find.text(note)),
        findsOneWidget,
        reason: 'Should display note: "$note"');
  }
  print('✓ Notes tab displays all 3 exact notes from Day 1');

  // === VERIFY CHECKLISTS TAB ===
  final checklistsTab = find.byIcon(Icons.checklist_outlined);
  expect(checklistsTab, findsOneWidget,
      reason: 'Checklists tab should be present');
  await TestHelpers.tapWidget(tester, checklistsTab);

  // Verify exact checklist
  final checklistsListWidget = find.descendant(
      of: find.byType(ItineraryChecklistTab), matching: find.byType(ListView));
  for (final checklist in expectedItineraryData.checklists) {
    expect(
        find.descendant(
            of: checklistsListWidget, matching: find.text(checklist.title)),
        findsOneWidget,
        reason: 'Should display checklist title "${checklist.title}"');
    final checklistCheckedItemsProgress = find.descendant(
        of: checklistsListWidget,
        matching: find.byType(LinearProgressIndicator));
    expect(checklistCheckedItemsProgress, findsOneWidget,
        reason: 'Should display checklist progress bar');
    final progress =
        tester.widget<LinearProgressIndicator>(checklistCheckedItemsProgress);
    expect(progress.value, checklist.progressIndicator,
        reason: 'Checklist progress should be ${checklist.progressIndicator}');
    expect(
        find.descendant(
            of: checklistsListWidget,
            matching: find.text(checklist.progressText)),
        findsOneWidget,
        reason: 'Should display checklist progress ${checklist.progressText}');
  }

  print('✓ Checklists tab displays exact checklist (title + progress)');
}

class ExpectedTimelineEvent {
  final String title;
  final String subtitle;
  final String? notes;
  final String? confirmationId;
  final IconData icon;

  ExpectedTimelineEvent({
    required this.title,
    required this.subtitle,
    this.notes,
    this.confirmationId,
    required this.icon,
  });
}

class ExpectedItineraryData {
  final Iterable<ExpectedSightData> sights;
  final Iterable<String> notes;
  final Iterable<ExpectedChecklistData> checklists;

  ExpectedItineraryData({
    required this.sights,
    required this.notes,
    required this.checklists,
  });
}

class ExpectedChecklistData {
  final String title;
  final double progressIndicator;
  final String progressText;

  ExpectedChecklistData({
    required this.title,
    required this.progressIndicator,
    required this.progressText,
  });
}

class ExpectedSightData {
  final String name;
  final String? location;
  final String expense;
  final String time;

  ExpectedSightData({
    required this.name,
    this.location,
    required this.expense,
    required this.time,
  });
}
