import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_config.dart';

/// Helper utilities for integration tests
class TestHelpers {
  /// Test credentials
  static const String testUsername = TestConfig.testEmail;
  static const String testPassword = TestConfig.testPassword;

  /// Setup authenticated state for tests
  static Future<void> setupAuthenticatedState(
      SharedPreferences sharedPreferences) async {
    // Set authentication flags in shared preferences
    // Note: Adjust these keys based on your actual implementation
    await sharedPreferences.setString('user_id', TestConfig.testUserId);
    await sharedPreferences.setBool('is_authenticated', true);
  }

  /// Create a test trip for trip editor tests
  static Future<void> createTestTrip(
      SharedPreferences sharedPreferences) async {
    // Store a test trip in shared preferences
    // Note: Adjust based on your actual data structure
    await sharedPreferences.setString('current_trip_id', TestConfig.testTripId);
  }

  /// Pump the app and wait for animations to settle
  ///
  /// This method automatically waits for the native splash screen to complete
  /// before proceeding with the test.
  static Future<void> pumpAndSettleApp(WidgetTester tester, Widget app) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Wait for native splash screen to complete (Android/iOS)
    await _waitForNativeSplashScreen(tester);
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

  /// [DEPRECATED] Wait for a specific duration
  ///
  /// This method is deprecated because it uses fixed duration waits which:
  /// - Makes tests slower than necessary
  /// - Makes tests flaky on slower devices
  /// - Doesn't verify what you're actually waiting for
  ///
  /// Use [waitForWidget] instead to wait for specific widgets to appear.
  /// Use [pumpAndSettle] without duration for animations.
  @Deprecated('Use waitForWidget() instead for async operations')
  static Future<void> waitForAsync(WidgetTester tester,
      {Duration duration = const Duration(seconds: 2)}) async {
    await tester.pump(duration);
    await tester.pumpAndSettle();
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

  /// Check if the current device has a small screen (< 1000px width)
  static bool isSmallScreen(WidgetTester tester) {
    return !isLargeScreen(tester);
  }

  /// Get a description of the current device size for logging
  static String getDeviceSizeDescription(WidgetTester tester) {
    final size = getScreenSize(tester);
    final category = isLargeScreen(tester) ? 'Large' : 'Small';
    return '$category screen (${size.width.toInt()}x${size.height.toInt()})';
  }

  /// Find a widget by its key
  static Finder findByKey(String key) {
    return find.byKey(Key(key));
  }

  /// Find a widget by its type
  static Finder findByType<T>() {
    return find.byType(T);
  }

  /// Find a widget by its text
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// Check if a widget is visible on screen
  static bool isWidgetVisible(WidgetTester tester, Finder finder) {
    try {
      tester.widget(finder);
      return true;
    } catch (e) {
      return false;
    }
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

  /// Scroll until a widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder,
    Finder scrollable, {
    double scrollDelta = 100.0,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      scrollDelta,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
  }

  /// Verify that a widget exists
  static void verifyWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verify that multiple widgets exist
  static void verifyWidgetsExist(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// Verify that a widget does not exist
  static void verifyWidgetDoesNotExist(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verify text is displayed
  static void verifyTextDisplayed(String text) {
    expect(find.text(text), findsAtLeastNWidgets(1));
  }

  /// Get the size of a widget
  static Size getWidgetSize(WidgetTester tester, Finder finder) {
    final RenderBox renderBox = tester.renderObject(finder);
    return renderBox.size;
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

  /// Drag a widget
  static Future<void> dragWidget(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }

  /// Long press on a widget
  static Future<void> longPressWidget(
      WidgetTester tester, Finder finder) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }
}
