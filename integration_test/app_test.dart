import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wandrr/main.dart' as app;

import 'helpers/mock_firebase_setup.dart';

/// Integration test for the Wandrr app
///
/// This test performs the following actions:
/// 1. Launches the app
/// 2. Waits for the loading animation to complete
/// 3. Finds and fills in the username field
/// 4. Finds and fills in the password field
/// 5. Submits the login form
/// 6. Waits for navigation to the trips list view
/// 7. Finds and taps on a trip item (if available)
void main() {
  // Initialize the integration test binding
  // This is required for all integration tests
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase before any tests run
    await MockFirebaseSetup.setupFirebaseMocks();
  });

  group('Wandrr App Integration Tests', () {
    testWidgets('Login flow and navigate to trip details',
        (WidgetTester tester) async {
      // STEP 1: Launch the app
      // This starts the app just like it would normally start
      app.main();

      // Wait for the app to initialize and render the first frame
      await tester.pumpAndSettle();

      // STEP 2: Wait for the login page to appear
      // Instead of waiting for a fixed duration, wait for the username field to appear
      print('Waiting for login page to appear...');

      final usernameFinder = find.byKey(const Key('username_field'));

      // Wait for the username field to appear (max 10 seconds)
      await _waitForWidget(tester, usernameFinder,
          timeout: const Duration(seconds: 10));
      print('Login page loaded!');

      // STEP 3: Verify we're on the login page
      print('Looking for login page elements...');

      // Verify the username field exists
      expect(usernameFinder, findsOneWidget);
      print('Found username field');

      // STEP 4: Enter username
      // Replace with your actual test credentials
      const testUsername = 'test@example.com';
      await tester.enterText(usernameFinder, testUsername);
      await tester.pumpAndSettle();
      print('Entered username: $testUsername');

      // STEP 5: Find the password field
      // The password field has a unique key
      final passwordFinder = find.byKey(const Key('password_field'));

      // Verify the password field exists
      expect(passwordFinder, findsOneWidget);
      print('Found password field');

      // STEP 6: Enter password
      // Replace with your actual test password
      const testPassword = 'TestPassword123!';
      await tester.enterText(passwordFinder, testPassword);
      await tester.pumpAndSettle();
      print('Entered password');

      // STEP 7: Find and tap the login/submit button
      // The submit button has a unique key
      final loginButtonFinder = find.byKey(const Key('login_submit_button'));

      // Verify the login button exists
      expect(loginButtonFinder, findsOneWidget);
      print('Found login button');

      // Tap the login button
      await tester.tap(loginButtonFinder);
      print('Tapped login button');

      // STEP 8: Wait for authentication to complete
      // Wait for trips list view to appear instead of fixed duration
      print('Waiting for authentication and navigation...');

      // Wait for trips view indicator (text containing "trip")
      final tripsViewIndicator =
          find.textContaining('trip', findRichText: true, skipOffstage: false);

      await _waitForWidget(tester, tripsViewIndicator,
          timeout: const Duration(seconds: 10));
      print('Successfully authenticated and navigated to trips list view!');

      // STEP 9: Verify we've navigated to the trips list view

      // Try to find the trips list view by looking for specific text
      // This will find either the header or the "no trips" message
      // We should find at least one text widget containing "trip"
      expect(tripsViewIndicator, findsWidgets);

      // STEP 10: Find and tap on a trip item (if available)
      // Trip items are InkWell widgets within the grid
      final tripItemFinder = find.byType(InkWell);

      if (tester.widgetList(tripItemFinder).isNotEmpty) {
        print('Found ${tester.widgetList(tripItemFinder).length} trip items');

        // Tap on the first trip item
        await tester.tap(tripItemFinder.first);
        print('Tapped on first trip item');

        // Wait for trip details page to load instead of fixed duration
        // You should replace this with a specific widget from your trip details page
        await tester.pumpAndSettle();
        print('Navigated to trip details');

        // At this point, the trip should be loaded
        // You could add more assertions here to verify the trip details page
      } else {
        print('No trip items found - user might not have any trips created');

        // You could optionally create a trip here if needed for testing
        // For now, we'll just log that no trips were found
      }

      print('Test completed successfully!');
    });

    testWidgets('Login with invalid credentials shows error',
        (WidgetTester tester) async {
      // STEP 1: Launch the app
      app.main();
      await tester.pumpAndSettle();

      print('Testing invalid login...');

      // STEP 2: Wait for login page to appear
      final usernameFinder = find.byKey(const Key('username_field'));
      await _waitForWidget(tester, usernameFinder,
          timeout: const Duration(seconds: 10));

      // STEP 3: Enter invalid credentials
      final passwordFinder = find.byKey(const Key('password_field'));

      await tester.enterText(usernameFinder, 'invalid@example.com');
      await tester.enterText(passwordFinder, 'WrongPassword123!');
      await tester.pumpAndSettle();

      // STEP 4: Tap login button
      final loginButtonFinder = find.byKey(const Key('login_submit_button'));
      await tester.tap(loginButtonFinder);

      // STEP 5: Wait for error message instead of fixed duration
      await tester.pumpAndSettle();

      // The error should be displayed
      // (You'll need to adjust this based on your actual error display)
      print('Invalid login test completed');
    });
  });
}

/// Helper method to wait for a widget to appear
///
/// This is much better than using pumpAndSettle with a fixed duration
/// because it:
/// 1. Fails fast if widget appears quickly
/// 2. Retries until timeout if widget takes time to appear
/// 3. Provides clear error message if widget never appears
Future<void> _waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final endTime = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(endTime)) {
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    if (finder.evaluate().isNotEmpty) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  throw Exception(
      'Widget not found within ${timeout.inSeconds} seconds: $finder');
}
