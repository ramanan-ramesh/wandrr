import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/auth/models/auth_type.dart';
import 'package:wandrr/data/trip/implementations/api_services/constants.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';

/// Helper class to configure Firebase to use local emulators for integration tests

class FirebaseEmulatorHelper {
  // Emulator configuration
  // For Android emulator: use 10.0.2.2 (maps to host machine's localhost)
  // For iOS simulator or web: use localhost/127.0.0.1
  // Can be overridden via dart-define: FIREBASE_AUTH_EMULATOR_HOST and FIRESTORE_EMULATOR_HOST
  static String get _defaultEmulatorHost {
    // Parse from dart-define if provided (format: "host:port")
    const authEmulatorEnv =
        String.fromEnvironment('FIREBASE_AUTH_EMULATOR_HOST', defaultValue: '');
    if (authEmulatorEnv.isNotEmpty && authEmulatorEnv.contains(':')) {
      return authEmulatorEnv.split(':')[0];
    }
    return '10.0.2.2'; // Default for Android emulator
  }

  static int get _defaultAuthPort {
    const authEmulatorEnv =
        String.fromEnvironment('FIREBASE_AUTH_EMULATOR_HOST', defaultValue: '');
    if (authEmulatorEnv.isNotEmpty && authEmulatorEnv.contains(':')) {
      return int.tryParse(authEmulatorEnv.split(':')[1]) ?? 9099;
    }
    return 9099;
  }

  static int get _defaultFirestorePort {
    const firestoreEmulatorEnv =
        String.fromEnvironment('FIRESTORE_EMULATOR_HOST', defaultValue: '');
    if (firestoreEmulatorEnv.isNotEmpty && firestoreEmulatorEnv.contains(':')) {
      return int.tryParse(firestoreEmulatorEnv.split(':')[1]) ?? 8080;
    }
    return 8080;
  }

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

    final host = customHost ?? _defaultEmulatorHost;
    final authPort = customAuthPort ?? _defaultAuthPort;
    final firestorePort = customFirestorePort ?? _defaultFirestorePort;

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

  /// Check if emulators are accessible
  /// Returns true if both Auth and Firestore emulators respond, false otherwise
  static Future<bool> checkEmulatorConnectivity() async {
    final host = _defaultEmulatorHost;
    final authPort = _defaultAuthPort;
    final firestorePort = _defaultFirestorePort;

    try {
      print('🔍 Checking Firebase emulator connectivity...');
      print('   Auth emulator: http://$host:$authPort');
      print('   Firestore emulator: http://$host:$firestorePort');

      // Check Auth emulator
      try {
        final authResponse = await http
            .get(
              Uri.parse('http://$host:$authPort'),
            )
            .timeout(const Duration(seconds: 5));

        if (authResponse.statusCode == 200 || authResponse.statusCode == 404) {
          print('✓ Auth emulator is accessible');
        } else {
          print('⚠️ Auth emulator returned status: ${authResponse.statusCode}');
          return false;
        }
      } catch (e) {
        print('❌ Auth emulator is NOT accessible: $e');
        return false;
      }

      // Check Firestore emulator
      try {
        final firestoreResponse = await http
            .get(
              Uri.parse('http://$host:$firestorePort'),
            )
            .timeout(const Duration(seconds: 5));

        if (firestoreResponse.statusCode == 200 ||
            firestoreResponse.statusCode == 404) {
          print('✓ Firestore emulator is accessible');
        } else {
          print(
              '⚠️ Firestore emulator returned status: ${firestoreResponse.statusCode}');
          return false;
        }
      } catch (e) {
        print('❌ Firestore emulator is NOT accessible: $e');
        return false;
      }

      print('✅ All emulators are accessible');
      return true;
    } catch (e) {
      print('❌ Error checking emulator connectivity: $e');
      return false;
    }
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
      await _signOutCurrentUser();
      await _clearAllAuthUsers();

      // Clear all Firestore data
      await _clearAllFirestoreData();

      if (kDebugMode) {
        print('✓ Test cleanup complete\n');
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error during test cleanup: $e');
      }
    }
  }

  /// Manually verify email using Firebase Auth Emulator's internal REST API
  /// This is required because the emulator doesn't automatically verify emails
  /// and user_management.dart checks emailVerified status
  ///
  /// [user] - The Firebase User object to verify (must be signed in)
  /// Returns true if verification was successful
  /// Manually verify email using Firebase Auth Emulator Admin REST API
  /// This uses admin privileges to set emailVerified=true
  static Future _verifyEmailInEmulator(String email) async {
    try {
      final host = _defaultEmulatorHost;
      final port = _defaultAuthPort;

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

      final updateUrl =
          'http://$host:$port/identitytoolkit.googleapis.com/v1/accounts:update?key=wandrr-15f70';

      // Admin request body: Use localId (UID) + emailVerified
      final updateResponse = await http
          .post(
        Uri.parse(updateUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer owner', // Key: Emulator admin token
        },
        body: json.encode({
          'localId': uid,
          'emailVerified': true,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Timeout: Could not connect to Firebase Auth emulator at $host:$port');
        },
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
    } catch (e) {
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
  static Future<void> _signOutCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseAuth.instance.signOut();
      if (kDebugMode) {
        print('✓ Signed out user: ${currentUser.email}');
      }
    }
  }

  /// Clear ALL users from Firebase Auth emulator via REST API
  /// This flushes the entire emulated Auth database for test isolation
  static Future _clearAllAuthUsers() async {
    try {
      if (kDebugMode) {
        print('\n--- Clearing ALL Auth users ---');
      }

      final host =
          _defaultEmulatorHost; // Dynamic based on dart-define or default '10.0.2.2'
      final port =
          _defaultAuthPort; // Dynamic based on dart-define or default 9099
      const projectId = 'wandrr-15f70'; // From your firebase.json

      // Emulator-specific endpoint to flush/clear all user records
      final clearUrl =
          'http://$host:$port/emulator/v1/projects/$projectId/accounts';

      final response = await http.delete(
        Uri.parse(clearUrl),
        headers: {
          'Authorization': 'Bearer owner', // Admin access for emulator
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Timeout: Could not connect to Firebase Auth emulator at $host:$port');
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

  /// Clear all Firestore data from specific collections
  /// Note: Firebase Auth emulator doesn't allow deleting users via SDK,
  /// but they are cleared when emulator restarts
  static Future<void> _clearAllFirestoreData() async {
    try {
      if (kDebugMode) {
        print('\n--- Clearing Firestore data ---');
      }

      final firestore = FirebaseFirestore.instance;

      // List of collections to clear
      final collectionsToDelete = [
        'users',
        FirestoreCollections.appConfig,
        Constants.apiServicesCollectionName,
        FirestoreCollections.tripMetadataCollectionName,
        FirestoreCollections.tripCollectionName,
        FirestoreCollections.expenseCollectionName,
        FirestoreCollections.itineraryDataCollectionName,
        FirestoreCollections.lodgingCollectionName,
        FirestoreCollections.transitCollectionName,
      ];

      int totalDeleted = 0;

      for (final collectionName in collectionsToDelete) {
        try {
          final snapshot = await firestore.collection(collectionName).get();

          if (snapshot.docs.isNotEmpty) {
            // Delete all documents in batches
            final batch = firestore.batch();
            int batchCount = 0;

            for (final doc in snapshot.docs) {
              batch.delete(doc.reference);
              batchCount++;
              totalDeleted++;

              // Firestore batch limit is 500
              if (batchCount >= 500) {
                await batch.commit();
                batchCount = 0;
              }
            }

            // Commit remaining deletes
            if (batchCount > 0) {
              await batch.commit();
            }

            if (kDebugMode) {
              print(
                  '  ✓ Deleted ${snapshot.docs.length} documents from $collectionName');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('  ⚠ Error deleting $collectionName: $e');
          }
        }
      }

      if (kDebugMode) {
        print('✓ Firestore cleanup complete: $totalDeleted documents deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error clearing Firestore data: $e');
      }
    }
  }
}
