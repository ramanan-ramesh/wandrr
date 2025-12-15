import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/firebase_emulator_helper.dart';
import '../helpers/mock_location_api_service.dart';
import '../helpers/test_config.dart';
import '../helpers/test_helpers.dart';
import 'capturer.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences sharedPreferences;

  group('Screenshot Capturer', () {
    setUpAll(() async {
      sharedPreferences = await SharedPreferences.getInstance();
      try {
        await Firebase.initializeApp();
      } catch (e) {
        print('Firebase already initialized or initialization skipped: $e');
      }
      await FirebaseEmulatorHelper.configureEmulators();
      print('✓ Firebase emulators configured for integration tests');
      await FirebaseEmulatorHelper.createFirebaseAuthUser(
        email: TestConfig.testEmail,
        password: TestConfig.testPassword,
        shouldAddToFirestore: true,
        shouldSignIn: true,
      );
      // Initialize mock location API service to intercept HTTP requests
      // Note: This creates a MockClient that can be injected into GeoLocator
      await MockLocationApiService.initialize();
      await TestHelpers.createTestTrip();
    });

    tearDownAll(() async {
      await FirebaseEmulatorHelper.cleanupAfterTest();
      FirebaseEmulatorHelper.reset();
      await sharedPreferences.clear();
    });

    testWidgets('Capturing screenshots', (WidgetTester tester) async {
      await runScreenshotCapturer(tester, binding);
    });
  });
}
