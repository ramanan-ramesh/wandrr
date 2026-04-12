import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_viewer.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/checklists.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/notes.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/sights.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/widgets/timeline_item.dart';

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

/// Verifies all expected timeline events on the [ItineraryViewer] for [itineraryDate].
///
/// Scrolls the viewer to collect every [TimelineItem], asserts the count
/// matches [expectedEvents], then validates title, subtitle, optional notes
/// and optional confirmationId for each event in order.
Future<void> verifyTimelineEvents(
    WidgetTester tester,
    Iterable<ExpectedTimelineEvent> expectedEvents,
    DateTime itineraryDate) async {
  expect(find.byType(ItineraryViewer), findsOneWidget);
  final itineraryViewerDate =
      (find.byType(ItineraryViewer).evaluate().single.widget as ItineraryViewer)
          .itineraryDay;
  expect(itineraryViewerDate.isOnSameDayAs(itineraryDate), true,
      reason: 'ItineraryViewer should display first trip date');
  print(
      '✓ Itinerary viewer displayed for trip date - ${itineraryDate.dateMonthFormat}');

  final scrollableFinder = find.descendant(
    of: find.byType(ItineraryViewer),
    matching: find.byType(SingleChildScrollView),
  );
  expect(scrollableFinder, findsOneWidget);

  final timelineItems =
      await TestHelpers.collectWidgetsByScrolling<TimelineItem>(
    tester: tester,
    scrollableFinder: scrollableFinder,
    widgetFinder: find.byType(TimelineItem),
    getUniqueId: (widget) => '${widget.event.time}_${widget.event.title}',
    expectedCount: expectedEvents.length,
    timeout: const Duration(seconds: 30),
  );

  print(
      '✓ Found ${timelineItems.length} actual TimelineItem instances (with scrolling)');

  expect(timelineItems.length, expectedEvents.length,
      reason: 'Number of actual timeline events should match expected events');

  for (var i = 0; i < expectedEvents.length; i++) {
    final expectedEvent = expectedEvents.elementAt(i);
    final timelineItem = timelineItems[i];
    final itemFinder = find.byWidget(timelineItem);

    expect(
        find.descendant(
            of: itemFinder, matching: find.text(expectedEvent.title)),
        findsOneWidget,
        reason: 'Event #${i + 1} title should be ${expectedEvent.title}');

    expect(
        find.descendant(
            of: itemFinder, matching: find.text(expectedEvent.subtitle)),
        findsOneWidget,
        reason: 'Event #${i + 1} subtitle should be ${expectedEvent.subtitle}');

    if (expectedEvent.notes != null) {
      expect(
          find.descendant(
              of: itemFinder, matching: find.text(expectedEvent.notes!)),
          findsOneWidget,
          reason: 'Event #${i + 1} notes should be ${expectedEvent.notes}');
    }

    if (expectedEvent.confirmationId != null) {
      expect(
          find.descendant(
              of: itemFinder,
              matching: find.text(expectedEvent.confirmationId!)),
          findsOneWidget,
          reason:
              'Event #${i + 1} confirmation ID should be ${expectedEvent.confirmationId}');
    }
  }

  print('\n✓ All timeline events verified and in correct chronological order');
}

/// Verifies that a newly created transit appears in the [ItineraryViewer]
/// timeline for [day].
///
/// [locationPair] is the "departure -> arrival" substring guaranteed to appear
/// in the timeline card title (timezone-independent).
/// Optionally asserts [operator], [confirmationId] and [note] are visible.
Future<void> verifyTransitTimelineEntry(
  WidgetTester tester, {
  required DateTime day,
  required String locationPair,
  String? operator,
  String? confirmationId,
  String? note,
}) async {
  final scrollable = find.descendant(
    of: find.byType(ItineraryViewer),
    matching: find.byType(SingleChildScrollView),
  );

  final titleFinder = find.textContaining(locationPair);

  final found = await TestHelpers.scrollUntilPresent(
    tester,
    scrollableFinder: scrollable,
    widgetFinder: titleFinder,
    reason: 'Timeline must contain text containing "$locationPair"',
  );
  expect(found, isTrue,
      reason:
          'Transit timeline entry containing "$locationPair" not found on ${day.toIso8601String().substring(0, 10)}');
  print('  [OK] Timeline entry found containing: "$locationPair"');

  if (operator != null) {
    expect(find.text(operator), findsAtLeastNWidgets(1),
        reason: 'Operator "$operator" must appear in the timeline card');
    print('  [OK] Operator "$operator" present');
  }
  if (confirmationId != null) {
    expect(find.text(confirmationId), findsAtLeastNWidgets(1),
        reason:
            'Confirmation ID "$confirmationId" must appear in the timeline card');
    print('  [OK] Confirmation ID "$confirmationId" present');
  }
  if (note != null) {
    expect(find.text(note), findsAtLeastNWidgets(1),
        reason: 'Note "$note" must appear in the timeline card');
    print('  [OK] Note "$note" present');
  }
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
    required this.icon, this.notes,
    this.confirmationId,
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
    required this.expense, required this.time, this.location,
  });
}
