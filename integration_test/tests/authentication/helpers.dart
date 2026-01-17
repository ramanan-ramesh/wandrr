// ============================================================================
// HELPER CLASSES - Following Single Responsibility Principle
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/auth/models/auth_type.dart';
import 'package:wandrr/presentation/app/pages/login_page.dart';
import 'package:wandrr/presentation/trip/pages/home/home_page.dart';

import '../../helpers/test_helpers.dart';

/// Helper class for authentication test setup (SRP: Test data creation)
class AuthTestSetup {
  /// Create an unverified user (for testing verification flow)
  static Future<void> createUnverifiedUser({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await FirebaseAuth.instance.signOut();
  }

  /// Verify email verification status
  static Future<bool> verifyEmailWasVerified(
      String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = FirebaseAuth.instance.currentUser;
    final isVerified = user?.emailVerified ?? false;
    await FirebaseAuth.instance.signOut();
    return isVerified;
  }
}

/// Helper class for login UI interactions (SRP: UI testing)
class LoginTestActions {
  /// Navigate to login page (handles screen size differences)
  static Future<void> navigateToLoginPage(WidgetTester tester) async {
    if (!TestHelpers.isLargeScreen(tester)) {
      final nextButton = find.byIcon(Icons.navigate_next_rounded);
      if (nextButton.evaluate().isNotEmpty) {
        await TestHelpers.tapWidget(tester, nextButton);
        print('✓ Navigated to LoginPage');
      }
    }
  }

  /// Perform login with credentials
  static Future<void> performLogin(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    final usernameField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).last;

    await TestHelpers.enterText(tester, usernameField, email);
    await TestHelpers.enterText(tester, passwordField, password);

    final submitButton = find.byKey(const Key('login_submit_button'));
    await TestHelpers.tapWidget(tester, submitButton);

    // Wait for authentication processing
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Verify successful login navigation
  static Future<void> verifySuccessfulLogin(WidgetTester tester) async {
    // With go_router, after successful login the app navigates to /trips which shows HomePage
    await TestHelpers.waitForWidget(
      tester,
      find.byType(HomePage),
      timeout: const Duration(seconds: 8),
    );
  }

  /// Verify login failed (still on LoginPage)
  static void verifyLoginFailed(WidgetTester tester, String reason) {
    expect(find.byType(LoginPage), findsOneWidget,
        reason: 'Should still be on LoginPage: $reason');
  }

  /// Switch to Register tab on LoginPage
  static Future<void> switchToSignUpTab(WidgetTester tester) async {
    // Find the Register tab by text
    final registerTab = find.text('Register');

    // Verify the tab exists
    expect(registerTab, findsOneWidget,
        reason: 'Register tab should be present on LoginPage');

    print('✓ Found Register tab, tapping it now');

    // Tap the Register tab
    await tester.tap(registerTab);
    await tester.pumpAndSettle();

    // Give the tab animation time to complete
    await tester.pump(const Duration(milliseconds: 300));

    print('✓ Switched to Register tab');
  }

  /// Perform sign up with credentials
  static Future<void> performSignUp(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    // Find text fields in the sign up tab
    final usernameField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).last;

    await TestHelpers.enterText(tester, usernameField, email);
    await TestHelpers.enterText(tester, passwordField, password);

    // The submit button is the same for both login and register
    // The behavior changes based on which tab is active (tabController.index)
    final submitButton = find.byKey(const Key('login_submit_button'));

    // Verify button exists
    expect(submitButton, findsOneWidget,
        reason: 'Submit button should be present');

    await TestHelpers.tapWidget(tester, submitButton);

    // Wait for authentication processing
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Verify that the verification pending message appears in the UI
  static Future<void> verifyVerificationPendingMessage(
      WidgetTester tester) async {
    // Look for the verification pending message text
    var localizations = TestHelpers.getAppLocalizations(tester, LoginPage);
    final verificationMessage = find.text(localizations.verificationPending);

    expect(verificationMessage.evaluate().isNotEmpty, true,
        reason: 'Verification pending message should appear in UI. ');
  }

  static Future<void> verifyLoginFailsOnInvalidEntry(
      WidgetTester tester,
      String email,
      String password,
      String loginFailureMessage,
      String verificationSuccessMessage,
      String errorMessage) async {
    // Enter invalid email
    await LoginTestActions.performLogin(
      tester,
      email: email,
      password: password,
    );
    // VERIFY: Should still be on LoginPage
    LoginTestActions.verifyLoginFailed(tester, 'Invalid email format');
    TestLogger.logSuccess('Stayed on LoginPage after invalid email');
    var errorMessageText = find.textContaining(errorMessage);
    expect(errorMessageText.evaluate().isNotEmpty, true,
        reason: 'Error message should appear in UI for invalid entry');
  }
}

/// Helper class for Firestore verification (SRP: Data validation)
class FirestoreTestVerifier {
  /// Verify user document exists in Firestore
  static Future<void> verifyUserDocumentExists(String email) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userName', isEqualTo: email)
        .get();

    expect(querySnapshot.docs.length, 1,
        reason: 'One user document should exist in Firestore for $email');
  }

  /// Verify user document does NOT exist in Firestore
  static Future<void> verifyUserDocumentDoesNotExist(String email) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userName', isEqualTo: email)
        .get();

    expect(querySnapshot.docs.isEmpty, true,
        reason: 'User document should NOT exist in Firestore for $email');
  }

  /// Verify document structure and fields
  static Future<Map<String, dynamic>> verifyDocumentStructure(
      String email) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userName', isEqualTo: email)
        .get();

    expect(querySnapshot.docs.isNotEmpty, true,
        reason: 'User document should exist');

    final userData = querySnapshot.docs.first.data();

    expect(userData.containsKey('userName'), true);
    expect(userData.containsKey('authType'), true);
    expect(userData['userName'], email);
    expect(userData['authType'], AuthenticationType.emailPassword.name);

    return userData;
  }
}

/// Helper class for test logging (SRP: Logging and reporting)
class TestLogger {
  static void logTestStart(String testNumber, String description) {
    print('\n[$testNumber] Testing $description...');
  }

  static void logSuccess(String message) {
    print('✓ $message');
  }

  static void logWarning(String message) {
    print('⚠ $message');
  }

  static void logInfo(String message) {
    print('  - $message');
  }
}
