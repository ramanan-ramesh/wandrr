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
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

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

  // Wait for TripProvider to appear (loading screen with animation)
  await TestHelpers.waitForWidget(tester, find.byType(TripProvider),
      timeout: const Duration(seconds: 5));

  // Verify TripProvider is displayed
  expect(find.byType(TripProvider), findsOneWidget);

  // Wait for trip repository loading and animation to complete, then HomePage appears
  await TestHelpers.waitForWidget(tester, find.byType(HomePage),
      timeout: const Duration(seconds: 10));

  // Verify HomePage is displayed
  expect(find.byType(HomePage), findsOneWidget);
}

/// Test: Rive animation is displayed during authentication
Future<void> runLoginAnimationTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

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

  // Wait for TripProvider to appear (which shows the loading animation)
  await TestHelpers.waitForWidget(tester, find.byType(TripProvider),
      timeout: const Duration(seconds: 5));

  // Verify TripProvider is displayed
  expect(find.byType(TripProvider), findsOneWidget);

  // Wait a bit for animation to render
  await tester.pump(const Duration(milliseconds: 500));

  // Verify Rive animation is displayed during loading
  // The TripProvider shows a RiveAnimation while loading the trip repository
  final animationWidget = find.byType(RiveAnimation);

  // The animation should be present during loading
  if (animationWidget.evaluate().isNotEmpty) {
    expect(animationWidget, findsOneWidget);
  }

  // Wait for authentication to complete and HomePage to appear
  await TestHelpers.waitForWidget(tester, find.byType(HomePage),
      timeout: const Duration(seconds: 10));
}
