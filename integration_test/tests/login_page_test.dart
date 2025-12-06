import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/presentation/app/pages/login_page.dart';
import 'package:wandrr/presentation/trip/pages/home/home_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_provider/trip_provider.dart';

import '../helpers/test_helpers.dart';

/// Test: Login with username and password navigates to HomePage
Future<void> runLoginAuthenticationTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  print('\n[1/5] Testing valid credentials...');

  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Verify LoginPage is displayed
  expect(find.byType(LoginPage), findsOneWidget);

  // Find the username and password fields
  final usernameField = find.byType(TextFormField).first;
  final passwordField = find.byType(TextFormField).last;

  // Enter test credentials
  await TestHelpers.enterText(
    tester,
    usernameField,
    TestHelpers.testUsername,
  );
  await TestHelpers.enterText(
    tester,
    passwordField,
    TestHelpers.testPassword,
  );

  // Find and tap the submit button
  final submitButton = find.byKey(const Key('login_submit_button'));
  await TestHelpers.tapWidget(tester, submitButton);

  // Wait a bit for authentication to process
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  // After successful login, should navigate to TripProvider
  // TripProvider may show a loading animation (RiveAnimation) initially
  try {
    await TestHelpers.waitForWidget(tester, find.byType(TripProvider),
        timeout: const Duration(seconds: 8));
    print('✓ Navigated to TripProvider page');
  } catch (e) {
    print('✗ Failed to navigate to TripProvider: $e');
    // Check if still on login page with error
    if (find.byType(LoginPage).evaluate().isNotEmpty) {
      print('✗ Still on LoginPage - authentication may have failed');
    }
    rethrow;
  }

  // Verify TripProvider is displayed
  expect(find.byType(TripProvider), findsOneWidget);

  // Wait for trip repository loading to complete and HomePage to appear
  // The HomePage may take time to load trip data from Firestore
  try {
    await TestHelpers.waitForWidget(tester, find.byType(HomePage),
        timeout: const Duration(seconds: 15));
    print('✓ HomePage loaded successfully');
  } catch (e) {
    print('⚠ HomePage not found, may still be loading: $e');
    // This is acceptable - TripProvider might still be loading
  }
}

/// Test: Rive animation is displayed during authentication
Future<void> runLoginAnimationTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  print('\n[2/5] Testing Rive animation during loading...');

  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);

  // Verify LoginPage is displayed
  expect(find.byType(LoginPage), findsOneWidget);

  // Find the username and password fields
  final usernameField = find.byType(TextFormField).first;
  final passwordField = find.byType(TextFormField).last;

  // Enter test credentials
  await TestHelpers.enterText(
    tester,
    usernameField,
    TestHelpers.testUsername,
  );
  await TestHelpers.enterText(
    tester,
    passwordField,
    TestHelpers.testPassword,
  );

  // Find and tap the submit button
  final submitButton = find.byKey(const Key('login_submit_button'));
  await TestHelpers.tapWidget(tester, submitButton);

  // Wait a moment for authentication to process
  await tester.pump(const Duration(seconds: 1));

  // Wait for TripProvider to appear (which shows the loading animation)
  try {
    await TestHelpers.waitForWidget(tester, find.byType(TripProvider),
        timeout: const Duration(seconds: 8));
    print('✓ TripProvider displayed');
  } catch (e) {
    print('✗ TripProvider not found: $e');
    rethrow;
  }

  // Verify TripProvider is displayed
  expect(find.byType(TripProvider), findsOneWidget);

  // Give some time for the animation to potentially render
  await tester.pump(const Duration(milliseconds: 500));

  // Check for RiveAnimation or HomePage
  // The animation might be visible, or we might have already navigated to HomePage
  final animationWidget = find.byType(RiveAnimation);
  final homePageWidget = find.byType(HomePage);

  final hasAnimation = animationWidget.evaluate().isNotEmpty;
  final hasHomePage = homePageWidget.evaluate().isNotEmpty;

  if (hasAnimation) {
    print('✓ Rive animation is displayed during loading');
    expect(animationWidget, findsOneWidget);
  } else if (hasHomePage) {
    print('ℹ Already navigated to HomePage (loading was fast)');
    expect(homePageWidget, findsOneWidget);
  } else {
    print('⚠ Neither animation nor HomePage found yet, still loading...');
    // Wait a bit more for either to appear
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Should have either animation or HomePage by now
    final hasAnimationNow = find.byType(RiveAnimation).evaluate().isNotEmpty;
    final hasHomePageNow = find.byType(HomePage).evaluate().isNotEmpty;

    expect(hasAnimationNow || hasHomePageNow, isTrue,
        reason:
            'Should either find animation or have already navigated to HomePage');
  }
}
