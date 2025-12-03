import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

  /// Get the emulator host based on platform
  static String getEmulatorHost() {
    // For Android emulator, use 10.0.2.2
    // For iOS simulator or web, use localhost
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    } else {
      return 'localhost';
    }
  }

  /// Create a test user in Firebase Auth emulator
  static Future<UserCredential?> _createTestUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (kDebugMode) {
        print('✓ Test user created: $email');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('✗ Error creating test user: ${e.message}');
      return null;
    }
  }

  /// Create test user document in Firestore
  static Future<void> _createTestUserDocument({
    required String email,
    required String userId,
  }) async {
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');

      // Check if user document already exists
      final querySnapshot =
          await usersRef.where('userName', isEqualTo: email).get();

      if (querySnapshot.docs.isEmpty) {
        // Create new user document
        await usersRef.add({
          'userName': email,
          'authType': 'emailPassword',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          print('✓ Test user document created in Firestore: $email');
        }
      } else {
        if (kDebugMode) {
          print('ℹ Test user document already exists: $email');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error creating test user document: $e');
      }
      rethrow;
    }
  }

  /// Setup test data - creates test user
  static Future<void> createFirebaseAuthUser({
    required String email,
    required String password,
    required bool shouldAddToFirestore,
  }) async {
    try {
      // Create test user in Firebase Auth
      final userCredential = await _createTestUser(
        email: email,
        password: password,
      );

      if (userCredential != null &&
          userCredential.user != null &&
          shouldAddToFirestore) {
        // Create user document in Firestore
        await _createTestUserDocument(
          email: email,
          userId: userCredential.user!.uid,
        );

        // Sign out after setup
        await FirebaseAuth.instance.signOut();

        if (kDebugMode) {
          print('--- Test data setup complete ---\n');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error setting up test data: $e');
      }
      rethrow;
    }
  }

  /// Clear all test data from emulators
  static Future<void> clearTestData() async {
    try {
      // Sign out current user
      await FirebaseAuth.instance.signOut();

      if (kDebugMode) {
        print('✓ User signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error clearing test data: $e');
      }
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
        'trips',
        'transits',
        'stays',
        'expenses',
        'sights',
        'notes',
        'checklists',
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

  /// Sign out current user if signed in
  static Future<void> _signOutCurrentUser() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseAuth.instance.signOut();
        if (kDebugMode) {
          print('✓ Signed out user: ${currentUser.email}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error signing out: $e');
      }
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

  /// Delete specific Firestore collection
  static Future<void> deleteCollection(String collectionName) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection(collectionName).get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        print(
            '✓ Deleted ${snapshot.docs.length} documents from $collectionName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error deleting collection $collectionName: $e');
      }
    }
  }

  /// Get count of documents in a collection (for verification)
  static Future<int> getCollectionDocumentCount(String collectionName) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection(collectionName).get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error getting document count for $collectionName: $e');
      }
      return 0;
    }
  }

  /// Verify cleanup was successful
  static Future<bool> verifyCleanup() async {
    try {
      // Check if user is signed out
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        if (kDebugMode) {
          print('✗ User still signed in: ${currentUser.email}');
        }
        return false;
      }

      // Check if Firestore collections are empty
      final collections = ['users', 'trips', 'expenses'];
      for (final collection in collections) {
        final count = await getCollectionDocumentCount(collection);
        if (count > 0) {
          if (kDebugMode) {
            print('✗ Collection $collection still has $count documents');
          }
          return false;
        }
      }

      if (kDebugMode) {
        print('✓ Cleanup verification passed');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error verifying cleanup: $e');
      }
      return false;
    }
  }
}
