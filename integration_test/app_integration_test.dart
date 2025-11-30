import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mock_firebase_setup.dart';
import 'helpers/test_helpers.dart';
import 'tests/home_page_test.dart';
import 'tests/login_page_test.dart';
import 'tests/startup_page_test.dart';
import 'tests/trip_editor_page_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Wandrr Travel Planner Integration Tests', () {
    late SharedPreferences sharedPreferences;

    setUpAll(() async {
      // Initialize Firebase before any tests run
      await MockFirebaseSetup.setupFirebaseMocks(
        remoteConfigDefaults: {
          'latest_version': '3.0.1+16',
          // Matches your pubspec to avoid update logic
          'min_version': '3.0.1+16',
          'release_notes': 'Test notes',
          // Add other keys used in MasterPageBloc, e.g., 'welcome_message': 'Test'
        },
        enableDebugLogs: true,
      );
    });

    setUp(() async {
      // Reset shared preferences for each test
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.clear();
    });

    tearDownAll(() async {
      MockFirebaseSetup.reset();
    });

    group('Startup Page Tests', () {
      testWidgets(
          'displays OnboardingPage and LoginPage side by side when screen width > 1000',
          (WidgetTester tester) async {
        await runStartupPageLargeScreenTest(tester, sharedPreferences);
      });

      testWidgets(
          'displays OnboardingPage with next button when screen width < 1000',
          (WidgetTester tester) async {
        await runStartupPageSmallScreenTest(tester, sharedPreferences);
      });

      testWidgets('navigates to LoginPage on clicking next button',
          (WidgetTester tester) async {
        await runStartupPageNavigationTest(tester, sharedPreferences);
      });
    });

    group('Login Page Tests', () {
      testWidgets(
          'authenticates with username and password and navigates to HomePage',
          (WidgetTester tester) async {
        await runLoginAuthenticationTest(tester, sharedPreferences);
      });

      testWidgets('displays rive animation during authentication',
          (WidgetTester tester) async {
        await runLoginAnimationTest(tester, sharedPreferences);
      });
    });

    group('Home Page Tests', () {
      setUp(() async {
        // Setup authenticated state for HomePage tests
        await TestHelpers.setupAuthenticatedState(sharedPreferences);
      });

      testWidgets('sets isBigLayout to true when screen width >= 1000',
          (WidgetTester tester) async {
        await runHomePageLayoutLargeTest(tester, sharedPreferences);
      });

      testWidgets('sets isBigLayout to false when screen width < 1000',
          (WidgetTester tester) async {
        await runHomePageLayoutSmallTest(tester, sharedPreferences);
      });

      testWidgets('displays no trips initially in TripsListView',
          (WidgetTester tester) async {
        await runHomePageEmptyTripsTest(tester, sharedPreferences);
      });

      testWidgets('updates locale when language is selected from toolbar',
          (WidgetTester tester) async {
        await runHomePageLanguageSwitchTest(tester, sharedPreferences);
      });

      testWidgets('updates theme mode when theme switcher is toggled',
          (WidgetTester tester) async {
        await runHomePageThemeSwitchTest(tester, sharedPreferences);
      });

      testWidgets('navigates to StartupPage on logout',
          (WidgetTester tester) async {
        await runHomePageLogoutTest(tester, sharedPreferences);
      });

      testWidgets('shows trip creator dialog on clicking Plan a Trip button',
          (WidgetTester tester) async {
        await runHomePageCreateTripDialogTest(tester, sharedPreferences);
      });

      testWidgets('navigates to TripEditorPage after creating trip',
          (WidgetTester tester) async {
        await runHomePageCreateTripFlowTest(tester, sharedPreferences);
      });
    });

    group('Trip Editor Page Tests', () {
      setUp(() async {
        // Setup authenticated state and create a test trip
        await TestHelpers.setupAuthenticatedState(sharedPreferences);
        await TestHelpers.createTestTrip(sharedPreferences);
      });

      testWidgets(
          'displays ItineraryViewer and BudgetingPage side by side when isBigLayout is true',
          (WidgetTester tester) async {
        await runTripEditorLargeLayoutTest(tester, sharedPreferences);
      });

      testWidgets(
          'displays FAB at center bottom with padding when isBigLayout is true',
          (WidgetTester tester) async {
        await runTripEditorLargeLayoutFABTest(tester, sharedPreferences);
      });

      testWidgets(
          'displays ItineraryViewer by default when isBigLayout is false',
          (WidgetTester tester) async {
        await runTripEditorSmallLayoutDefaultTest(tester, sharedPreferences);
      });

      testWidgets('displays BottomNavigationBar when isBigLayout is false',
          (WidgetTester tester) async {
        await runTripEditorSmallLayoutBottomNavTest(tester, sharedPreferences);
      });

      testWidgets(
          'switches between ItineraryViewer and BudgetingPage using BottomNavigationBar',
          (WidgetTester tester) async {
        await runTripEditorSmallLayoutNavigationTest(tester, sharedPreferences);
      });

      testWidgets('displays FAB docked in center of BottomNavBar',
          (WidgetTester tester) async {
        await runTripEditorSmallLayoutFABTest(tester, sharedPreferences);
      });
    });
  });
}
