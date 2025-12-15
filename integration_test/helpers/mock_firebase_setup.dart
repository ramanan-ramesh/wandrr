import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock setup for Firebase services
/// - firebase_auth_mocks for Auth
/// - fake_cloud_firestore for Firestore
/// - MethodChannel mocks for Core + Remote Config (for integration tests)
class MockFirebaseSetup {
  static bool _initialized = false;

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

  /// Reset all mocks
  static void reset() {
    _initialized = false;
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
