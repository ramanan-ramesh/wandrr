import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/presentation/app/pages/login_page.dart';
import 'package:wandrr/presentation/app/pages/onboarding/onboarding_page.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';

import '../helpers/test_helpers.dart';

/// Comprehensive test for StartupPage that adapts to device screen size
///
/// For large screens (width >= 1000):
/// - Displays OnboardingPage and LoginPage side by side
/// - No next button navigation needed
///
/// For small screens (width < 1000):
/// - Displays OnboardingPage first with next button
/// - Tapping next button navigates to LoginPage
Future<void> runStartupPageTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Determine screen size
  final isLarge = TestHelpers.isLargeScreen(tester);

  // Verify StartupPage is displayed
  expect(find.byType(StartupPage), findsOneWidget);

  if (isLarge) {
    // ==================== LARGE SCREEN SCENARIO ====================
    print('Running large screen scenario');

    // Find both OnboardingPage and LoginPage
    final onboardingFinder = find.byType(OnBoardingPage);
    final loginFinder = find.byType(LoginPage);

    expect(onboardingFinder, findsOneWidget);
    expect(loginFinder, findsOneWidget);

    // Find the Row ancestor that contains OnboardingPage
    final onboardingRowFinder = find.ancestor(
      of: onboardingFinder,
      matching: find.byType(Row),
    );
    expect(onboardingRowFinder, findsWidgets,
        reason: 'OnboardingPage must have a Row ancestor');

    // Find the Row ancestor that contains LoginPage
    final loginRowFinder = find.ancestor(
      of: loginFinder,
      matching: find.byType(Row),
    );
    expect(loginRowFinder, findsWidgets,
        reason: 'LoginPage must have a Row ancestor');

    // Get the actual Row widgets
    final onboardingRowWidget = tester.widget<Row>(onboardingRowFinder.first);
    final loginRowWidget = tester.widget<Row>(loginRowFinder.first);

    // Verify both pages share the same Row ancestor
    expect(identical(onboardingRowWidget, loginRowWidget), isTrue,
        reason:
            'OnboardingPage and LoginPage must share the same Row ancestor');

    // Additionally verify the Row has exactly 2 children in correct order
    expect(onboardingRowWidget.children.length, 2,
        reason: 'Row must contain exactly 2 children');
    expect(onboardingRowWidget.children[0].runtimeType.toString(),
        contains('Expanded'));
    expect(onboardingRowWidget.children[1].runtimeType.toString(),
        contains('Expanded'));

    // Verify no next button is shown (only for small screens)
    final nextButton = find.byIcon(Icons.navigate_next_rounded);
    expect(nextButton, findsNothing);

    print(
        '✓ Large screen layout verified: OnboardingPage and LoginPage are side-by-side in Row');
  } else {
    // ==================== SMALL SCREEN SCENARIO ====================
    print('Running small screen scenario');

    // Verify OnboardingPage is displayed
    expect(find.byType(OnBoardingPage), findsOneWidget);

    // Verify LoginPage is NOT displayed initially
    expect(find.byType(LoginPage), findsNothing);

    // Verify next button is shown
    final nextButton = find.byIcon(Icons.navigate_next_rounded);
    expect(nextButton, findsOneWidget);

    print('✓ OnboardingPage displayed with next button');

    // Test navigation: tap next button
    await TestHelpers.tapWidget(tester, nextButton);

    // Verify LoginPage is now displayed
    expect(find.byType(LoginPage), findsOneWidget);

    // Verify OnboardingPage is no longer displayed
    expect(find.byType(OnBoardingPage), findsNothing);

    print('✓ Navigation to LoginPage successful');
  }
}
