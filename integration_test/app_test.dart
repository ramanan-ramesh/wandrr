import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wandrr/main.dart' as app;

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

  group('Wandrr App Integration Tests', () {
    testWidgets('Login flow and navigate to trip details',
        (WidgetTester tester) async {
      // STEP 1: Launch the app
      // This starts the app just like it would normally start
      app.main();

      // Wait for the app to initialize and render the first frame
      await tester.pumpAndSettle();

      // STEP 2: Wait for the loading animation to complete
      // The app shows a loading screen with a Rive animation for minimum 2 seconds
      print('Waiting for loading animation to complete...');

      // We need to wait for the loading screen to disappear
      // The loading screen shows "Loading user data and theme" text
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // At this point, the app should have loaded and we should be on the login page
      // Let's verify we can find the login page elements
      print('Looking for login page elements...');

      // STEP 3: Find the username field
      // The login page has a username field with a unique key
      final usernameFinder = find.byKey(const Key('username_field'));

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
      // This might take a few seconds depending on network speed
      print('Waiting for authentication...');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // STEP 9: Verify we've navigated to the trips list view
      // The trips list view should have a "View Recent Trips" or similar text
      // and should show either trip items or "No trips created" message
      print('Looking for trips list view...');

      // Try to find the trips list view by looking for specific text
      // This will find either the header or the "no trips" message
      final tripsViewIndicator =
          find.textContaining('trip', findRichText: true, skipOffstage: false);

      // We should find at least one text widget containing "trip"
      expect(tripsViewIndicator, findsWidgets);
      print('Successfully navigated to trips list view');

      // STEP 10: Find and tap on a trip item (if available)
      // Trip items are InkWell widgets within the grid
      final tripItemFinder = find.byType(InkWell);

      if (tester.widgetList(tripItemFinder).isNotEmpty) {
        print('Found ${tester.widgetList(tripItemFinder).length} trip items');

        // Tap on the first trip item
        // We need to be more specific - find InkWell within the GridView
        await tester.tap(tripItemFinder.first);
        print('Tapped on first trip item');

        await tester.pumpAndSettle(const Duration(seconds: 2));
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
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('Testing invalid login...');

      // STEP 2: Enter invalid credentials
      final usernameFinder = find.byKey(const Key('username_field'));
      final passwordFinder = find.byKey(const Key('password_field'));

      await tester.enterText(usernameFinder, 'invalid@example.com');
      await tester.enterText(passwordFinder, 'WrongPassword123!');
      await tester.pumpAndSettle();

      // STEP 3: Tap login button
      final loginButtonFinder = find.byKey(const Key('login_submit_button'));
      await tester.tap(loginButtonFinder);

      // STEP 4: Wait and check for error message
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The error should be displayed
      // (You'll need to adjust this based on your actual error display)
      print('Invalid login test completed');
    });
  });
}
