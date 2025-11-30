import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fake_firebase_remote_config/fake_firebase_remote_config.dart'; // Optional, for unit tests
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock setup for Firebase services
/// - firebase_auth_mocks for Auth
/// - fake_cloud_firestore for Firestore
/// - MethodChannel mocks for Core + Remote Config (for integration tests)
class MockFirebaseSetup {
  static bool _initialized = false;
  static FakeRemoteConfig? _fakeRemoteConfig; // For unit tests only

  /// Initialize mock Firebase
  static Future<void> setupFirebaseMocks({
    Map<String, dynamic> remoteConfigDefaults =
        const {}, // e.g., {'latest_version': '3.0.1+16'}
    bool enableDebugLogs =
        false, // Optional: Print channel calls for troubleshooting
  }) async {
    if (_initialized) return;

    TestWidgetsFlutterBinding
        .ensureInitialized(); // Or IntegrationTestWidgetsFlutterBinding if in integration_test

    // Setup channel mocks FIRST (before Firebase.init)
    setupFirebaseCoreChannelMock(enableDebugLogs: enableDebugLogs);
    setupRemoteConfigChannelMock(
        defaults: remoteConfigDefaults, enableDebugLogs: enableDebugLogs);

    // SKIP platform override to allow channel calls
    // setupFirebaseCorePlatform();  // <-- Commented out to ensure channel is hit

    try {
      // Now initialize (uses mocks via channel)
      await Firebase.initializeApp();
    } catch (e) {
      print('Firebase initialization warning: $e');
    }

    // Optional: Setup fake for unit tests
    await _setupRemoteConfigUnitTestOnly();

    _initialized = true;
  }

  /// Mock Firebase Core MethodChannel with CORRECT pluginConstants keys/values
  /// This is now called during Firebase.initializeApp()
  static void setupFirebaseCoreChannelMock({bool enableDebugLogs = false}) {
    const MethodChannel firebaseChannel =
        MethodChannel('plugins.flutter.io/firebase_core');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseChannel, (MethodCall call) async {
      if (enableDebugLogs) print('Core Channel called: ${call.method}');
      switch (call.method) {
        case 'Firebase#initializeCore':
          return <dynamic>[
            <String, dynamic>{
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'fake-api-key',
                'appId': 'fake-app-id',
                'messagingSenderId': 'fake-sender-id',
                'projectId': 'fake-project-id',
              },
              'pluginConstants': {
                'plugins.flutter.io/firebase_remote_config': {
                  'fetchTimeout': 10, // Seconds (int) - fixes Duration cast
                  'minimumFetchInterval': 3600, // 1 hour in seconds (int)
                  'lastFetchTime': 0, // Milliseconds (int)
                  'throttleEndTimeInMillis':
                      0, // Additional potential key (int millis)
                  'lastFetchStatus':
                      1, // int for RemoteConfigFetchStatus.success
                  'parameters': <String, dynamic>{}, // Initial params
                },
              },
            },
          ];
        case 'Firebase#initializeApp':
          // Return full constants for safety (overrides potentially empty args)
          return <String, dynamic>{
            'name': call.arguments['appName'] ?? '[DEFAULT]',
            'options': call.arguments['options'] ??
                {
                  'apiKey': 'fake-api-key',
                  'appId': 'fake-app-id',
                  'messagingSenderId': 'fake-sender-id',
                  'projectId': 'fake-project-id',
                },
            'pluginConstants': {
              'plugins.flutter.io/firebase_remote_config': {
                'fetchTimeout': 10,
                'minimumFetchInterval': 3600,
                'lastFetchTime': 0,
                'throttleEndTimeInMillis': 0,
                'lastFetchStatus': 1,
                'parameters': <String, dynamic>{},
              },
            },
          };
        default:
          throw UnimplementedError(
              'Core method ${call.method} not implemented.');
      }
    });
  }

  /// Mock Firebase Remote Config MethodChannel
  static void setupRemoteConfigChannelMock({
    Map<String, dynamic> defaults = const {},
    bool enableDebugLogs = false,
  }) {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/firebase_remote_config');
    final Map<String, dynamic> _mockValues = {...defaults};

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (enableDebugLogs)
        print('Remote Config Channel: ${call.method} args: ${call.arguments}');
      switch (call.method) {
        case 'setConfigSettings':
          return null; // No-op
        case 'setDefaults':
          final Map<dynamic, dynamic> incoming =
              call.arguments['defaults'] ?? {};
          _mockValues.addAll(Map<String, dynamic>.from(incoming));
          return null;
        case 'fetch':
          return <String, dynamic>{'status': 1}; // int success
        case 'activateFetched':
          return true;
        case 'getStringValue':
          final String key = call.arguments['key'] as String;
          return _mockValues[key]?.toString() ?? '';
        case 'getIntValue':
          final String key = call.arguments['key'] as String;
          return _mockValues[key] is int ? _mockValues[key] : 0;
        case 'getDoubleValue':
          final String key = call.arguments['key'] as String;
          return _mockValues[key] is double ? _mockValues[key] : 0.0;
        case 'getBooleanValue':
          final String key = call.arguments['key'] as String;
          return _mockValues[key] is bool ? _mockValues[key] : false;
        case 'getLastFetchTime':
          return DateTime.now().millisecondsSinceEpoch;
        case 'getLastFetchStatus':
          return 1; // int success
        default:
          throw UnimplementedError(
              'RemoteConfig method ${call.method} not implemented.');
      }
    });
  }

  /// Optional: Setup FakeRemoteConfig for unit/widget tests (requires DI)
  static Future<void> _setupRemoteConfigUnitTestOnly() async {
    try {
      _fakeRemoteConfig = FakeRemoteConfig();
      await _fakeRemoteConfig!.setDefaults({
        'latest_version': '3.0.1+16',
        'min_version': '3.0.1+16',
        'release_notes': 'Test release notes',
        // Add more as needed
      });
    } catch (e) {
      print('Unit-test-only Remote Config setup warning: $e');
    }
  }

  /// Get the fake Remote Config instance (for unit tests)
  static FakeRemoteConfig? getFakeRemoteConfig() {
    return _fakeRemoteConfig;
  }

  /// Get mock Firebase Auth instance
  static MockFirebaseAuth getMockAuth({
    bool isSignedIn = false,
    MockUser? mockUser,
  }) {
    final user = mockUser ??
        MockUser(
          uid: 'test_user_id',
          email: 'test@example.com',
          displayName: 'Test User',
        );

    return MockFirebaseAuth(
      signedIn: isSignedIn,
      mockUser: user,
    );
  }

  /// Get mock Firestore instance
  static FakeFirebaseFirestore getMockFirestore() {
    return FakeFirebaseFirestore();
  }

  /// Setup mock user authentication
  static Future<MockFirebaseAuth> setupAuthenticatedUser({
    String? uid,
    String? email,
    String? displayName,
  }) async {
    await setupFirebaseMocks();

    final mockUser = MockUser(
      uid: uid ?? 'test_user_id',
      email: email ?? 'test@example.com',
      displayName: displayName ?? 'Test User',
      isEmailVerified: true,
    );

    return MockFirebaseAuth(
      signedIn: true,
      mockUser: mockUser,
    );
  }

  /// Setup mock Firestore with test data
  static Future<FakeFirebaseFirestore> setupFirestoreWithData({
    Map<String, dynamic>? userData,
    List<Map<String, dynamic>>? trips,
  }) async {
    await setupFirebaseMocks();

    final firestore = FakeFirebaseFirestore();

    // Add user data if provided
    if (userData != null) {
      await firestore.collection('users').doc('test_user_id').set(userData);
    }

    // Add trips if provided
    if (trips != null) {
      for (var i = 0; i < trips.length; i++) {
        await firestore.collection('trips').doc('trip_$i').set(trips[i]);
      }
    }

    return firestore;
  }

  /// Reset all mocks
  static void reset() {
    _initialized = false;
    _fakeRemoteConfig = null;
    // Reset channels using the non-deprecated API
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/firebase_core'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/firebase_remote_config'),
            null);
  }
}
