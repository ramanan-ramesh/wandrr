import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/auth/models/auth_type.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/app/pages/master_page/master_page.dart';

import 'firebase_emulator_helper.dart';
import 'test_config.dart';

/// Helper utilities for integration tests
class TestHelpers {
  /// Test credentials
  static const String testUsername = TestConfig.testEmail;
  static const String testPassword = TestConfig.testPassword;

  /// Pump the app and wait for animations to settle
  ///
  /// This method automatically waits for the native splash screen to complete
  /// before proceeding with the test.
  static Future<void> pumpAndSettleApp(WidgetTester tester) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(MasterPage(sharedPreferences));
    await tester.pumpAndSettle();
    // Wait for native splash screen to complete (Android/iOS)
    await _waitForNativeSplashScreen(tester);
    // Log device size after splash screen
    print(_getDeviceSizeDescription(tester));
  }

  /// Pump the app and wait for animations to settle
  ///
  /// This method automatically waits for the native splash screen to complete
  /// before proceeding with the test.
  static Future<void> pumpAndSettleAppWithTestUser(
      WidgetTester tester, bool shouldAddToFirestore, bool shouldSignIn) async {
    await FirebaseEmulatorHelper.createFirebaseAuthUser(
      email: TestConfig.testEmail,
      password: TestConfig.testPassword,
      shouldAddToFirestore: shouldAddToFirestore,
      shouldSignIn: shouldSignIn,
    );

    final sharedPreferences = await SharedPreferences.getInstance();
    if (shouldSignIn) {
      await sharedPreferences.setString(
          'authType', AuthenticationType.emailPassword.name);
    }
    await tester.pumpWidget(MasterPage(sharedPreferences));
    await tester.pumpAndSettle();
    // Wait for native splash screen to complete (Android/iOS)
    await _waitForNativeSplashScreen(tester);
    // Log device size after splash screen
    print(_getDeviceSizeDescription(tester));
  }

  /// Setup authenticated state for tests
  static Future<void> setupAuthenticatedState(
      SharedPreferences sharedPreferences) async {
    // Set authentication flags in shared preferences
    // Note: Adjust these keys based on your actual implementation
    await sharedPreferences.setString('user_id', TestConfig.testUserId);
    await sharedPreferences.setBool('is_authenticated', true);
  }

  static AppLocalizations getAppLocalizations(WidgetTester tester, Type type) {
    final context = tester.element(find.byType(type));
    return AppLocalizations.of(context)!;
  }

  /// Create a test trip for trip editor tests
  static Future<void> createTestTrip(
      SharedPreferences sharedPreferences) async {
    // Store a test trip in shared preferences
    // Note: Adjust based on your actual data structure
    await sharedPreferences.setString('current_trip_id', TestConfig.testTripId);
  }

  /// Get the current device screen size
  static Size getScreenSize(WidgetTester tester) {
    return tester.view.physicalSize / tester.view.devicePixelRatio;
  }

  /// Check if the current device has a large screen (>= 1000px width)
  static bool isLargeScreen(WidgetTester tester) {
    final size = getScreenSize(tester);
    return size.width >= TestConfig.bigLayoutBreakpoint;
  }

  /// Enter text into a text field
  static Future<void> enterText(
      WidgetTester tester, Finder finder, String text) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Tap on a widget
  static Future<void> tapWidget(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Get the position of a widget
  static Offset getWidgetPosition(WidgetTester tester, Finder finder) {
    final RenderBox renderBox = tester.renderObject(finder);
    return renderBox.localToGlobal(Offset.zero);
  }

  /// Wait for a specific widget to appear
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));

      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }

    throw Exception('Widget not found within timeout: $finder');
  }

  /// Wait for native splash screen to complete (Private helper)
  ///
  /// The Android/iOS native splash screen runs before Flutter's runApp() is called.
  /// On Android (MainActivity.kt), there's a 3-second animation with:
  /// - Spaceship animation (3 seconds)
  /// - Logo fade out (2 seconds)
  /// - Text fade in (1 second)
  /// Total delay before FlutterAppActivity starts: 3 seconds
  ///
  /// This method is called automatically by pumpAndSettleApp().
  static Future<void> _waitForNativeSplashScreen(WidgetTester tester) async {
    // The native splash screen takes ~3 seconds on Android
    // We wait for any Flutter widget to appear, which indicates the Flutter
    // engine has started and the native splash is complete

    // Give some initial time for native splash to potentially start
    await tester.pump(const Duration(milliseconds: 100));

    // Now wait for Flutter to actually render something
    // This is better than a fixed 3-second wait because:
    // 1. On some devices it might be faster
    // 2. On emulators it might take longer
    // 3. We verify that Flutter has actually started

    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  /// Get a description of the current device size for logging
  static String _getDeviceSizeDescription(WidgetTester tester) {
    final size = getScreenSize(tester);
    final category = isLargeScreen(tester) ? 'Large' : 'Small';
    return '$category screen (${size.width.toInt()}x${size.height.toInt()})';
  }
}
