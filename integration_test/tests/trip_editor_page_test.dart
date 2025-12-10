import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/trip/pages/home/trips_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/budgeting_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_navigator.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/bottom_nav_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../helpers/test_helpers.dart';

/// Single comprehensive test for TripEditorPage layout characteristics
/// Tests both big layout and small layout based on context.isBigLayout
/// Also verifies isBigLayout setting based on screen width (>= 1000px)
Future<void> runTripEditorLayoutTest(
  WidgetTester tester,
) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Wait for TripsListView to be displayed
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripListView),
    timeout: const Duration(seconds: 5),
  );

  // Find the test trip grid item by its name "European Adventure"
  final testTripItem = find.ancestor(
    of: find.text('European Adventure'),
    matching: find.byType(InkWell),
  );

  // Verify the test trip item is found
  expect(testTripItem, findsOneWidget,
      reason:
          'Test trip "European Adventure" should be displayed in TripsListView');

  // Click on the test trip item to navigate to TripEditorPage
  await TestHelpers.tapWidget(tester, testTripItem);

  // Wait for navigation animation and TripEditorPage to appear
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10), // Allow extra time for Rive animation
  );

  // Verify TripEditorPage is displayed
  expect(find.byType(TripEditorPage), findsOneWidget);

  // Get screen size and verify isBigLayout setting
  final screenSize = TestHelpers.getScreenSize(tester);
  final expectedIsBigLayout =
      screenSize.width >= 1000.0; // TripProviderPageConstants.cutOffPageWidth

  // Get the BuildContext from the element
  final tripEditorFinder = find.byType(TripEditorPage);
  final BuildContext tripEditorContext = tester.element(tripEditorFinder);

  // Verify isBigLayout is set correctly based on screen width
  expect(tripEditorContext.isBigLayout, expectedIsBigLayout,
      reason:
          'isBigLayout should be $expectedIsBigLayout when screen width is >= 1000');

  if (tripEditorContext.isBigLayout) {
    // === BIG LAYOUT TESTS ===
    print(
        'Testing big layout characteristics (screen width: ${screenSize.width})');

    // Verify both ItineraryNavigator and BudgetingPage are displayed side by side
    expect(find.byType(ItineraryNavigator), findsOneWidget);
    expect(find.byType(BudgetingPage), findsOneWidget);

    // Verify they are in a Row layout (side by side)
    final itineraryRow = find.ancestor(
      of: find.byType(ItineraryNavigator),
      matching: find.byType(Row),
    );
    expect(itineraryRow, findsOneWidget,
        reason: 'ItineraryNavigator should be in a Row for big layout');

    final budgetingRow = find.ancestor(
      of: find.byType(BudgetingPage),
      matching: find.byType(Row),
    );
    expect(budgetingRow, findsOneWidget,
        reason: 'BudgetingPage should be in a Row for big layout');

    // Verify both widgets share the same Row ancestor
    final itineraryRowWidget = tester.widget<Row>(itineraryRow);
    final budgetingRowWidget = tester.widget<Row>(budgetingRow);
    expect(itineraryRowWidget, same(budgetingRowWidget),
        reason:
            'Both ItineraryNavigator and BudgetingPage should share the same Row ancestor for side-by-side layout');

    // Verify no BottomNavigationBar is displayed
    expect(find.byType(BottomNavBar), findsNothing,
        reason: 'BottomNavBar should not be displayed in big layout');

    // === FAB TESTS FOR BIG LAYOUT ===
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget,
        reason: 'FAB should be displayed in big layout');

    // Verify Scaffold has centerDocked FAB location
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.floatingActionButtonLocation,
        FloatingActionButtonLocation.centerDocked,
        reason: 'Scaffold should have centerDocked FAB location in big layout');
  } else {
    // === SMALL LAYOUT TESTS ===
    print(
        'Testing small layout characteristics (screen width: ${screenSize.width})');

    // Verify ItineraryNavigator is displayed by default
    expect(find.byType(ItineraryNavigator), findsOneWidget,
        reason:
            'ItineraryNavigator should be displayed by default in small layout');

    // Verify BudgetingPage is NOT displayed by default
    expect(find.byType(BudgetingPage), findsNothing,
        reason:
            'BudgetingPage should not be displayed by default in small layout');

    // Verify BottomNavigationBar is displayed
    expect(find.byType(BottomNavBar), findsOneWidget,
        reason: 'BottomNavBar should be displayed in small layout');

    // === NAVIGATION TESTS ===
    // Find BottomNavigationBar
    final bottomNavBar = find.byType(BottomNavBar);
    expect(bottomNavBar, findsOneWidget);

    // Find icon for budgeting (adjust icon based on your implementation)
    final budgetIcon = find.descendant(
      of: bottomNavBar,
      matching: find.byIcon(Icons.wallet_travel_rounded),
    );

    await TestHelpers.tapWidget(tester, budgetIcon);

    // Verify BudgetingPage is now displayed after navigation
    expect(find.byType(BudgetingPage), findsOneWidget,
        reason:
            'BudgetingPage should be displayed after navigation in small layout');

    // Verify ItineraryNavigator is NOT displayed after navigation to budgeting
    expect(find.byType(ItineraryNavigator), findsNothing,
        reason:
            'ItineraryNavigator should not be displayed when BudgetingPage is active in small layout');

    // === NAVIGATION BACK TESTS ===
    // Find icon for itinerary (adjust icon based on your implementation)
    final itineraryIcon = find.descendant(
      of: bottomNavBar,
      matching: find.byIcon(Icons.travel_explore_rounded),
    );

    await TestHelpers.tapWidget(tester, itineraryIcon);

    // Verify ItineraryNavigator is displayed again after navigation back
    expect(find.byType(ItineraryNavigator), findsOneWidget,
        reason:
            'ItineraryNavigator should be displayed after navigating back in small layout');

    // Verify BudgetingPage is NOT displayed after navigation back
    expect(find.byType(BudgetingPage), findsNothing,
        reason:
            'BudgetingPage should not be displayed after navigating back to itinerary in small layout');

    // === FAB TESTS FOR SMALL LAYOUT ===
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget,
        reason: 'FAB should be displayed in small layout');

    // Verify Scaffold has centerDocked FAB location
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.floatingActionButtonLocation,
        FloatingActionButtonLocation.centerDocked,
        reason:
            'Scaffold should have centerDocked FAB location in small layout');
  }

  print('✅ TripEditorPage layout test completed successfully');
}
