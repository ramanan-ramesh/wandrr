import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_navigator.dart';

import '../../helpers/firebase_emulator_helper.dart';
import '../../helpers/http_overrides/mock_location_api_service.dart';
import '../../helpers/test_config.dart';
import '../../helpers/test_helpers.dart';
import 'helpers.dart';

final expectedDayOneEvents = <ExpectedTimelineEvent>[
  ExpectedTimelineEvent(
      title: 'YXU → CDG\n08:00 AM - 11:00 AM\nEurope/London - Europe/Paris',
      subtitle: 'Air France AF 542',
      notes: 'Direct flight',
      confirmationId: 'AF123456',
      icon: Icons.flight_rounded),
  ExpectedTimelineEvent(
      title: 'Check-In • 02:00 PM',
      subtitle: 'Paris',
      notes: 'City center, 2 nights',
      confirmationId: 'PARIS-HTL-001',
      icon: Icons.login),
  ExpectedTimelineEvent(
    title: 'Eiffel Tower • 03:30 PM (Europe/Paris)',
    subtitle: 'Eiffel Tower, Paris • 26.00 EUR',
    notes: 'Iconic landmark',
    icon: Icons.place_rounded,
  ),
];
final expectedLastDayEvents = <ExpectedTimelineEvent>[
  ExpectedTimelineEvent(
    title: 'Check-Out • 11:00 AM',
    subtitle: 'Amsterdam',
    notes: 'Budget hostel',
    confirmationId: 'AMS-HSTL-123',
    icon: Icons.logout,
  ),
  ExpectedTimelineEvent(
    title: 'Keukenhof flower show • 12:00 PM (Europe/Amsterdam)',
    subtitle: 'Keukenhof flower show, Amsterdam • 40.00 EUR',
    notes: 'Flower show',
    icon: Icons.place_rounded,
  ),
  ExpectedTimelineEvent(
    title: 'AMS → YXU\n01:00 PM - 03:30 PM\nEurope/Amsterdam - Europe/London',
    subtitle: 'British Airways BA 621',
    notes: 'Direct flight',
    confirmationId: 'BA345612',
    icon: Icons.flight_rounded,
  ),
];

final expectedDayOneItineraryData = ExpectedItineraryData(
  sights: <ExpectedSightData>[
    ExpectedSightData(
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
  checklists: <ExpectedChecklistData>[
    ExpectedChecklistData(
      title: 'Day 1',
      progressIndicator: 0,
      progressText: "0/2",
    ),
  ],
);

final expectedLastDayItineraryData = ExpectedItineraryData(
  sights: [
    ExpectedSightData(
      name: 'Keukenhof flower show',
      location: 'Keukenhof',
      expense: '40 €',
      time: "12:00",
    ),
  ],
  notes: ['Breakfast', 'Visit Keukenhof', 'Return home'],
  checklists: [
    ExpectedChecklistData(
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

  await verifyTimelineEvents(
      tester, expectedDayOneEvents, DateTime(2025, 9, 24));
  await verifyItineraryPlanData(tester, expectedDayOneItineraryData);

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
  await TestHelpers.pickDate(tester, datePicker, '29',
      expectedStartDate: DateTime(2025, 9, 24),
      expectedEndDate: DateTime(2025, 9, 29));
  print('✓ Navigated to Sep 29 via date picker');

  await verifyTimelineEvents(
      tester, expectedLastDayEvents, DateTime(2025, 9, 29));
  await verifyItineraryPlanData(tester, expectedLastDayItineraryData);

  print('✓ ItineraryViewer displays itinerary for selected date');
}

/// Test: Verify itinerary plan data on Day 2 (multiple sights, different notes/checklists)
Future<void> runItineraryViewerNavigateNextTest(WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

  // Navigate to Day 6 (September 29)
  for (var i = 1; i <= 5; i++) {
    final nextButton = find.descendant(
        of: find.byType(ItineraryNavigator),
        matching: find.byIcon(Icons.chevron_right_rounded));
    await TestHelpers.tapWidget(tester, nextButton);
  }
  print('✓ Navigated to Day 6 (September 29)');

  await verifyTimelineEvents(
      tester, expectedLastDayEvents, DateTime(2025, 9, 29));

  print('✓ Day 6 Timeline tab: transits and lodging displayed');

  await verifyItineraryPlanData(tester, expectedLastDayItineraryData);

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
  print('✓ Advanced to Day 2');

  // Find the previous button (left chevron)
  final previousButton = find.byIcon(Icons.chevron_left_rounded);
  await TestHelpers.tapWidget(tester, previousButton.first);
  print('✓ Navigated back to Day 1');

  await verifyTimelineEvents(
      tester, expectedDayOneEvents, DateTime(2025, 9, 24));
  await verifyItineraryPlanData(tester, expectedDayOneItineraryData);

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

  await verifyTimelineEvents(
      tester, expectedDayOneEvents, DateTime(2025, 9, 24));
  await verifyItineraryPlanData(tester, expectedDayOneItineraryData);

  print(
      "✓ Pressing Previous button on initial layout doesn't update ItineraryViewer");
}

/// Test: Cannot navigate beyond trip end date
Future<void> runItineraryViewerNavigationBoundaryEndTest(
    WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  // Navigate to Day 6 (September 29), and press an additional time
  for (var i = 1; i <= 6; i++) {
    final nextButton = find.descendant(
        of: find.byType(ItineraryNavigator),
        matching: find.byIcon(Icons.chevron_right_rounded));
    await TestHelpers.tapWidget(tester, nextButton);
  }
  print('✓ Navigated to Day 6 (September 29)');

  await verifyTimelineEvents(
      tester, expectedLastDayEvents, DateTime(2025, 9, 29));

  print('✓ Day 6 Timeline tab: transits and lodging displayed');

  await verifyItineraryPlanData(tester, expectedLastDayItineraryData);

  print(
      "✓ Pressing Next button while on last trip date doesn't update ItineraryViewer");
}

void runTests() {
  setUpAll(() async {
    await FirebaseEmulatorHelper.createFirebaseAuthUser(
      email: TestConfig.testEmail,
      password: TestConfig.testEmail,
      shouldAddToFirestore: true,
      shouldSignIn: true,
    );
    // Initialize mock location API service to intercept HTTP requests
    // Note: This creates a MockClient that can be injected into GeoLocator
    await MockApiServices.initialize();
    await TestHelpers.createTestTrip();
  });

  tearDown(() async {
    expect(find.byType(ErrorWidget), findsNothing);
  });

  tearDownAll(() async {
    await FirebaseEmulatorHelper.cleanupAfterTest();
  });

  testWidgets(
      'displays first trip date with all components (transits, lodgings, sights, notes, checklists)',
      (WidgetTester tester) async {
    await runItineraryViewerDefaultDateTest(tester);
  });

  testWidgets('navigates to selected date', (WidgetTester tester) async {
    await runItineraryViewerNavigateToDateTest(tester);
  });

  testWidgets('navigates to next date correctly', (WidgetTester tester) async {
    await runItineraryViewerNavigateNextTest(tester);
  });

  testWidgets('navigates to previous date correctly',
      (WidgetTester tester) async {
    await runItineraryViewerNavigatePreviousTest(tester);
  });

  testWidgets('cannot navigate before trip start date',
      (WidgetTester tester) async {
    await runItineraryViewerNavigationBoundaryStartTest(tester);
  });

  testWidgets('cannot navigate beyond trip end date',
      (WidgetTester tester) async {
    await runItineraryViewerNavigationBoundaryEndTest(tester);
  });
}
