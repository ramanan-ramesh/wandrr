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
      sharedPreferences = await SharedPreferences.getInstance();
      try {
        await Firebase.initializeApp();
      } catch (e) {
        print('Firebase already initialized or initialization skipped: $e');
      }
      await FirebaseEmulatorHelper.configureEmulators();
      await FirebaseEmulatorHelper.createFirebaseAuthUser(
        email: TestConfig.testEmail,
        password: TestConfig.testEmail,
        shouldAddToFirestore: true,
        shouldSignIn: true,
      );
      await TestHelpers.createTestTrip();
      print('✓ Firebase emulators configured for integration tests');
    });

    tearDownAll(() async {
      await FirebaseEmulatorHelper.cleanupAfterTest();
      await sharedPreferences.clear();
      FirebaseEmulatorHelper.reset();
    });

    // Run phone tests only if device type is 'phone' or 'all'
    if (deviceType == 'phone' || deviceType == 'all') {
      testWidgets('generate screenshots for phone',
          (WidgetTester tester) async {
        print('📱 Generating screenshots for phone...');
        await generateScreenshotsForPhone(tester);
        print('✓ Phone screenshots generated');
      });
    }

    // Run tablet tests only if device type is 'tablet' or 'all'
    if (deviceType == 'tablet' || deviceType == 'all') {
      testWidgets('generate screenshots for tablet',
          (WidgetTester tester) async {
        print('📱 Generating screenshots for tablet...');
        await generateScreenshotsForTablet(tester);
        print('✓ Tablet screenshots generated');
      });
    }
  });
}
