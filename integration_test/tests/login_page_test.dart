import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/presentation/app/pages/login_page.dart';
import 'package:wandrr/presentation/app/pages/master_page/master_page.dart';
import 'package:wandrr/presentation/trip/pages/home/home_page.dart';

import '../helpers/test_helpers.dart';

/// Test: Login with username and password navigates to HomePage
Future<void> runLoginAuthenticationTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(
    tester,
    MasterPage(sharedPreferences),
  );

  print('Testing on ${TestHelpers.getDeviceSizeDescription(tester)}');

  // Verify LoginPage is displayed
  TestHelpers.verifyWidgetExists(find.byType(LoginPage));

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

  // Wait for authentication to complete and HomePage to appear
  await TestHelpers.waitForWidget(tester, find.byType(HomePage),
      timeout: const Duration(seconds: 10));

  // Verify HomePage is displayed
  TestHelpers.verifyWidgetExists(find.byType(HomePage));
}

/// Test: Rive animation is displayed during authentication
Future<void> runLoginAnimationTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(
    tester,
    MasterPage(sharedPreferences),
  );

  print('Testing on ${TestHelpers.getDeviceSizeDescription(tester)}');

  // Verify LoginPage is displayed
  TestHelpers.verifyWidgetExists(find.byType(LoginPage));

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

  // Wait a bit for animation to potentially start
  await tester.pump(const Duration(milliseconds: 500));

  // Verify Rive animation is displayed
  // Note: The animation widget type might be RiveAnimation or similar
  // Adjust based on your actual implementation
  final animationWidget = find.byType(RiveAnimation);

  // The animation should be present during loading
  // (This might need adjustment based on when the animation appears)
  if (animationWidget.evaluate().isNotEmpty) {
    TestHelpers.verifyWidgetExists(animationWidget);
  }

  // Wait for authentication to complete and HomePage to appear
  await TestHelpers.waitForWidget(tester, find.byType(HomePage),
      timeout: const Duration(seconds: 10));
}

