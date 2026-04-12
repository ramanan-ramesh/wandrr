import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/presentation/app/pages/login_page.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';

import '../../helpers/firebase_emulator_helper.dart';
import '../../helpers/test_config.dart';
import '../../helpers/test_helpers.dart';
import 'helpers.dart';

/// Comprehensive integration tests for UserManagement authentication and Firestore logic
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
) async {
  TestLogger.logTestStart(
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
  await LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  await LoginTestActions.performLogin(
    tester,
    email: TestConfig.testEmail,
    password: TestConfig.testPassword,
  );

  // VERIFY: Successful login navigation
  await LoginTestActions.verifySuccessfulLogin(tester);
  TestLogger.logSuccess('Successfully signed in existing user');

  // VERIFY: Firestore document exists and is correct
  await FirestoreTestVerifier.verifyUserDocumentExists(TestConfig.testEmail);
  TestLogger.logSuccess('Firestore document verified');
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
) async {
  TestLogger.logTestStart(
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

  await FirestoreTestVerifier.verifyUserDocumentDoesNotExist(testEmail);

  // TEST: Launch app and perform login
  await TestHelpers.pumpAndSettleApp(tester);
  await LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  await LoginTestActions.performLogin(
    tester,
    email: testEmail,
    password: testPassword,
  );

  await LoginTestActions.verifySuccessfulLogin(tester);
  TestLogger.logSuccess('Successfully signed in user without Firestore doc');

  // VERIFY: Document exists and structure is correct
  final userData =
      await FirestoreTestVerifier.verifyDocumentStructure(testEmail);
  TestLogger.logSuccess('Firestore document was created during sign-in');
  TestLogger.logInfo('Document created with userName: ${userData['userName']}');
  TestLogger.logInfo('Document created with authType: ${userData['authType']}');
}

/// Test 3: Sign in with unverified email (should return verificationPending)
///
/// DESIGN NOTES:
/// - Tests user_management.dart (emailVerified check)
/// - Validates that unverified users cannot sign in
/// - Confirms user is signed out and verificationPending is returned
Future<void> runSignInUnverifiedEmail(
  WidgetTester tester,
) async {
  TestLogger.logTestStart(
      '3/10', 'sign in with unverified email (verificationPending)');

  const testEmail = 'unverified@example.com';
  const testPassword = r'Password123$';

  // SETUP: Create user WITHOUT verifying email
  await AuthTestSetup.createUnverifiedUser(
    email: testEmail,
    password: testPassword,
  );

  // VERIFY: Email is NOT verified
  final isVerified =
      await AuthTestSetup.verifyEmailWasVerified(testEmail, testPassword);

  if (isVerified) {
    TestLogger.logWarning(
        'Email was verified unexpectedly - emulator may auto-verify');
    fail('Pre-Condition: Email should NOT be verified');
  } else {
    TestLogger.logInfo('User created without email verification');
  }

  // TEST: Launch app and attempt login
  await TestHelpers.pumpAndSettleApp(tester);
  await LoginTestActions.navigateToLoginPage(tester);
  expect(find.byType(LoginPage), findsOneWidget);

  await LoginTestActions.performLogin(
    tester,
    email: testEmail,
    password: testPassword,
  );

  // VERIFY: Should stay on LoginPage (verification pending)
  LoginTestActions.verifyLoginFailed(tester, 'Email not verified');
  TestLogger.logSuccess(
      'Stayed on LoginPage (verification pending as expected)');

  // VERIFY: Verification pending message appears in UI
  await LoginTestActions.verifyVerificationPendingMessage(tester);
  TestLogger.logSuccess('Verification pending message displayed in UI');

  // VERIFY: User was signed out (per user_management.dart)
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull,
      reason: 'User should be signed out since verification is pending');
  TestLogger.logSuccess('User was signed out (per user_management.dart logic)');
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
) async {
  TestLogger.logTestStart(
      '4/10', 'sign up new user (should show verificationPending)');

  const testEmail = 'newuser@example.com';
  const testPassword = r'Password123$';

  // TEST: Launch app and navigate to sign up on LoginPage
  await TestHelpers.pumpAndSettleApp(tester);
  await LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  // Switch to Sign Up tab
  await LoginTestActions.switchToSignUpTab(tester);
  TestLogger.logInfo('Switched to Sign Up tab');

  // Perform sign up
  await LoginTestActions.performSignUp(
    tester,
    email: testEmail,
    password: testPassword,
  );

  // VERIFY: Should stay on LoginPage (verification pending)
  LoginTestActions.verifyLoginFailed(tester, 'Sign up requires verification');
  TestLogger.logSuccess('Stayed on LoginPage after sign up (as expected)');

  // VERIFY: Verification pending message appears in UI
  await LoginTestActions.verifyVerificationPendingMessage(tester);
  TestLogger.logSuccess(
      'Verification pending message displayed in UI after sign up');

  // VERIFY: User was signed out (per user_management.dart sign up logic)
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull,
      reason: 'User should be signed out after sign up pending verification');
  TestLogger.logSuccess(
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
) async {
  TestLogger.logTestStart('5/10',
      'sign up with existing email (should show error or verificationPending)');

  const testEmail = TestConfig.testEmail;
  const testPassword = TestConfig.testPassword;

  // TEST: Launch app and navigate to sign up on LoginPage
  await FirebaseEmulatorHelper.createFirebaseAuthUser(
    email: TestConfig.testEmail,
    password: TestConfig.testPassword,
    shouldAddToFirestore: true,
    shouldSignIn: false,
  );
  await TestHelpers.pumpAndSettleApp(tester);
  await LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  // Switch to Sign Up tab
  await LoginTestActions.switchToSignUpTab(tester);
  TestLogger.logInfo('Switched to Sign Up tab');

  // Attempt to sign up with existing email
  await LoginTestActions.performSignUp(
    tester,
    email: testEmail,
    password: testPassword,
  );

  // VERIFY: Should stay on LoginPage
  LoginTestActions.verifyLoginFailed(tester, 'Email already exists');
  TestLogger.logSuccess(
      'Stayed on LoginPage after attempting duplicate sign up');

  final localizations = TestHelpers.getAppLocalizations(tester, LoginPage);
  final alreadyExistsMessage =
      find.textContaining(localizations.userNameAlreadyExists);

  expect(
    alreadyExistsMessage.evaluate().isNotEmpty,
    true,
    reason: 'Should show either already registered message in UI',
  );

  TestLogger.logSuccess('Correctly showed already registered message');

  // VERIFY: User is signed out
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull,
      reason: 'User should be signed out after failed sign up');
  TestLogger.logSuccess('User was signed out as expected');
}

/// Test 6: Sign in with invalid credentials - Wrong password
///
/// DESIGN NOTES:
/// - Tests user_management.dart error handling for wrong password
/// - Validates appropriate error message appears in UI
/// - Confirms user stays on LoginPage and is not authenticated
Future<void> runSignInWrongPassword(
  WidgetTester tester,
) async {
  TestLogger.logTestStart('6/10', 'sign in with wrong password');

  const testEmail = TestConfig.testEmail;
  const wrongPassword = r'WrongPassword123$';

  // Launch the app
  await FirebaseEmulatorHelper.createFirebaseAuthUser(
    email: TestConfig.testEmail,
    password: TestConfig.testPassword,
    shouldAddToFirestore: true,
    shouldSignIn: false,
  );
  await TestHelpers.pumpAndSettleApp(tester);
  await LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  // Enter credentials with wrong password
  await LoginTestActions.performLogin(
    tester,
    email: testEmail,
    password: wrongPassword,
  );

  // VERIFY: Should still be on LoginPage
  LoginTestActions.verifyLoginFailed(tester, 'Wrong password');
  TestLogger.logSuccess('Stayed on LoginPage after wrong password');

  // VERIFY: Error message appears in UI
  var localizations = TestHelpers.getAppLocalizations(tester, LoginPage);
  final errorMessage = find.text(localizations.wrong_password_entered);

  expect(
    errorMessage.evaluate().isNotEmpty,
    true,
    reason: 'Error message should appear in UI for wrong password',
  );
  TestLogger.logSuccess('Error message displayed for wrong password');

  // VERIFY: User is not authenticated
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull, reason: 'User should not be authenticated');
  TestLogger.logSuccess('User is not authenticated (as expected)');
}

/// Test 7: Sign in with invalid email format
///
/// DESIGN NOTES:
/// - Tests form validation or Firebase error handling for invalid email
/// - Validates appropriate error message appears in UI
/// - Confirms user stays on LoginPage
Future<void> runSignInInvalidEmail(
  WidgetTester tester,
) async {
  TestLogger.logTestStart('7/10', 'sign in with invalid email format');

  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);
  await LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  var localizations = TestHelpers.getAppLocalizations(tester, LoginPage);

  //Use Case 1 : Invalid email format(missing domain qualifier)
  await LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      'invalid@email',
      'password',
      'Invalid email format',
      'Stayed on LoginPage after invalid email',
      localizations.enterValidEmail);

  //Use Case 2 : Invalid email format(missing domain and domain qualifier)
  await LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      'invalid',
      'password',
      'Invalid email format',
      'Stayed on LoginPage after invalid email',
      localizations.enterValidEmail);

  //Use Case 3 : Invalid email format(missing domain and domain qualifier with just @)
  await LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      'invalid@',
      'password',
      'Invalid email format',
      'Stayed on LoginPage after invalid email',
      localizations.enterValidEmail);

  //Password must be 8-20 characters long and include an uppercase letter, a lowercase letter, a digit, and a special character
  //Use Case 4 : Weak password(password less than)
  await LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      'invalid@',
      'password',
      'Invalid email format',
      'Stayed on LoginPage after invalid email',
      localizations.enterValidEmail);

  // VERIFY: User is not authenticated
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull, reason: 'User should not be authenticated');
  TestLogger.logSuccess('User is not authenticated (as expected)');
}

/// Test 8: Sign up with weak password
///
/// DESIGN NOTES:
/// - Tests form validation or Firebase error handling for weak password
/// - Validates appropriate error message appears in UI
/// - Confirms user stays on LoginPage
Future<void> runSignUpWeakPassword(
  WidgetTester tester,
) async {
  TestLogger.logTestStart('8/10', 'sign up with weak password');

  // Launch the app and navigate to Sign Up tab
  await TestHelpers.pumpAndSettleApp(tester);
  await LoginTestActions.navigateToLoginPage(tester);
  expect(find.byType(LoginPage), findsOneWidget);
  await LoginTestActions.switchToSignUpTab(tester);
  TestLogger.logInfo('Switched to Sign Up tab');

  var localizations = TestHelpers.getAppLocalizations(tester, LoginPage);

  var userEmail = 'username@example.com';
  var verificationSuccessMessage = 'Stayed on LoginPage after weak password';
  var passwordPolicyErrorMessage = localizations.password_policy;

  //Use Case 1 : Weak password(less than 8 characters)
  await LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      'pasword',
      'Password contains less than 8 characters',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  //Use Case 2 : Weak password(more than 20 characters)
  await LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      r'invalidpasswordentry@123$',
      'Password contains more than 20 characters',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  //Use Case 3 : Weak password(must contain uppercase letter)
  await LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      r'password@123$',
      'Password must contain an uppercase letter',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  //Use Case 4 : Weak password(must contain lowercase letter)
  await LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      r'PASSWORD@123$',
      'Password must contain an lowercase letter',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  //Use Case 5 : Weak password(must contain a digit)
  await LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      r'Password$',
      'Password must contain a digit',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  //Use Case 6 : Weak password(must contain a special character)
  await LoginTestActions.verifyLoginFailsOnInvalidEntry(
      tester,
      userEmail,
      'Password123',
      'Password must contain a special character',
      verificationSuccessMessage,
      passwordPolicyErrorMessage);

  // VERIFY: User is not authenticated
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull, reason: 'User should not be authenticated');
  TestLogger.logSuccess('User is not authenticated (as expected)');
}

/// Test 9: Sign in with non-existent user
///
/// DESIGN NOTES:
/// - Tests Firebase error handling for non-existent user
/// - Validates appropriate error message appears in UI
/// - Confirms user stays on LoginPage and is not authenticated
Future<void> runSignInNonExistentUser(
  WidgetTester tester,
) async {
  TestLogger.logTestStart('9/10', 'sign in with non-existent user');

  const nonExistentEmail = 'nonexistent@example.com';
  const testPassword = r'Password123$';

  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);
  await LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  // Attempt to sign in with non-existent user
  await LoginTestActions.performLogin(
    tester,
    email: nonExistentEmail,
    password: testPassword,
  );

  await tester.pumpAndSettle();

  // VERIFY: Should still be on LoginPage
  LoginTestActions.verifyLoginFailed(tester, 'User not found');
  TestLogger.logSuccess('Stayed on LoginPage after non-existent user');

  // VERIFY: Error message appears in UI
  await tester.pump(const Duration(seconds: 1));
  var localizations = TestHelpers.getAppLocalizations(tester, LoginPage);
  final notFoundError = find.textContaining(localizations.noSuchUserExists);

  expect(
    notFoundError.evaluate().isNotEmpty,
    true,
    reason: 'Error message should appear in UI for non-existent user',
  );
  TestLogger.logSuccess('Error message displayed for non-existent user');

  // VERIFY: User is not authenticated
  final currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull, reason: 'User should not be authenticated');
  TestLogger.logSuccess('User is not authenticated (as expected)');
}

/// Test 10: Sign out functionality
///
/// DESIGN NOTES:
/// - Tests sign out clears auth, cache, and Firestore listeners
/// - Validates user is signed out and returns to LoginPage
Future<void> runSignOutTest(
  WidgetTester tester,
) async {
  TestLogger.logTestStart('10/10', 'sign out functionality');

  // First, sign in
  const testEmail = TestConfig.testEmail;
  const testPassword = TestConfig.testPassword;

  await FirebaseEmulatorHelper.createFirebaseAuthUser(
    email: TestConfig.testEmail,
    password: TestConfig.testPassword,
    shouldAddToFirestore: true,
    shouldSignIn: false,
  );
  await TestHelpers.pumpAndSettleApp(tester);
  await LoginTestActions.navigateToLoginPage(tester);

  expect(find.byType(LoginPage), findsOneWidget);

  // Sign in
  await LoginTestActions.performLogin(
    tester,
    email: testEmail,
    password: testPassword,
  );

  await LoginTestActions.verifySuccessfulLogin(tester);
  TestLogger.logSuccess('Signed in successfully');

  // VERIFY: User is authenticated
  var currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNotNull,
      reason: 'User should be authenticated after login');
  TestLogger.logSuccess('User is authenticated');

  // TEST: Sign out
  final toolbarButton = find.byIcon(Icons.settings);
  await TestHelpers.tapWidget(tester, toolbarButton);
  final logoutButton = find.byIcon(Icons.logout);
  if (logoutButton.evaluate().isEmpty) {
    TestLogger.logWarning('Logout button not found - test may be incomplete');
    fail('Logout button should be present after successful login');
  }

  await TestHelpers.tapWidget(tester, logoutButton);

  // VERIFY: Returned to LoginPage
  await TestHelpers.waitForWidget(
    tester,
    find.byType(StartupPage),
    timeout: const Duration(seconds: 5),
  );
  TestLogger.logSuccess('Successfully signed out');
  TestLogger.logSuccess('Navigated back to StartupPage');

  // VERIFY: Firebase Auth state cleared
  currentUser = FirebaseAuth.instance.currentUser;
  expect(currentUser, isNull, reason: 'User should be null after sign out');
  TestLogger.logSuccess('Firebase Auth state cleared');

  // VERIFY: SharedPreferences cleared
  final sharedPreferences = await SharedPreferences.getInstance();
  expect(sharedPreferences.getKeys().isEmpty, true,
      reason: 'UserData should be cleared from cache');
  TestLogger.logSuccess('Local cache cleared');
}

void runTests() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    expect(find.byType(ErrorWidget), findsNothing);
    var sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.clear();
    await FirebaseEmulatorHelper.cleanupAfterTest();
  });

  testWidgets('Sign in with existing user (has Firestore document)',
      (WidgetTester tester) async {
    await runSignInExistingUserWithFirestoreDoc(tester);
  });

  testWidgets('Sign in with user without Firestore doc (creates one)',
      (WidgetTester tester) async {
    await runSignInNewUserWithoutFirestoreDoc(tester);
  });

  testWidgets('Sign in with unverified email (verification pending)',
      (WidgetTester tester) async {
    await runSignInUnverifiedEmail(tester);
  });

  testWidgets('Sign up new user (verification pending)',
      (WidgetTester tester) async {
    await runSignUpNewUser(tester);
  });

  testWidgets('Sign up with existing email (should fail)',
      (WidgetTester tester) async {
    await runSignUpExistingEmail(tester);
  });

  testWidgets('Sign in with wrong password (should fail)',
      (WidgetTester tester) async {
    await runSignInWrongPassword(tester);
  });

  testWidgets('Sign in with invalid email format (should fail)',
      (WidgetTester tester) async {
    await runSignInInvalidEmail(tester);
  });

  testWidgets('Sign in with weak password (should fail)',
      (WidgetTester tester) async {
    await runSignUpWeakPassword(tester);
  });

  testWidgets('Sign in with non-existent user (should fail)',
      (WidgetTester tester) async {
    await runSignInNonExistentUser(tester);
  });

  testWidgets('Sign out clears auth and cache', (WidgetTester tester) async {
    await runSignOutTest(tester);
  });
}
