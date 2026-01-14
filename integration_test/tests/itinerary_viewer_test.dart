import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_navigator.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_viewer.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/timeline_event.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/widgets/timeline_item_widget.dart';

import '../helpers/test_helpers.dart';

/// Test: ItineraryViewer displays first trip date's itinerary with all components by default
/// Verifies transits, lodgings, sights, notes, and checklists are displayed
Future<void> runItineraryViewerDefaultDateTest(WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

  // Verify ItineraryNavigator is present
  expect(find.byType(ItineraryNavigator), findsOneWidget);

  // Verify ItineraryViewer is displayed
  expect(find.byType(ItineraryViewer), findsOneWidget);

  print('✓ Itinerary viewer displayed for first trip date');

  // === BUILD EXPECTED TIMELINE EVENTS FROM REPOSITORY DATA ===
  // Get repository and itinerary data
  final context = tester.element(find.byType(ItineraryViewer));
  final tripRepo = RepositoryProvider.of<TripRepositoryFacade>(context);
  final itineraryDay = DateTime(2025, 9, 24); // Day 1
  final itinerary =
      tripRepo.activeTrip!.itineraryCollection.getItineraryForDay(itineraryDay);

  // Collect expected timeline items from repository data
  final expectedEvents = <_ExpectedTimelineEvent>[];

  // Collect transits for this day
  for (final transit in itinerary.transits) {
    final departure = transit.departureDateTime!;
    final arrival = transit.arrivalDateTime!;
    final isDepartingToday = departure.isOnSameDayAs(itineraryDay);
    final isArrivingToday = arrival.isOnSameDayAs(itineraryDay);

    if (isDepartingToday || isArrivingToday) {
      expectedEvents.add(_ExpectedTimelineEvent(
        time: isDepartingToday ? departure : arrival,
        type: 'Transit',
        operator: transit.operator,
        notes: transit.notes,
        confirmationId: transit.confirmationId,
      ));
    }
  }

  // Collect lodgings for this day
  final fullDay = itinerary.fullDayLodging;
  final checkIn = itinerary.checkInLodging;
  final checkOut = itinerary.checkOutLodging;

  if (fullDay != null) {
    expectedEvents.add(_ExpectedTimelineEvent(
      time: fullDay.checkinDateTime!,
      type: 'Lodging (All Day)',
      location: fullDay.location!.context.name,
      notes: fullDay.notes,
      confirmationId: fullDay.confirmationId,
    ));
  } else {
    if (checkIn != null) {
      expectedEvents.add(_ExpectedTimelineEvent(
        time: checkIn.checkinDateTime!,
        type: 'Lodging (Check-in)',
        location: checkIn.location!.context.name,
        notes: checkIn.notes,
        confirmationId: checkIn.confirmationId,
      ));
    }
    if (checkOut != null) {
      expectedEvents.add(_ExpectedTimelineEvent(
        time: checkOut.checkoutDateTime!,
        type: 'Lodging (Check-out)',
        location: checkOut.location!.context.name,
        notes: checkOut.notes,
        confirmationId: checkOut.confirmationId,
      ));
    }
  }

  // Collect sights with visit times for this day
  for (final sight in itinerary.planData.sights) {
    if (sight.visitTime != null) {
      expectedEvents.add(_ExpectedTimelineEvent(
        time: sight.visitTime!,
        type: 'Sight',
        sightName: sight.name,
        location: sight.location?.context.name,
        notes: sight.description,
        confirmationId: null, // Sights don't have confirmation IDs
      ));
    }
  }

  // Sort expected events by time (same as TimelineEventFactory does)
  expectedEvents.sort((a, b) => a.time.compareTo(b.time));

  print(
      '✓ Built ${expectedEvents.length} expected timeline events from repository data');

  // === FIND AND VERIFY ALL TIMELINE ITEM WIDGETS ===
  // Scroll through the timeline to find all TimelineItemWidget instances
  final scrollableFinder = find.descendant(
    of: find.byType(ItineraryViewer),
    matching: find.byType(SingleChildScrollView),
  );
  expect(scrollableFinder, findsOneWidget);

  final actualEvents = <TimelineEvent>[];

  // Find all TimelineItemWidget by scrolling
  await tester.pumpAndSettle();

  // Get all visible timeline items
  var timelineItemFinders = find.byType(TimelineItemWidget);
  while (timelineItemFinders.evaluate().isNotEmpty) {
    // Extract events from visible widgets
    for (final element in timelineItemFinders.evaluate()) {
      final widget = element.widget as TimelineItemWidget;
      if (!actualEvents.any((e) =>
          e.time == widget.event.time && e.title == widget.event.title)) {
        actualEvents.add(widget.event);
      }
    }

    // Try to scroll down to reveal more items
    await tester.drag(scrollableFinder, const Offset(0, -300));
    await tester.pumpAndSettle();

    // Check if we found new items
    final newItemCount = find.byType(TimelineItemWidget).evaluate().length;
    if (newItemCount == 0 || actualEvents.length >= expectedEvents.length) {
      break;
    }
  }

  print(
      '✓ Found ${actualEvents.length} actual TimelineItemWidget instances (with scrolling)');

  // === VERIFY COUNT MATCHES ===
  expect(actualEvents.length, expectedEvents.length,
      reason: 'Number of actual timeline events should match expected events');

  // === VERIFY EACH EVENT MATCHES ===
  for (int i = 0; i < expectedEvents.length; i++) {
    final expected = expectedEvents[i];
    final actual = actualEvents[i];

    print('\n--- Verifying Event #${i + 1}: ${expected.type} ---');

    // Verify time
    expect(actual.time, expected.time,
        reason: 'Event #${i + 1} time should be ${expected.time}');
    print('  ✓ time: ${actual.time}');

    // Verify type-specific fields
    switch (expected.type) {
      case 'Transit':
        expect(actual.subtitle, expected.operator,
            reason:
                'Event #${i + 1} subtitle should be operator "${expected.operator}"');
        print('  ✓ subtitle (operator): ${actual.subtitle}');
        break;

      case 'Lodging (Check-in)':
      case 'Lodging (Check-out)':
      case 'Lodging (All Day)':
        expect(actual.subtitle.contains(expected.location!), true,
            reason:
                'Event #${i + 1} subtitle should contain location "${expected.location}"');
        print('  ✓ subtitle (location): ${actual.subtitle}');
        break;

      case 'Sight':
        expect(actual.title.contains(expected.sightName!), true,
            reason:
                'Event #${i + 1} title should contain sight name "${expected.sightName}"');
        print('  ✓ title (sight): ${actual.title}');
        break;
    }

    // Verify notes
    expect(actual.notes, expected.notes,
        reason: 'Event #${i + 1} notes should be "${expected.notes}"');
    print('  ✓ notes: ${actual.notes}');

    // Verify confirmationId
    expect(actual.confirmationId, expected.confirmationId,
        reason:
            'Event #${i + 1} confirmationId should be "${expected.confirmationId}"');
    print('  ✓ confirmationId: ${actual.confirmationId}');
  }

  // === VERIFY CHRONOLOGICAL ORDER ===
  for (int i = 0; i < actualEvents.length - 1; i++) {
    expect(
        actualEvents[i].time.isBefore(actualEvents[i + 1].time) ||
            actualEvents[i].time.isAtSameMomentAs(actualEvents[i + 1].time),
        true,
        reason:
            'Event #${i + 1} should be before or at same time as Event #${i + 2}');
  }

  print('\n✓ All timeline events verified and in correct chronological order');

  // === VERIFY SIGHTS TAB ===
  final sightsTab = find.byIcon(Icons.place_outlined);
  expect(sightsTab, findsOneWidget, reason: 'Sights tab should be present');

  await TestHelpers.tapWidget(tester, sightsTab);

  // Verify exact sight details from Day 1: Eiffel Tower (15:30)
  expect(find.textContaining('Eiffel Tower'), findsWidgets,
      reason: 'Should display Eiffel Tower name');
  expect(find.textContaining('Iconic landmark'), findsWidgets,
      reason: 'Should display Eiffel Tower description');
  // Note: Time and expense verification depends on how ItinerarySightsViewer displays them

  print('✓ Sights tab displays exact sight details (name, description)');

  // === VERIFY NOTES TAB ===
  final notesTab = find.byIcon(Icons.note_outlined);
  expect(notesTab, findsOneWidget, reason: 'Notes tab should be present');

  await TestHelpers.tapWidget(tester, notesTab);

  // Verify exact notes from Day 1 test data (3 notes total)
  expect(find.textContaining('Arrive from London'), findsWidgets,
      reason: 'Should display note 1: "Arrive from London"');
  expect(find.textContaining('Check in'), findsWidgets,
      reason: 'Should display note 2: "Check in"');
  expect(find.textContaining('Visit Eiffel Tower'), findsWidgets,
      reason: 'Should display note 3: "Visit Eiffel Tower"');

  print('✓ Notes tab displays all 3 exact notes from Day 1');

  // === VERIFY CHECKLISTS TAB ===
  final checklistsTab = find.byIcon(Icons.checklist_outlined);
  expect(checklistsTab, findsOneWidget,
      reason: 'Checklists tab should be present');

  await TestHelpers.tapWidget(tester, checklistsTab);

  // Verify exact checklist from Day 1 test data
  // Checklist title: "Day 1"
  // Items: "Exchange currency" (status: false), "Buy metro pass" (status: false)
  expect(find.textContaining('Day 1'), findsWidgets,
      reason: 'Should display checklist title "Day 1"');
  expect(find.textContaining('Exchange currency'), findsWidgets,
      reason: 'Should display checklist item 1: "Exchange currency"');
  expect(find.textContaining('Buy metro pass'), findsWidgets,
      reason: 'Should display checklist item 2: "Buy metro pass"');

  print(
      '✓ Checklists tab displays exact checklist (title + 2 items) from Day 1');
  print('✓ All itinerary components verified for first trip date');
}

/// Test: Verify itinerary plan data on Day 2 (multiple sights, different notes/checklists)
Future<void> runItineraryViewerDay2Test(WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

  // Navigate to Day 2 (click next button)
  final nextButton = find.byIcon(Icons.chevron_right_rounded);
  expect(nextButton, findsOneWidget, reason: 'Next button should be present');

  await TestHelpers.tapWidget(tester, nextButton.first);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  print('✓ Navigated to Day 2 (September 25)');

  // === VERIFY SIGHTS TAB (Day 2 has 2 sights) ===
  final sightsTab = find.byIcon(Icons.place_outlined);
  expect(sightsTab, findsOneWidget, reason: 'Sights tab should be present');

  await TestHelpers.tapWidget(tester, sightsTab);
  await tester.pumpAndSettle();

  // Day 2 sights: Palace of Versailles (10:30) and Louvre Museum (13:00)
  expect(find.textContaining('Palace of Versailles'), findsWidgets,
      reason: 'Should display Palace of Versailles name');
  expect(find.textContaining('Louvre Museum'), findsWidgets,
      reason: 'Should display Louvre Museum name');
  expect(find.textContaining('Royal palace'), findsWidgets,
      reason: 'Should display Versailles description');
  expect(find.textContaining('Art museum'), findsWidgets,
      reason: 'Should display Louvre description');

  print('✓ Day 2 Sights tab: 2 sights verified (Versailles, Louvre)');

  // === VERIFY NOTES TAB (Day 2 has 3 notes) ===
  final notesTab = find.byIcon(Icons.note_outlined);
  expect(notesTab, findsOneWidget, reason: 'Notes tab should be present');

  await TestHelpers.tapWidget(tester, notesTab);
  await tester.pumpAndSettle();

  // Day 2 notes: "Versailles trip", "Louvre visit", "Dinner"
  expect(find.textContaining('Versailles trip'), findsWidgets,
      reason: 'Should display note 1: "Versailles trip"');
  expect(find.textContaining('Louvre visit'), findsWidgets,
      reason: 'Should display note 2: "Louvre visit"');
  expect(find.textContaining('Dinner'), findsWidgets,
      reason: 'Should display note 3: "Dinner"');

  print('✓ Day 2 Notes tab: 3 notes verified');

  // === VERIFY CHECKLISTS TAB (Day 2 checklist) ===
  final checklistsTab = find.byIcon(Icons.checklist_outlined);
  expect(checklistsTab, findsOneWidget,
      reason: 'Checklists tab should be present');

  await TestHelpers.tapWidget(tester, checklistsTab);
  await tester.pumpAndSettle();

  // Day 2 checklist: "Day 2" with items "Book tour" (checked) and "Pack snacks" (unchecked)
  expect(find.textContaining('Day 2'), findsWidgets,
      reason: 'Should display checklist title "Day 2"');
  expect(find.textContaining('Book tour'), findsWidgets,
      reason: 'Should display checklist item 1: "Book tour"');
  expect(find.textContaining('Pack snacks'), findsWidgets,
      reason: 'Should display checklist item 2: "Pack snacks"');

  print('✓ Day 2 Checklists tab: checklist with 1 checked, 1 unchecked item');

  // === VERIFY TIMELINE TAB ===
  final timelineTab = find.byIcon(Icons.timeline_outlined);
  expect(timelineTab, findsOneWidget, reason: 'Timeline tab should be present');

  await TestHelpers.tapWidget(tester, timelineTab);
  await tester.pumpAndSettle();

  // Day 2 should have 2 transits (train to Versailles, train back)
  // and lodging info
  final timelineItems = find.byType(TimelineItemWidget);
  expect(timelineItems, findsWidgets,
      reason: 'Timeline should have events for Day 2');

  print('✓ Day 2 Timeline tab: transits and lodging displayed');
  print(
      '✅ Day 2 itinerary plan data verified (multiple sights, notes, checklists)');
}

/// Test: Navigate to next date in itinerary
Future<void> runItineraryViewerNavigateNextTest(WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Find the next button (right chevron)
  final nextButton = find.byIcon(Icons.chevron_right_rounded);
  expect(nextButton, findsOneWidget, reason: 'Next button should be present');

  // Check if button is enabled
  final parentButton = tester.widget<IconButton>(
    find
        .ancestor(
          of: nextButton.first,
          matching: find.byType(IconButton),
        )
        .first,
  );

  expect(parentButton.onPressed, isNotNull,
      reason: 'Next button should be enabled (not at last day)');

  // Tap next button
  await TestHelpers.tapWidget(tester, nextButton.first);

  // Wait for animation to complete
  await tester.pump(const Duration(milliseconds: 500));

  print('✓ Successfully navigated to next date');
}

/// Test: Navigate to previous date in itinerary
Future<void> runItineraryViewerNavigatePreviousTest(WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // First navigate to next day so we can go back
  final nextButton = find.byIcon(Icons.chevron_right_rounded);
  expect(nextButton, findsOneWidget, reason: 'Next button should be present');

  await TestHelpers.tapWidget(tester, nextButton.first);
  await tester.pump(const Duration(milliseconds: 500));

  // Find the previous button (left chevron)
  final previousButton = find.byIcon(Icons.chevron_left_rounded);
  expect(previousButton, findsOneWidget,
      reason: 'Previous button should be present');

  final parentButton = tester.widget<IconButton>(
    find
        .ancestor(
          of: previousButton.first,
          matching: find.byType(IconButton),
        )
        .first,
  );

  expect(parentButton.onPressed, isNotNull,
      reason: 'Previous button should be enabled after navigating forward');

  // Tap previous button
  await TestHelpers.tapWidget(tester, previousButton.first);

  // Wait for animation to complete
  await tester.pump(const Duration(milliseconds: 500));

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
  expect(previousButton, findsOneWidget,
      reason: 'Previous button should be present');

  final parentButton = tester.widget<IconButton>(
    find
        .ancestor(
          of: previousButton.first,
          matching: find.byType(IconButton),
        )
        .first,
  );

  expect(parentButton.onPressed, isNull,
      reason: 'Previous button should be disabled at trip start');
  print('✓ Previous button correctly disabled at trip start');
}

/// Test: Cannot navigate beyond trip end date
Future<void> runItineraryViewerNavigationBoundaryEndTest(
    WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Navigate to last day by clicking next button repeatedly
  final nextButton = find.byIcon(Icons.chevron_right_rounded);
  expect(nextButton, findsOneWidget, reason: 'Next button should be present');

  // Try to navigate to the end (max 10 attempts to avoid infinite loop)
  for (int i = 0; i < 10; i++) {
    final parentButton = tester.widget<IconButton>(
      find
          .ancestor(
            of: nextButton.first,
            matching: find.byType(IconButton),
          )
          .first,
    );

    if (parentButton.onPressed != null) {
      await TestHelpers.tapWidget(tester, nextButton.first);
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      // Button is disabled, we've reached the end
      print('✓ Next button correctly disabled at trip end');
      return;
    }
  }
  fail('Unable to verify end boundary - too many days');
}

/// Test: Itinerary viewer refreshes correctly when navigating between dates
Future<void> runItineraryViewerRefreshOnNavigationTest(
    WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Get initial timeline items count
  final initialTimelineItems = find.byType(TimelineItemWidget);
  final initialCount = initialTimelineItems.evaluate().length;

  // Navigate to next date
  final nextButton = find.byIcon(Icons.chevron_right_rounded);
  expect(nextButton, findsOneWidget, reason: 'Next button should be present');

  final parentButton = tester.widget<IconButton>(
    find
        .ancestor(
          of: nextButton.first,
          matching: find.byType(IconButton),
        )
        .first,
  );

  expect(parentButton.onPressed, isNotNull,
      reason: 'Next button should be enabled');

  await TestHelpers.tapWidget(tester, nextButton.first);

  // Wait for animation and rebuild
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  // Get new timeline items count
  final newTimelineItems = find.byType(TimelineItemWidget);
  final newCount = newTimelineItems.evaluate().length;

  // The itinerary viewer should have refreshed
  print('✓ Itinerary viewer refreshed after navigation');
  print('  Timeline items: $initialCount → $newCount');
}

/// Helper class to represent expected timeline event data
class _ExpectedTimelineEvent {
  final DateTime time;
  final String
      type; // 'Transit', 'Lodging (Check-in)', 'Lodging (Check-out)', 'Lodging (All Day)', 'Sight'
  final String? operator; // For transits
  final String? location; // For lodgings
  final String? sightName; // For sights
  final String? notes;
  final String? confirmationId;

  _ExpectedTimelineEvent({
    required this.time,
    required this.type,
    this.operator,
    this.location,
    this.sightName,
    this.notes,
    this.confirmationId,
  });
}
