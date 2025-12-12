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

  group('Wandrr Travel Planner Integration Tests', () {
    late SharedPreferences sharedPreferences;

    setUpAll(() async {
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

    testWidgets('generate screenshots for phone', (WidgetTester tester) async {
      await generateScreenshotsForPhone(tester);
    });

    testWidgets('generate screenshots for tablets',
        (WidgetTester tester) async {
      await generateScreenshotsForTablet(tester);
    });
  });
}
