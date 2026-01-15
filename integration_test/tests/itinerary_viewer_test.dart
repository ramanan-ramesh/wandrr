import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_navigator.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_viewer.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/checklists.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/notes.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/sights.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/widgets/timeline_item_widget.dart';

import '../helpers/test_helpers.dart';

final expectedDayOneEvents = <_ExpectedTimelineEvent>[
  _ExpectedTimelineEvent(
      title: 'YXU → CDG\n08:00 AM - 11:00 AM\nEurope/London - Europe/Paris',
      subtitle: 'Air France AF 542',
      notes: 'Direct flight',
      confirmationId: 'AF123456',
      icon: Icons.flight_rounded),
  _ExpectedTimelineEvent(
      title: 'Check-In • 02:00 PM',
      subtitle: 'Paris',
      notes: 'City center, 2 nights',
      confirmationId: 'PARIS-HTL-001',
      icon: Icons.login),
  _ExpectedTimelineEvent(
    title: 'Eiffel Tower • 03:30 PM (Europe/Paris)',
    subtitle: 'Eiffel Tower, Paris • 26.00 EUR',
    notes: 'Iconic landmark',
    icon: Icons.place_rounded,
  ),
];
final expectedLastDayEvents = <_ExpectedTimelineEvent>[
  _ExpectedTimelineEvent(
    title: 'Check-Out • 11:00 AM',
    subtitle: 'Amsterdam',
    notes: 'Budget hostel',
    confirmationId: 'AMS-HSTL-123',
    icon: Icons.logout,
  ),
  _ExpectedTimelineEvent(
    title: 'Keukenhof flower show • 12:00 PM (Europe/Amsterdam)',
    subtitle: 'Keukenhof flower show, Amsterdam • 40.00 EUR',
    notes: 'Flower show',
    icon: Icons.place_rounded,
  ),
  _ExpectedTimelineEvent(
    title: 'AMS → YXU\n01:00 PM - 03:30 PM\nEurope/Amsterdam - Europe/London',
    subtitle: 'British Airways BA 621',
    notes: 'Direct flight',
    confirmationId: 'BA345612',
    icon: Icons.flight_rounded,
  ),
];

final expectedDayOneItineraryData = _ExpectedItineraryData(
  sights: <_ExpectedSightData>[
    _ExpectedSightData(
      name: 'Eiffel Tower',
      expense: '26 €',
      time: "15:30",
    ),
  ],
  notes: <String>[
    'Arrive from London',
    'Check in',
    'Visit Eiffel Tower',
  ],
  checklists: <_ExpectedChecklistData>[
    _ExpectedChecklistData(
      title: 'Day 1',
      progressIndicator: 0,
      progressText: "0/2",
    ),
  ],
);

final expectedLastDayItineraryData = _ExpectedItineraryData(
  sights: [
    _ExpectedSightData(
      name: 'Keukenhof flower show',
      expense: '40 €',
      time: "12:00",
    ),
  ],
  notes: ['Breakfast', 'Visit Keukenhof', 'Return home'],
  checklists: [
    _ExpectedChecklistData(
      title: 'Last day',
      progressIndicator: 0,
      progressText: "0/2",
    ),
  ],
);

/// Test: ItineraryViewer displays first trip date's itinerary with all components by default
/// Verifies transits, lodgings, sights, notes, and checklists are displayed
Future<void> runItineraryViewerDefaultDateTest(WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

  await _verifyTimelineEvents(
      tester, expectedDayOneEvents, DateTime(2025, 9, 24));
  await _verifyItineraryPlanData(tester, expectedDayOneItineraryData);

  print('✓ All itinerary components verified for first trip date');
}

/// Test: Verify itinerary navigation on choosing a date
Future<void> runItineraryViewerNavigateToDateTest(WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

  // Open date range picker
  final datePicker = find.descendant(
      of: find.byType(ItineraryNavigator),
      matching: find.byType(PlatformDatePicker));
  await TestHelpers.tapWidget(tester, datePicker);

  // Verify possible selectable dates
  final calendarPicker = tester.widget<CalendarDatePicker2WithActionButtons>(
      find.byType(CalendarDatePicker2WithActionButtons));
  final calendarPickerConfig = calendarPicker.config;
  _matchDate(calendarPickerConfig.firstDate, DateTime(2025, 9, 24),
      reason: 'First possible selectable date should be trip start date');
  _matchDate(calendarPickerConfig.lastDate, DateTime(2025, 9, 29),
      reason: 'Last possible selectable date should be trip end date');

  // Select 29th September
  final lastDateButton = find.descendant(
      of: find.byType(CalendarDatePicker2WithActionButtons),
      matching: find.text('29'));
  await TestHelpers.tapWidget(tester, lastDateButton);
  final confirmButton = find.descendant(
      of: find.byType(CalendarDatePicker2WithActionButtons),
      matching: find.text('OK'));
  await TestHelpers.tapWidget(tester, confirmButton, warnIfMissed: false);

  await _verifyTimelineEvents(
      tester, expectedLastDayEvents, DateTime(2025, 9, 29));
  await _verifyItineraryPlanData(tester, expectedLastDayItineraryData);

  print('✓ ItineraryViewer displays itinerary for selected date');
}

/// Test: Verify itinerary plan data on Day 2 (multiple sights, different notes/checklists)
Future<void> runItineraryViewerNavigateNextTest(WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

  // Navigate to Day 6 (September 29)
  for (int i = 1; i <= 5; i++) {
    final nextButton = find.descendant(
        of: find.byType(ItineraryNavigator),
        matching: find.byIcon(Icons.chevron_right_rounded));
    await TestHelpers.tapWidget(tester, nextButton);
  }
  print('✓ Navigated to Day 6 (September 29)');

  await _verifyTimelineEvents(
      tester, expectedLastDayEvents, DateTime(2025, 9, 29));

  print('✓ Day 6 Timeline tab: transits and lodging displayed');

  await _verifyItineraryPlanData(tester, expectedLastDayItineraryData);

  print(
      '✅ Day 6 itinerary plan data verified (multiple sights, notes, checklists)');
}

/// Test: Navigate to previous date in itinerary
Future<void> runItineraryViewerNavigatePreviousTest(WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // First navigate to next day so we can go back
  final nextButton = find.byIcon(Icons.chevron_right_rounded);
  await TestHelpers.tapWidget(tester, nextButton.first);

  // Find the previous button (left chevron)
  final previousButton = find.byIcon(Icons.chevron_left_rounded);
  await TestHelpers.tapWidget(tester, previousButton.first);

  await _verifyTimelineEvents(
      tester, expectedDayOneEvents, DateTime(2025, 9, 24));
  await _verifyItineraryPlanData(tester, expectedDayOneItineraryData);

  print('✓ Successfully navigated to previous date');
}

/// Test: Cannot navigate beyond trip start date
Future<void> runItineraryViewerNavigationBoundaryStartTest(
    WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Find the previous button (left chevron) - should be disabled on first day
  final previousButton = find.byIcon(Icons.chevron_left_rounded);
  await TestHelpers.tapWidget(tester, previousButton);

  await _verifyTimelineEvents(
      tester, expectedDayOneEvents, DateTime(2025, 9, 24));
  await _verifyItineraryPlanData(tester, expectedDayOneItineraryData);

  print(
      '✓ Pressing Previous button on initial layout doesn\'t update ItineraryViewer');
}

/// Test: Cannot navigate beyond trip end date
Future<void> runItineraryViewerNavigationBoundaryEndTest(
    WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Navigate to Day 6 (September 29), and press an additional time
  for (int i = 1; i <= 6; i++) {
    final nextButton = find.descendant(
        of: find.byType(ItineraryNavigator),
        matching: find.byIcon(Icons.chevron_right_rounded));
    await TestHelpers.tapWidget(tester, nextButton);
  }
  print('✓ Navigated to Day 6 (September 29)');

  await _verifyTimelineEvents(
      tester, expectedLastDayEvents, DateTime(2025, 9, 29));

  print('✓ Day 6 Timeline tab: transits and lodging displayed');

  await _verifyItineraryPlanData(tester, expectedLastDayItineraryData);

  print(
      '✓ Pressing Next button while on last trip date doesn\'t update ItineraryViewer');
}

Future<void> _verifyTimelineEvents(
    WidgetTester tester,
    Iterable<_ExpectedTimelineEvent> expectedEvents,
    DateTime itineraryDate) async {
  expect(find.byType(ItineraryViewer), findsOneWidget);
  final itineraryViewerDate =
      (find.byType(ItineraryViewer).evaluate().single.widget as ItineraryViewer)
          .itineraryDay;
  expect(itineraryViewerDate.isOnSameDayAs(itineraryDate), true,
      reason: 'ItineraryViewer should display first trip date');
  print(
      '✓ Itinerary viewer displayed for trip date - ${itineraryDate.dateMonthFormat}');

  // === FIND AND VERIFY ALL TIMELINE ITEM WIDGETS ===
  // Scroll through the timeline to find all TimelineItemWidget instances
  final scrollableFinder = find.descendant(
    of: find.byType(ItineraryViewer),
    matching: find.byType(SingleChildScrollView),
  );
  expect(scrollableFinder, findsOneWidget);

  final timelineItemWidgets = <TimelineItemWidget>[];

  // Find all TimelineItemWidget by scrolling
  await tester.pumpAndSettle();

  // Get all visible timeline items
  var timelineItemFinders = find.byType(TimelineItemWidget);
  while (timelineItemFinders.evaluate().isNotEmpty) {
    // Extract events from visible widgets
    for (final element in timelineItemFinders.evaluate()) {
      final widget = element.widget as TimelineItemWidget;
      if (!timelineItemWidgets.any((e) =>
          e.event.time == widget.event.time &&
          e.event.title == widget.event.title)) {
        timelineItemWidgets.add(widget);
      }
    }

    // Try to scroll down to reveal more items
    await tester.drag(scrollableFinder, const Offset(0, -300));
    await tester.pumpAndSettle();

    // Check if we found new items
    final newItemCount = find.byType(TimelineItemWidget).evaluate().length;
    if (newItemCount == 0 ||
        timelineItemWidgets.length >= expectedEvents.length) {
      break;
    }
  }

  print(
      '✓ Found ${timelineItemWidgets.length} actual TimelineItemWidget instances (with scrolling)');

  // === VERIFY COUNT MATCHES ===
  expect(timelineItemWidgets.length, expectedEvents.length,
      reason: 'Number of actual timeline events should match expected events');

  // === VERIFY EACH EVENT MATCHES ===
  for (int i = 0; i < expectedEvents.length; i++) {
    final expectedEvent = expectedEvents.elementAt(i);
    final timelineItemWidget = timelineItemWidgets[i];

    var timelineItemWidgetFinder = find.byWidget(timelineItemWidget);
    final titleWidget = find.descendant(
        of: timelineItemWidgetFinder, matching: find.text(expectedEvent.title));
    expect(titleWidget, findsOneWidget,
        reason: 'Event #${i + 1} title should be ${expectedEvent.title}');

    final subtitleWidget = find.descendant(
        of: timelineItemWidgetFinder,
        matching: find.text(expectedEvent.subtitle));
    expect(subtitleWidget, findsOneWidget,
        reason: 'Event #${i + 1} subtitle should be ${expectedEvent.subtitle}');

    if (expectedEvent.notes != null) {
      final notesWidget = find.descendant(
          of: timelineItemWidgetFinder,
          matching: find.text(expectedEvent.notes!));
      expect(notesWidget, findsOneWidget,
          reason: 'Event #${i + 1} notes should be ${expectedEvent.notes}');
    }

    if (expectedEvent.confirmationId != null) {
      final confirmationWidget = find.descendant(
          of: timelineItemWidgetFinder,
          matching: find.text(expectedEvent.confirmationId!));
      expect(confirmationWidget, findsOneWidget,
          reason:
              'Event #${i + 1} confirmation ID should be ${expectedEvent.confirmationId}');
    }
  }

  print('\n✓ All timeline events verified and in correct chronological order');
}

Future<void> _verifyItineraryPlanData(
    WidgetTester tester, _ExpectedItineraryData expectedItineraryData) async {
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

class _ExpectedTimelineEvent {
  final String title;
  final String subtitle;
  final String? notes;
  final String? confirmationId;
  final IconData icon;

  _ExpectedTimelineEvent({
    required this.title,
    required this.subtitle,
    this.notes,
    this.confirmationId,
    required this.icon,
  });
}

class _ExpectedItineraryData {
  final Iterable<_ExpectedSightData> sights;
  final Iterable<String> notes;
  final Iterable<_ExpectedChecklistData> checklists;

  _ExpectedItineraryData({
    required this.sights,
    required this.notes,
    required this.checklists,
  });
}

class _ExpectedChecklistData {
  final String title;
  final double progressIndicator;
  final String progressText;

  _ExpectedChecklistData({
    required this.title,
    required this.progressIndicator,
    required this.progressText,
  });
}

class _ExpectedSightData {
  final String name;
  final String? location;
  final String expense;
  final String time;

  _ExpectedSightData({
    required this.name,
    this.location,
    required this.expense,
    required this.time,
  });
}

void _matchDate(DateTime actualDateTime, DateTime expectedDateTime,
    {String? reason}) {
  expect(
      actualDateTime,
      predicate<DateTime>((DateTime date) {
        return date.isOnSameDayAs(expectedDateTime);
      }, reason ?? 'Date should be ${expectedDateTime.dayDateMonthFormat}'));
}
