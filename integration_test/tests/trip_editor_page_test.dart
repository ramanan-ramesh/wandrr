import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/budgeting_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_navigator.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/bottom_nav_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../helpers/test_helpers.dart';

/// Test: TripEditorPage displays ItineraryViewer and BudgetingPage side by side
/// when isBigLayout is true
Future<void> runTripEditorLargeLayoutTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  final isLarge = TestHelpers.isLargeScreen(tester);

  // Navigate to trip editor
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 5),
  );

  // Verify TripEditorPage is displayed
  expect(find.byType(TripEditorPage), findsOneWidget);

  if (isLarge) {
    // Verify both ItineraryNavigator and BudgetingPage are displayed
    expect(find.byType(ItineraryNavigator), findsOneWidget);
    expect(find.byType(BudgetingPage), findsOneWidget);

    // Verify they are in a Row layout (side by side)
    final row = find.ancestor(
      of: find.byType(ItineraryNavigator),
      matching: find.byType(Row),
    );
    expect(row, findsOneWidget);

    // Verify no BottomNavigationBar is displayed
    expect(find.byType(BottomNavBar), findsNothing);
  } else {
    print('Skipping large layout test - device has small screen');
  }
}

/// Test: FloatingActionButton is present at center bottom with padding
/// when isBigLayout is true
Future<void> runTripEditorLargeLayoutFABTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  final isLarge = TestHelpers.isLargeScreen(tester);

  // Navigate to trip editor
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 5),
  );

  // Verify TripEditorPage is displayed
  expect(find.byType(TripEditorPage), findsOneWidget);

  // Verify FloatingActionButton is displayed
  final fab = find.byType(FloatingActionButton);
  expect(fab, findsOneWidget);

  if (isLarge) {
    // Verify FAB has padding (wrapped in Padding widget)
    final paddedFab = find.ancestor(
      of: find.byType(FloatingActionButton),
      matching: find.byType(Padding),
    );
    expect(paddedFab, findsOneWidget);

    // Get FAB position to verify it's at center bottom
    final fabPosition = TestHelpers.getWidgetPosition(tester, fab);
    final screenSize = TestHelpers.getScreenSize(tester);

    // Verify FAB is roughly centered horizontally
    expect(
      fabPosition.dx,
      greaterThan(screenSize.width * 0.4),
      reason: 'FAB should be horizontally centered',
    );
    expect(
      fabPosition.dx,
      lessThan(screenSize.width * 0.6),
      reason: 'FAB should be horizontally centered',
    );
  } else {
    print('Skipping large layout FAB test - device has small screen');
  }
}

/// Test: ItineraryViewer is displayed by default when isBigLayout is false
Future<void> runTripEditorSmallLayoutDefaultTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  final isSmall = !TestHelpers.isLargeScreen(tester);

  // Navigate to trip editor
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 5),
  );

  // Verify TripEditorPage is displayed
  expect(find.byType(TripEditorPage), findsOneWidget);

  if (isSmall) {
    // Verify ItineraryNavigator is displayed
    expect(find.byType(ItineraryNavigator), findsOneWidget);

    // Note: BudgetingPage exists in the widget tree but is not the current page
  } else {
    print('Skipping small layout test - device has large screen');
  }
}

/// Test: BottomNavigationBar is displayed when isBigLayout is false
Future<void> runTripEditorSmallLayoutBottomNavTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  final isSmall = !TestHelpers.isLargeScreen(tester);

  // Navigate to trip editor
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 5),
  );

  // Verify TripEditorPage is displayed
  expect(find.byType(TripEditorPage), findsOneWidget);

  if (isSmall) {
    // Verify BottomNavigationBar is displayed
    expect(find.byType(BottomNavBar), findsOneWidget);
  } else {
    print('Skipping small layout test - device has large screen');
  }
}

/// Test: Switch between ItineraryViewer and BudgetingPage using BottomNavigationBar
Future<void> runTripEditorSmallLayoutNavigationTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  final isSmall = !TestHelpers.isLargeScreen(tester);

  // Navigate to trip editor
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 5),
  );

  // Verify TripEditorPage is displayed
  expect(find.byType(TripEditorPage), findsOneWidget);

  if (isSmall) {
    // Verify ItineraryNavigator is initially displayed
    expect(find.byType(ItineraryNavigator), findsOneWidget);

    // Find BottomNavigationBar
    final bottomNavBar = find.byType(BottomNavBar);
    expect(bottomNavBar, findsOneWidget);

    // Find icon for budgeting (adjust icon based on your implementation)
    final budgetIcon = find.descendant(
      of: bottomNavBar,
      matching: find.byIcon(Icons.account_balance_wallet_rounded),
    );

    if (budgetIcon.evaluate().isNotEmpty) {
      await TestHelpers.tapWidget(tester, budgetIcon);

      // Verify BudgetingPage is now displayed
      expect(find.byType(BudgetingPage), findsOneWidget);
    }
  } else {
    print('Skipping small layout navigation test - device has large screen');
  }
}

/// Test: FloatingActionButton is docked in center of BottomNavBar
Future<void> runTripEditorSmallLayoutFABTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  final isSmall = !TestHelpers.isLargeScreen(tester);

  // Navigate to trip editor
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 5),
  );

  // Verify TripEditorPage is displayed
  expect(find.byType(TripEditorPage), findsOneWidget);

  // Verify FloatingActionButton is displayed
  final fab = find.byType(FloatingActionButton);
  expect(fab, findsOneWidget);

  if (isSmall) {
    // Verify BottomNavigationBar is displayed
    final bottomNavBar = find.byType(BottomNavBar);
    expect(bottomNavBar, findsOneWidget);

    // Get positions to verify FAB is docked with bottom nav bar
    final fabPosition = TestHelpers.getWidgetPosition(tester, fab);
    final bottomNavPosition =
        TestHelpers.getWidgetPosition(tester, bottomNavBar);

    // Verify FAB is at bottom (near bottom nav bar)
    expect(
      fabPosition.dy,
      greaterThan(bottomNavPosition.dy - 50),
      reason: 'FAB should be docked near bottom navigation bar',
    );

    // Verify FAB is horizontally centered
    final screenSize = TestHelpers.getScreenSize(tester);
    expect(
      fabPosition.dx,
      greaterThan(screenSize.width * 0.4),
      reason: 'FAB should be horizontally centered',
    );
    expect(
      fabPosition.dx,
      lessThan(screenSize.width * 0.6),
      reason: 'FAB should be horizontally centered',
    );
  } else {
    print('Skipping small layout FAB test - device has large screen');
  }
}
