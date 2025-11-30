import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/presentation/app/pages/login_page.dart';
import 'package:wandrr/presentation/app/pages/master_page/master_page.dart';
import 'package:wandrr/presentation/app/pages/onboarding/onboarding_page.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';

import '../helpers/test_helpers.dart';

/// Test: Startup page displays OnboardingPage and LoginPage side by side
/// when screen width > 1000
Future<void> runStartupPageLargeScreenTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(
    tester,
    MasterPage(sharedPreferences),
  );

  // Get actual device size
  final isLarge = TestHelpers.isLargeScreen(tester);
  print('Testing on ${TestHelpers.getDeviceSizeDescription(tester)}');

  // Verify StartupPage is displayed
  TestHelpers.verifyWidgetExists(find.byType(StartupPage));

  if (isLarge) {
    // Verify both OnboardingPage and LoginPage are displayed side by side
    TestHelpers.verifyWidgetExists(find.byType(OnBoardingPage));
    TestHelpers.verifyWidgetExists(find.byType(LoginPage));

    // Verify they are in a Row layout (side by side)
    final row = find.ancestor(
      of: find.byType(OnBoardingPage),
      matching: find.byType(Row),
    );
    TestHelpers.verifyWidgetExists(row);

    // Verify no next button is shown (only for small screens)
    final nextButton = find.byIcon(Icons.navigate_next_rounded);
    TestHelpers.verifyWidgetDoesNotExist(nextButton);
  } else {
    print('Skipping large screen test - device has small screen');
  }
}

/// Test: Startup page displays OnboardingPage with next button
/// when screen width < 1000
Future<void> runStartupPageSmallScreenTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(
    tester,
    MasterPage(sharedPreferences),
  );

  // Get actual device size
  final isSmall = TestHelpers.isSmallScreen(tester);
  print('Testing on ${TestHelpers.getDeviceSizeDescription(tester)}');

  // Verify StartupPage is displayed
  TestHelpers.verifyWidgetExists(find.byType(StartupPage));

  if (isSmall) {
    // Verify OnboardingPage is displayed
    TestHelpers.verifyWidgetExists(find.byType(OnBoardingPage));

    // Verify LoginPage is NOT displayed initially
    TestHelpers.verifyWidgetDoesNotExist(find.byType(LoginPage));

    // Verify next button is shown
    final nextButton = find.byIcon(Icons.navigate_next_rounded);
    TestHelpers.verifyWidgetExists(nextButton);
  } else {
    print('Skipping small screen test - device has large screen');
  }
}

/// Test: Clicking next button navigates to LoginPage
Future<void> runStartupPageNavigationTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(
    tester,
    MasterPage(sharedPreferences),
  );

  // Get actual device size
  final isSmall = TestHelpers.isSmallScreen(tester);
  print('Testing on ${TestHelpers.getDeviceSizeDescription(tester)}');

  if (isSmall) {
    // Verify OnboardingPage is displayed
    TestHelpers.verifyWidgetExists(find.byType(OnBoardingPage));
    TestHelpers.verifyWidgetDoesNotExist(find.byType(LoginPage));

    // Find and tap the next button
    final nextButton = find.byIcon(Icons.navigate_next_rounded);
    await TestHelpers.tapWidget(tester, nextButton);

    // Verify LoginPage is now displayed
    TestHelpers.verifyWidgetExists(find.byType(LoginPage));

    // Verify OnboardingPage is no longer displayed
    TestHelpers.verifyWidgetDoesNotExist(find.byType(OnBoardingPage));
  } else {
    print(
        'Skipping navigation test - device has large screen (no next button)');
  }
}

