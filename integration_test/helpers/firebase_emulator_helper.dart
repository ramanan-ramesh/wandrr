import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/auth/models/auth_type.dart';

/// Helper class to configure Firebase to use local emulators for integration tests
class FirebaseEmulatorHelper {
  // Emulator configuration
  // For Android emulator: use 10.0.2.2 (maps to host machine's localhost)
  // For iOS simulator or web: use localhost/127.0.0.1
  static const String _emulatorHost = '10.0.2.2';
  static const int _authEmulatorPort = 9099;
  static const int _firestoreEmulatorPort = 8080;

  static bool _isConfigured = false;

  /// Configure Firebase services to use emulators
  /// Call this AFTER Firebase.initializeApp() but BEFORE any Firebase operations
  static Future<void> configureEmulators({
    String? customHost,
    int? customAuthPort,
    int? customFirestorePort,
  }) async {
    if (_isConfigured) {
      if (kDebugMode) {
        print('✓ Firebase emulators already configured');
      }
      return;
    }

    final host = customHost ?? _emulatorHost;
    final authPort = customAuthPort ?? _authEmulatorPort;
    final firestorePort = customFirestorePort ?? _firestoreEmulatorPort;

    try {
      // Configure Firebase Auth to use emulator
      await FirebaseAuth.instance.useAuthEmulator(host, authPort);
      if (kDebugMode) {
        print('✓ Firebase Auth emulator configured: $host:$authPort');
      }

      // Configure Firestore to use emulator
      FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
      if (kDebugMode) {
        print('✓ Firestore emulator configured: $host:$firestorePort');
      }

      _isConfigured = true;
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error configuring emulators: $e');
      }
      rethrow;
    }
  }

  /// Check if emulators are configured
  static bool get isConfigured => _isConfigured;

  /// Reset configuration flag (useful for testing)
  static void reset() {
    _isConfigured = false;
  }

  /// Setup test data - creates test user
  static Future<void> createFirebaseAuthUser({
    required String email,
    required String password,
    required bool shouldAddToFirestore,
    required bool shouldSignIn,
  }) async {
    // Create test user in Firebase Auth
    await _createVerifiedTestUser(
      email: email,
      password: password,
    );

    // Create user document in Firestore
    if (shouldAddToFirestore) {
      await _createTestUserDocument(email: email);
    }

    if (!shouldSignIn) {
      try {
        // Sign out after setup
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        if (kDebugMode) {
          print('✗ Error while signing out: $e');
        }
        rethrow;
      }
    } else {
      final sharedPreferences = await SharedPreferences.getInstance();
      if (shouldSignIn) {
        await sharedPreferences.setString(
            'authType', AuthenticationType.emailPassword.name);
      }
    }

    if (kDebugMode) {
      print('--- Test data setup complete ---\n');
    }
  }

  /// Complete cleanup - signs out user and clears all Firestore data
  /// Call this in tearDown() after each test
  static Future<void> cleanupAfterTest() async {
    try {
      if (kDebugMode) {
        print('\n🧹 Cleaning up after test...');
      }

      // Sign out any authenticated user
      await signOutCurrentUser();
      await clearAllAuthenticatedUsers();

      // Clear all Firestore data
      await clearAllFirestoreData();

      if (kDebugMode) {
        print('✓ Test cleanup complete\n');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('✗ Error during test cleanup: $e');
      }
    }
  }

  /// This is required because the emulator doesn't automatically verify emails
  /// and user_management.dart checks emailVerified status
  ///
  /// [email] - The email address of the user to verify (must be signed in)
  /// Returns true if verification was successful
  /// Manually verify email using Firebase Auth Emulator Admin REST API
  /// This uses admin privileges to set emailVerified=true
  static Future _verifyEmailInEmulator(String email) async {
    try {
      const host = _emulatorHost;
      const port = _authEmulatorPort;

      // Get current user details (must be signed in)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print('✗ No current user to verify email for');
        }
        return;
      }

      final uid = currentUser.uid;
      if (kDebugMode) {
        print('  → Verifying email for: $email');
      }

      const updateUrl =
          'http://$host:$port/identitytoolkit.googleapis.com/v1/accounts:update?key=wandrr-15f70';

      // Admin request body: Use localId (UID) + emailVerified
      final updateResponse = await http.post(
        Uri.parse(updateUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer owner', // Key: Emulator admin token
        },
        body: json.encode({
          'localId': uid,
          'emailVerified': true,
        }),
      );

      if (updateResponse.statusCode == 200) {
        if (kDebugMode) {
          print('✓ Email verified in emulator via Admin REST API: $email');
        }
        return;
      } else {
        if (kDebugMode) {
          print('✗ Admin update failed: ${updateResponse.statusCode}');
          print('   Response: ${updateResponse.body}');
        }
        throw Exception('Error verifying email in emulator');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('✗ Error verifying email in emulator: $e');
      }
      throw Exception('Error verifying email in emulator');
    }
  }

  /// Create a test user in Firebase Auth emulator
  /// Uses Firebase Auth Emulator REST API to manually verify email
  /// This ensures user_management.dart's emailVerified checks pass
  static Future _createVerifiedTestUser({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('✗ Error creating test user: ${e.code}');
      }
      throw Exception('Error creating test user: ${e.message}');
    }

    if (kDebugMode) {
      print('✓ Test user created: $email');
    }

    await _verifyEmailInEmulator(email);

    try {
      await FirebaseAuth.instance.currentUser!.reload();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('✗ Error reloading user: ${e.message}');
      }
      rethrow;
    }
  }

  /// Create test user document in Firestore
  static Future<void> _createTestUserDocument({required String email}) async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    // Check if user document already exists
    final querySnapshot =
        await usersRef.where('userName', isEqualTo: email).get();

    if (querySnapshot.docs.isEmpty) {
      // Create new user document
      await usersRef.add({
        'userName': email,
        'authType': AuthenticationType.emailPassword.name,
      });

      if (kDebugMode) {
        print('✓ Test user document created in Firestore: $email');
      }
    } else {
      if (kDebugMode) {
        print('ℹ Test user document already exists: $email');
      }
    }
  }

  /// Sign out current user if signed in
  static Future<void> signOutCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('Signing out current user...');
      await FirebaseAuth.instance.signOut();
      if (kDebugMode) {
        print('✓ Signed out user: ${currentUser.email}');
      }
    }
  }

  /// Clear ALL users from Firebase Auth emulator via REST API
  /// This flushes the entire emulated Auth database for test isolation
  static Future clearAllAuthenticatedUsers() async {
    try {
      if (kDebugMode) {
        print('\n--- Clearing ALL Auth users ---');
      }

      const host = _emulatorHost; // '10.0.2.2' for Android emulator
      const port = _authEmulatorPort; // 9099
      const projectId = 'wandrr-15f70'; // From your firebase.json

      // Emulator-specific endpoint to flush/clear all user records
      const clearUrl =
          'http://$host:$port/emulator/v1/projects/$projectId/accounts';

      final response = await http.delete(
        Uri.parse(clearUrl),
        headers: {
          'Authorization': 'Bearer owner', // Admin access for emulator
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✓ ALL Auth users cleared successfully');
        }
      } else {
        if (kDebugMode) {
          print('✗ Failed to clear Auth users: ${response.statusCode}');
          print('   Response: ${response.body}');
        }
        throw Exception('Failed to clear Auth users');
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error clearing Auth users: $e');
      }
      rethrow;
    }
  }

  /// Clear all Firestore data by calling the emulator's REST flush endpoint.
  ///
  /// Using `collectionReference.get()` from the SDK hangs during teardown
  /// because the app is still holding active stream listeners on those
  /// collections.  The emulator exposes a dedicated HTTP DELETE endpoint that
  /// wipes all documents atomically without going through the SDK.
  static Future<void> clearAllFirestoreData() async {
    try {
      if (kDebugMode) {
        print('\n--- Clearing Firestore data ---');
      }

      const host = _emulatorHost;
      const port = _firestoreEmulatorPort;
      const projectId = 'wandrr-15f70';

      // DELETE /emulator/v1/projects/{project}/databases/(default)/documents
      // clears every document in the emulated Firestore database.
      const clearUrl =
          'http://$host:$port/emulator/v1/projects/$projectId/databases/(default)/documents';

      final response = await http.delete(Uri.parse(clearUrl));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✓ Firestore cleanup complete (all documents wiped)');
        }
      } else {
        if (kDebugMode) {
          print(
              '✗ Failed to clear Firestore data: ${response.statusCode} ${response.body}');
        }
        throw Exception(
            'Firestore emulator flush failed: ${response.statusCode}');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('✗ Error clearing Firestore data: $e');
      }
      // Do not rethrow – a cleanup failure must not mask the real test result.
    }
  }
}
