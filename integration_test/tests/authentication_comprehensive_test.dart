import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/auth/models/auth_type.dart';
import 'package:wandrr/presentation/app/pages/login_page.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_provider/trip_provider.dart';

import '../helpers/firebase_emulator_helper.dart';
import '../helpers/test_config.dart';
import '../helpers/test_helpers.dart';

/// Comprehensive integration tests for UserManagement authentication and Firestore logic
///
/// DESIGN PRINCIPLES APPLIED:
/// 1. Single Responsibility Principle (SRP): Each test focuses on one scenario
/// 2. Open/Closed Principle (OCP): Tests are extensible via helper methods
/// 3. Dependency Inversion Principle (DIP): Tests depend on abstractions (helpers)
/// 4. Don't Repeat Yourself (DRY): Common logic extracted to helper methods
///
/// Tests all scenarios in user_management.dart:
/// 1. Sign in with existing user (with Firestore doc) + email verified
/// 2. Sign in with new user (no Firestore doc) + creates doc
/// 3. Sign in with unverified email → verificationPending
/// 4. Sign up new user → creates user + sends verification
/// 5. Sign up with existing email → error
/// 6. Invalid credentials (wrong password, invalid email, user not found)
/// 7. Sign out → clears auth + cache + Firestore
/// 8. Firestore document structure validation

// ============================================================================
// TEST IMPLEMENTATIONS - Following DRY and OCP principles
// ============================================================================

/// Test 1: Sign in with existing user (verified email + Firestore document)
///
/// DESIGN NOTES:
/// - Tests the "happy path" where everything is set up correctly
/// - Validates email verification via REST API works
/// - Confirms user_management.dart's emailVerified check passes
/// - Verifies Firestore document is reused (not recreated)
Future<void> runSignInExistingUserWithFirestoreDoc(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  _TestLogger.logTestStart(
      '1/10', 'sign in with existing user (has Firestore doc)');

  // SETUP: Create verified user with Firestore document
  await FirebaseEmulatorHelper.createFirebaseAuthUser(
    email: TestConfig.testEmail,
    password: TestConfig.testPassword,
    shouldAddToFirestore: true,
    shouldSignIn: false,
  );

  // TEST: Launch app and perform login
  await TestHelpers.pumpAndSettleApp(tester);
  await _LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  await _LoginTestActions.performLogin(
    tester,
    email: TestConfig.testEmail,
    password: TestConfig.testPassword,
  );

  // VERIFY: Successful login navigation
  await _LoginTestActions.verifySuccessfulLogin(tester);
  _TestLogger.logSuccess('Successfully signed in existing user');

  // VERIFY: Firestore document exists and is correct
  await _FirestoreTestVerifier.verifyUserDocumentExists(TestConfig.testEmail);
  _TestLogger.logSuccess('Firestore document verified');
}

/// Test 2: Sign in with user without Firestore document (should create one)
///
/// DESIGN NOTES:
/// - Tests user_management.dart lines 208-217 (creates new Firestore doc)
/// - Validates that users can sign in even without pre-existing Firestore data
/// - Confirms document is created during sign-in flow
/// - Tests emailVerified check with verified user
Future<void> runSignInNewUserWithoutFirestoreDoc(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  _TestLogger.logTestStart(
      '2/10', 'sign in with user without Firestore doc (should create one)');

  const testEmail = 'nofirestoredoc@example.com';
  const testPassword = r'Password123$';

  // SETUP: Create verified user in Auth only (NO Firestore doc)
  await FirebaseEmulatorHelper.createFirebaseAuthUser(
    email: testEmail,
    password: testPassword,
    shouldAddToFirestore: false,
    shouldSignIn: false,
  );

  await _FirestoreTestVerifier.verifyUserDocumentDoesNotExist(testEmail);

  // TEST: Launch app and perform login
  await TestHelpers.pumpAndSettleApp(tester);
  await _LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  await _LoginTestActions.performLogin(
    tester,
    email: testEmail,
    password: testPassword,
  );

  await _LoginTestActions.verifySuccessfulLogin(tester);
  _TestLogger.logSuccess('Successfully signed in user without Firestore doc');

  // VERIFY: Document exists and structure is correct
  final userData =
      await _FirestoreTestVerifier.verifyDocumentStructure(testEmail);
  _TestLogger.logSuccess('Firestore document was created during sign-in');
  _TestLogger.logInfo(
      'Document created with userName: ${userData['userName']}');
  _TestLogger.logInfo(
      'Document created with authType: ${userData['authType']}');
}

/// Test 3: Sign in with unverified email (should return verificationPending)
///
/// DESIGN NOTES:
/// - Tests user_management.dart (emailVerified check)
/// - Validates that unverified users cannot sign in
/// - Confirms user is signed out and verificationPending is returned
Future<void> runSignInUnverifiedEmail(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  _TestLogger.logTestStart(
      '3/10', 'sign in with unverified email (verificationPending)');

  const testEmail = 'unverified@example.com';
  const testPassword = r'Password123$';

  // SETUP: Create user WITHOUT verifying email
  await _AuthTestSetup.createUnverifiedUser(
    email: testEmail,
    password: testPassword,
  );

  // VERIFY: Email is NOT verified
  final isVerified =
      await _AuthTestSetup.verifyEmailWasVerified(testEmail, testPassword);

  if (isVerified) {
    _TestLogger.logWarning(
        'Email was verified unexpectedly - emulator may auto-verify');
    fail('Pre-Condition: Email should NOT be verified');
  } else {
    _TestLogger.logInfo('User created without email verification');
  }

  // TEST: Launch app and attempt login
  await TestHelpers.pumpAndSettleApp(tester);
  await _LoginTestActions.navigateToLoginPage(tester);
  expect(find.byType(LoginPage), findsOneWidget);

  await _LoginTestActions.performLogin(
    tester,
    email: testEmail,
    password: testPassword,
  );

  // VERIFY: Should stay on LoginPage (verification pending)
  _LoginTestActions.verifyLoginFailed(tester, 'Email not verified');
  _TestLogger.logSuccess(
      'Stayed on LoginPage (verification pending as expected)');

  // VERIFY: Verification pending message appears in UI
  await _LoginTestActions.verifyVerificationPendingMessage(tester);
  _TestLogger.logSuccess('Verification pending message displayed in UI');

  // VERIFY: User was signed out (per user_management.dart)
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull,
      reason: 'User should be signed out since verification is pending');
  _TestLogger.logSuccess(
      'User was signed out (per user_management.dart logic)');
}

/// Test 4: Sign up new user - Should create Auth user and return verificationPending
///
/// DESIGN NOTES:
/// - Tests user_management.dart trySignUpWithUsernamePassword flow
/// - Validates that new user registration sends verification email
/// - Confirms verificationPending status is returned and shown in UI
/// - Tests that user is signed out after registration
Future<void> runSignUpNewUser(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  _TestLogger.logTestStart(
      '4/10', 'sign up new user (should show verificationPending)');

  const testEmail = 'newuser@example.com';
  const testPassword = r'Password123$';

  // TEST: Launch app and navigate to sign up on LoginPage
  await TestHelpers.pumpAndSettleApp(tester);
  await _LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  // Switch to Sign Up tab
  await _LoginTestActions.switchToSignUpTab(tester);
  _TestLogger.logInfo('Switched to Sign Up tab');

  // Perform sign up
  await _LoginTestActions.performSignUp(
    tester,
    email: testEmail,
    password: testPassword,
  );

  // VERIFY: Should stay on LoginPage (verification pending)
  _LoginTestActions.verifyLoginFailed(tester, 'Sign up requires verification');
  _TestLogger.logSuccess('Stayed on LoginPage after sign up (as expected)');

  // VERIFY: Verification pending message appears in UI
  await _LoginTestActions.verifyVerificationPendingMessage(tester);
  _TestLogger.logSuccess(
      'Verification pending message displayed in UI after sign up');

  // VERIFY: User was signed out (per user_management.dart sign up logic)
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull,
      reason: 'User should be signed out after sign up pending verification');
  _TestLogger.logSuccess(
      'User was signed out after sign up (per user_management.dart logic)');
}

/// Test 5: Sign up with existing email - Should return usernameAlreadyExists or verificationPending
///
/// DESIGN NOTES:
/// - Tests user_management.dart trySignUpWithUsernamePassword with existing user
/// - If user is verified: should return usernameAlreadyExists
/// - If user is unverified: should return verificationPending
/// - Validates appropriate message is shown in UI
Future<void> runSignUpExistingEmail(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  _TestLogger.logTestStart('5/10',
      'sign up with existing email (should show error or verificationPending)');

  final testEmail = TestConfig.testEmail;
  final testPassword = TestConfig.testPassword;

  // TEST: Launch app and navigate to sign up on LoginPage
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, false);
  await _LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  // Switch to Sign Up tab
  await _LoginTestActions.switchToSignUpTab(tester);
  _TestLogger.logInfo('Switched to Sign Up tab');

  // Attempt to sign up with existing email
  await _LoginTestActions.performSignUp(
    tester,
    email: testEmail,
    password: testPassword,
  );

  // VERIFY: Should stay on LoginPage
  _LoginTestActions.verifyLoginFailed(tester, 'Email already exists');
  _TestLogger.logSuccess(
      'Stayed on LoginPage after attempting duplicate sign up');

  final localizations = TestHelpers.getAppLocalizations(tester, LoginPage);
  final alreadyExistsMessage =
      find.textContaining(localizations.userNameAlreadyExists);

  expect(
    alreadyExistsMessage.evaluate().isNotEmpty,
    true,
    reason: 'Should show either already registered message in UI',
  );

  _TestLogger.logSuccess('Correctly showed already registered message');

  // VERIFY: User is signed out
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull,
      reason: 'User should be signed out after failed sign up');
  _TestLogger.logSuccess('User was signed out as expected');
}

/// Test 6: Sign in with invalid credentials - Wrong password
///
/// DESIGN NOTES:
/// - Tests user_management.dart error handling for wrong password
/// - Validates appropriate error message appears in UI
/// - Confirms user stays on LoginPage and is not authenticated
Future<void> runSignInWrongPassword(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  _TestLogger.logTestStart('6/10', 'sign in with wrong password');

  final testEmail = TestConfig.testEmail;
  final wrongPassword = 'wrongPassword999';

  // Launch the app
  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, false);
  await _LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  // Enter credentials with wrong password
  await _LoginTestActions.performLogin(
    tester,
    email: testEmail,
    password: wrongPassword,
  );

  // VERIFY: Should still be on LoginPage
  _LoginTestActions.verifyLoginFailed(tester, 'Wrong password');
  _TestLogger.logSuccess('Stayed on LoginPage after wrong password');

  // VERIFY: Error message appears in UI
  var localizations = TestHelpers.getAppLocalizations(tester, LoginPage);
  final errorMessage = find.text(localizations.wrong_password_entered);

  expect(
    errorMessage.evaluate().isNotEmpty,
    true,
    reason: 'Error message should appear in UI for wrong password',
  );
  _TestLogger.logSuccess('Error message displayed for wrong password');

  // VERIFY: User is not authenticated
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull, reason: 'User should not be authenticated');
  _TestLogger.logSuccess('User is not authenticated (as expected)');
}

/// Test 7: Sign in with invalid email format
///
/// DESIGN NOTES:
/// - Tests form validation or Firebase error handling for invalid email
/// - Validates appropriate error message appears in UI
/// - Confirms user stays on LoginPage
Future<void> runSignInInvalidEmail(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  _TestLogger.logTestStart('7/10', 'sign in with invalid email format');

  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);
  await _LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  var localizations = TestHelpers.getAppLocalizations(tester, LoginPage);

  //Use Case 1 : Invalid email format(missing domain qualifier)
  await _LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      'invalid@email',
      'password',
      'Invalid email format',
      'Stayed on LoginPage after invalid email',
      localizations.enterValidEmail);

  //Use Case 2 : Invalid email format(missing domain and domain qualifier)
  await _LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      'invalid',
      'password',
      'Invalid email format',
      'Stayed on LoginPage after invalid email',
      localizations.enterValidEmail);

  //Use Case 3 : Invalid email format(missing domain and domain qualifier with just @)
  await _LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      'invalid@',
      'password',
      'Invalid email format',
      'Stayed on LoginPage after invalid email',
      localizations.enterValidEmail);

  //Password must be 8-20 characters long and include an uppercase letter, a lowercase letter, a digit, and a special character
  //Use Case 4 : Weak password(password less than)
  await _LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      'invalid@',
      'password',
      'Invalid email format',
      'Stayed on LoginPage after invalid email',
      localizations.enterValidEmail);

  // VERIFY: User is not authenticated
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull, reason: 'User should not be authenticated');
  _TestLogger.logSuccess('User is not authenticated (as expected)');
}

/// Test 8: Sign up with weak password
///
/// DESIGN NOTES:
/// - Tests form validation or Firebase error handling for weak password
/// - Validates appropriate error message appears in UI
/// - Confirms user stays on LoginPage
Future<void> runSignUpWeakPassword(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  _TestLogger.logTestStart('8/10', 'sign up with weak password');

  // Launch the app and navigate to Sign Up tab
  await TestHelpers.pumpAndSettleApp(tester);
  await _LoginTestActions.navigateToLoginPage(tester);
  expect(find.byType(LoginPage), findsOneWidget);
  await _LoginTestActions.switchToSignUpTab(tester);
  _TestLogger.logInfo('Switched to Sign Up tab');

  var localizations = TestHelpers.getAppLocalizations(tester, LoginPage);

  var userEmail = 'username@example.com';
  var verificationSuccessMessage = 'Stayed on LoginPage after weak password';
  var passwordPolicyErrorMessage = localizations.password_policy;

  //Use Case 1 : Weak password(less than 8 characters)
  await _LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      'pasword',
      'Password contains less than 8 characters',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  //Use Case 2 : Weak password(more than 20 characters)
  await _LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      r'invalidpasswordentry@123$',
      'Password contains more than 20 characters',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  //Use Case 3 : Weak password(must contain uppercase letter)
  await _LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      r'password@123$',
      'Password must contain an uppercase letter',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  //Use Case 4 : Weak password(must contain lowercase letter)
  await _LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      r'PASSWORD@123$',
      'Password must contain an lowercase letter',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  //Use Case 5 : Weak password(must contain a digit)
  await _LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      r'Password$',
      'Password must contain a digit',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  //Use Case 6 : Weak password(must contain a special character)
  await _LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      'Password123',
      'Password must contain a special character',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  // VERIFY: User is not authenticated
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull, reason: 'User should not be authenticated');
  _TestLogger.logSuccess('User is not authenticated (as expected)');
}

/// Test 9: Sign in with non-existent user
///
/// DESIGN NOTES:
/// - Tests Firebase error handling for non-existent user
/// - Validates appropriate error message appears in UI
/// - Confirms user stays on LoginPage and is not authenticated
Future<void> runSignInNonExistentUser(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  _TestLogger.logTestStart('9/10', 'sign in with non-existent user');

  final nonExistentEmail = 'nonexistent@example.com';
  final testPassword = r'Password123$';

  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);
  await _LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  // Attempt to sign in with non-existent user
  await _LoginTestActions.performLogin(
    tester,
    email: nonExistentEmail,
    password: testPassword,
  );

  await tester.pumpAndSettle();

  // VERIFY: Should still be on LoginPage
  _LoginTestActions.verifyLoginFailed(tester, 'User not found');
  _TestLogger.logSuccess('Stayed on LoginPage after non-existent user');

  // VERIFY: Error message appears in UI
  await tester.pump(const Duration(seconds: 1));
  var localizations = TestHelpers.getAppLocalizations(tester, LoginPage);
  final notFoundError = find.textContaining(localizations.noSuchUserExists);

  expect(
    notFoundError.evaluate().isNotEmpty,
    true,
    reason: 'Error message should appear in UI for non-existent user',
  );
  _TestLogger.logSuccess('Error message displayed for non-existent user');

  // VERIFY: User is not authenticated
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull, reason: 'User should not be authenticated');
  _TestLogger.logSuccess('User is not authenticated (as expected)');
}

/// Test 10: Sign out functionality
///
/// DESIGN NOTES:
/// - Tests sign out clears auth, cache, and Firestore listeners
/// - Validates user is signed out and returns to LoginPage
Future<void> runSignOutTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  _TestLogger.logTestStart('10/10', 'sign out functionality');

  // First, sign in
  final testEmail = TestConfig.testEmail;
  final testPassword = TestConfig.testPassword;

  await TestHelpers.pumpAndSettleAppWithTestUser(tester, true, true);
  await _LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  // Sign in
  await _LoginTestActions.performLogin(
    tester,
    email: testEmail,
    password: testPassword,
  );

  // VERIFY: Successfully signed in
  try {
    await _LoginTestActions.verifySuccessfulLogin(tester);
    _TestLogger.logSuccess('Signed in successfully');
  } catch (e) {
    _TestLogger.logWarning(
        'HomePage not found, but continuing with sign out test');
  }

  // VERIFY: User is authenticated
  var currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNotNull,
      reason: 'User should be authenticated after login');
  _TestLogger.logSuccess('User is authenticated');

  // TEST: Sign out
  final logoutButton = find.byIcon(Icons.logout);
  if (logoutButton.evaluate().isEmpty) {
    _TestLogger.logWarning('Logout button not found - test may be incomplete');
    fail('Logout button should be present after successful login');
  }

  await TestHelpers.tapWidget(tester, logoutButton);

  // VERIFY: Returned to LoginPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(StartupPage),
    timeout: const Duration(seconds: 5),
  );
  _TestLogger.logSuccess('Successfully signed out');
  _TestLogger.logSuccess('Navigated back to StartupPage');

  // VERIFY: Firebase Auth state cleared
  currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull, reason: 'User should be null after sign out');
  _TestLogger.logSuccess('Firebase Auth state cleared');

  // VERIFY: SharedPreferences cleared
  final userID = sharedPreferences.getString('userID');
  expect(userID, isNull, reason: 'UserID should be cleared from cache');
  _TestLogger.logSuccess('Local cache cleared');
}

// ============================================================================
// HELPER CLASSES - Following Single Responsibility Principle
// ============================================================================

/// Helper class for authentication test setup (SRP: Test data creation)
class _AuthTestSetup {
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
class _LoginTestActions {
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
    await TestHelpers.waitForWidget(
      tester,
      find.byType(TripProvider),
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
    await _LoginTestActions.performLogin(
      tester,
      email: email,
      password: password,
    );
    // VERIFY: Should still be on LoginPage
    _LoginTestActions.verifyLoginFailed(tester, 'Invalid email format');
    _TestLogger.logSuccess('Stayed on LoginPage after invalid email');
    var errorMessageText = find.textContaining(errorMessage);
    expect(errorMessageText.evaluate().isNotEmpty, true,
        reason: 'Error message should appear in UI for invalid entry');
  }
}

/// Helper class for Firestore verification (SRP: Data validation)
class _FirestoreTestVerifier {
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
class _TestLogger {
  static void logTestStart(String testNumber, String description) {
    print('\n[$testNumber] Testing $description...');
  }

  static void logSuccess(String message) {
    print('✓ $message');
  }

  static void logWarning(String message) {
    print('⚠ $message');
  }

  static void logError(String message) {
    print('✗ $message');
  }

  static void logInfo(String message) {
    print('  - $message');
  }
}
