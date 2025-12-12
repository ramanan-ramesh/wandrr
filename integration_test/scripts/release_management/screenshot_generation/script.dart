import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_emulator_helper.dart';
import 'phone.dart';
import 'tablet.dart';
import 'test_config.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Get device type from dart-define parameter
  const deviceType = String.fromEnvironment('DEVICE_TYPE', defaultValue: 'all');

  group('Wandrr Travel Planner Integration Tests', () {
    late SharedPreferences sharedPreferences;

    setUpAll(() async {
      print('🚀 Starting integration tests for: $deviceType');
      print(
          '📍 Firebase Auth Emulator: ${const String.fromEnvironment('FIREBASE_AUTH_EMULATOR_HOST', defaultValue: '10.0.2.2:9099')}');
      print(
          '📍 Firestore Emulator: ${const String.fromEnvironment('FIRESTORE_EMULATOR_HOST', defaultValue: '10.0.2.2:8080')}');

      sharedPreferences = await SharedPreferences.getInstance();

      try {
        print('⏳ Initializing Firebase...');
        await Firebase.initializeApp().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception(
                'Firebase initialization timed out after 10 seconds');
          },
        );
        print('✓ Firebase initialized');
      } catch (e) {
        print('⚠️ Firebase already initialized or initialization skipped: $e');
      }

      // Check emulator connectivity before proceeding
      final emulatorsAccessible =
          await FirebaseEmulatorHelper.checkEmulatorConnectivity();
      if (!emulatorsAccessible) {
        throw Exception('❌ Firebase emulators are not accessible. '
            'Please ensure emulators are running and the correct host is configured.\n'
            'Expected: Auth at ${const String.fromEnvironment('FIREBASE_AUTH_EMULATOR_HOST', defaultValue: '10.0.2.2:9099')}, '
            'Firestore at ${const String.fromEnvironment('FIRESTORE_EMULATOR_HOST', defaultValue: '10.0.2.2:8080')}');
      }

      try {
        print('⏳ Configuring Firebase emulators...');
        await FirebaseEmulatorHelper.configureEmulators();
        print('✓ Firebase emulators configured');

        print('⏳ Creating test user...');
        await FirebaseEmulatorHelper.createFirebaseAuthUser(
          email: TestConfig.testEmail,
          password: TestConfig.testEmail,
          shouldAddToFirestore: true,
          shouldSignIn: true,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception(
                'Creating Firebase Auth user timed out after 30 seconds. Check if emulators are running and accessible.');
          },
        );
        print('✓ Test user created');

        print('⏳ Creating test trip data...');
        await TestHelpers.createTestTrip().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception(
                'Creating test trip timed out after 30 seconds. Check if Firestore emulator is accessible.');
          },
        );
        print('✓ Test trip created');

        print('✅ All setup complete - ready to run tests');
      } catch (e, stackTrace) {
        print('❌ Setup failed: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    });

    tearDownAll(() async {
      print('🧹 Starting cleanup...');
      try {
        await FirebaseEmulatorHelper.cleanupAfterTest().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('⚠️ Cleanup timed out after 30 seconds');
          },
        );
        await sharedPreferences.clear();
        FirebaseEmulatorHelper.reset();
        print('✓ Cleanup complete');
      } catch (e) {
        print('⚠️ Cleanup error (non-fatal): $e');
      }
    });

    // Run phone tests only if device type is 'phone' or 'all'
    if (deviceType == 'phone' || deviceType == 'all') {
      testWidgets('generate screenshots for phone',
          (WidgetTester tester) async {
        print('📱 Generating screenshots for phone...');
        await generateScreenshotsForPhone(tester);
        print('✓ Phone screenshots generated');
      }, timeout: const Timeout(Duration(minutes: 10)));
    }

    // Run tablet tests only if device type is 'tablet' or 'all'
    if (deviceType == 'tablet' || deviceType == 'all') {
      testWidgets('generate screenshots for tablet',
          (WidgetTester tester) async {
        print('📱 Generating screenshots for tablet...');
        await generateScreenshotsForTablet(tester);
        print('✓ Tablet screenshots generated');
      }, timeout: const Timeout(Duration(minutes: 10)));
    }
  });
}
