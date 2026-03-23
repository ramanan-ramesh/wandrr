import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/firebase_emulator_helper.dart';
import 'helpers/mock_location_api_service.dart';
import 'helpers/test_config.dart';
import 'helpers/test_helpers.dart';
import 'screenshot_capturer/capturer.dart';
import 'tests/authentication_comprehensive_test.dart';
import 'tests/budgeting_page_test.dart';
import 'tests/conflict_detection_test.dart';
import 'tests/crud_operations_test.dart';
import 'tests/entity_editing_test.dart';
import 'tests/home_page_test.dart';
import 'tests/itinerary_viewer_test.dart';
import 'tests/multi_collaborator_test.dart';
import 'tests/startup_page_test.dart';
import 'tests/trip_editor_page_test.dart';
import 'tests/validation_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
      print('✓ Firebase emulators configured for integration tests');
    });

    tearDownAll(() async {
      FirebaseEmulatorHelper.reset();
    });

    group('Screenshot Capturer', () {
      setUpAll(() async {
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
        await sharedPreferences.clear();
      });

      testWidgets('Capturing screenshots', (WidgetTester tester) async {
        await runScreenshotCapturer(tester, binding);
      });
    });

    group('Startup Page Tests', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        await sharedPreferences.clear();
      });

      tearDown(() async {
        await sharedPreferences.clear();
        await FirebaseEmulatorHelper.cleanupAfterTest();
      });

      testWidgets(
          'adapts layout based on screen size (large: side-by-side, small: navigation)',
          (WidgetTester tester) async {
        await runStartupPageTest(tester);
      });
    });

    group('Authentication & Firestore - UserManagement Tests', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        await sharedPreferences.clear();
      });

      tearDown(() async {
        await sharedPreferences.clear();
        await FirebaseEmulatorHelper.cleanupAfterTest();
      });

      testWidgets('Sign in with existing user (has Firestore document)',
          (WidgetTester tester) async {
        await runSignInExistingUserWithFirestoreDoc(tester);
      });

      testWidgets('Sign in with user without Firestore doc (creates one)',
          (WidgetTester tester) async {
        await runSignInNewUserWithoutFirestoreDoc(tester);
      });

      testWidgets('Sign in with unverified email (verification pending)',
          (WidgetTester tester) async {
        await runSignInUnverifiedEmail(tester);
      });

      testWidgets('Sign up new user (verification pending)',
          (WidgetTester tester) async {
        await runSignUpNewUser(tester);
      });

      testWidgets('Sign up with existing email (should fail)',
          (WidgetTester tester) async {
        await runSignUpExistingEmail(tester);
      });

      testWidgets('Sign in with wrong password (should fail)',
          (WidgetTester tester) async {
        await runSignInWrongPassword(tester);
      });

      testWidgets('Sign in with invalid email format (should fail)',
          (WidgetTester tester) async {
        await runSignInInvalidEmail(tester);
      });

      testWidgets('Sign in with weak password (should fail)',
          (WidgetTester tester) async {
        await runSignUpWeakPassword(tester);
      });

      testWidgets('Sign in with non-existent user (should fail)',
          (WidgetTester tester) async {
        await runSignInNonExistentUser(tester);
      });

      testWidgets('Sign out clears auth and cache',
          (WidgetTester tester) async {
        await runSignOutTest(tester);
      });
    });

    group('Home Page Tests', () {
      setUpAll(() async {
        await FirebaseEmulatorHelper.createFirebaseAuthUser(
          email: TestConfig.testEmail,
          password: TestConfig.testPassword,
          shouldAddToFirestore: true,
          shouldSignIn: true,
        );
        // Initialize mock location API service to intercept HTTP requests
        // Note: This creates a MockClient that can be injected into GeoLocator
        await MockLocationApiService.initialize();
      });

      tearDownAll(() async {
        await FirebaseEmulatorHelper.cleanupAfterTest();
        await sharedPreferences.clear();
      });

      testWidgets(
          'sets isBigLayout to true when screen width >= 1000, and AppBar resizes accordingly',
          (WidgetTester tester) async {
        await runHomePageLayoutTest(tester);
      });

      testWidgets('updates locale when language is selected from toolbar',
          (WidgetTester tester) async {
        await runHomePageLanguageSwitchTest(tester);
      });

      testWidgets('updates theme mode when theme switcher is toggled',
          (WidgetTester tester) async {
        await runHomePageThemeSwitchTest(tester);
      });

      testWidgets('displays no trips initially in TripsListView',
          (WidgetTester tester) async {
        await runHomePageEmptyTripsTest(tester);
      });

      testWidgets('navigates to TripEditorPage after creating trip',
          (WidgetTester tester) async {
        await runHomePageCreateTripFlowTest(tester);
      });
    });

    group('Trip Editor Page Tests', () {
      setUpAll(() async {
        await FirebaseEmulatorHelper.createFirebaseAuthUser(
          email: TestConfig.testEmail,
          password: TestConfig.testEmail,
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
        await sharedPreferences.clear();
      });

      testWidgets(
          'adapts layout based on screen size - side-by-side for large screens, bottom navigation for small screens',
          (WidgetTester tester) async {
        await runTripEditorLayoutTest(tester);
      });

      testWidgets(
          'trip repository contains correct values from createTestTrip setup',
          (WidgetTester tester) async {
        await runTripRepositoryValuesTest(tester);
      });
    });

    group('Itinerary Viewer Tests', () {
      setUpAll(() async {
        await FirebaseEmulatorHelper.createFirebaseAuthUser(
          email: TestConfig.testEmail,
          password: TestConfig.testEmail,
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
        await sharedPreferences.clear();
      });

      testWidgets(
          'displays first trip date with all components (transits, lodgings, sights, notes, checklists)',
          (WidgetTester tester) async {
        await runItineraryViewerDefaultDateTest(tester);
      });

      testWidgets('navigates to next date correctly',
          (WidgetTester tester) async {
        await runItineraryViewerNavigateNextTest(tester);
      });

      testWidgets('navigates to previous date correctly',
          (WidgetTester tester) async {
        await runItineraryViewerNavigatePreviousTest(tester);
      });

      testWidgets('cannot navigate before trip start date',
          (WidgetTester tester) async {
        await runItineraryViewerNavigationBoundaryStartTest(tester);
      });

      testWidgets('cannot navigate beyond trip end date',
          (WidgetTester tester) async {
        await runItineraryViewerNavigationBoundaryEndTest(tester);
      });

      testWidgets('refreshes correctly when navigating between dates',
          (WidgetTester tester) async {
        await runItineraryViewerRefreshOnNavigationTest(tester);
      });
    });

    group('Budgeting Page Tests', () {
      setUp(() async {
        // Setup authenticated state and create a test trip
        await TestHelpers.createTestTrip();
      });

      testWidgets('displays three main sections (Expenses, Debt, Breakdown)',
          (WidgetTester tester) async {
        await runBudgetingPageStructureTest(tester, sharedPreferences);
      });

      testWidgets('ExpenseListView displays BudgetTile and sort options',
          (WidgetTester tester) async {
        await runExpensesListViewStructureTest(tester, sharedPreferences);
      });

      testWidgets('BudgetTile displays correctly when expenses under budget',
          (WidgetTester tester) async {
        await runBudgetTileUnderBudgetTest(tester, sharedPreferences);
      });

      testWidgets('BudgetTile displays correctly when expenses over budget',
          (WidgetTester tester) async {
        await runBudgetTileOverBudgetTest(tester, sharedPreferences);
      });

      testWidgets('default sort option works (newest to oldest)',
          (WidgetTester tester) async {
        await runSortOptionsDefaultTest(tester, sharedPreferences);
      });

      testWidgets('sort by cost ascending works', (WidgetTester tester) async {
        await runSortByCostAscendingTest(tester, sharedPreferences);
      });

      testWidgets('sort by cost descending works', (WidgetTester tester) async {
        await runSortByCostDescendingTest(tester, sharedPreferences);
      });

      testWidgets('sort by date ascending works (oldest first)',
          (WidgetTester tester) async {
        await runSortByDateAscendingTest(tester, sharedPreferences);
      });

      testWidgets('sort by date descending works (newest first)',
          (WidgetTester tester) async {
        await runSortByDateDescendingTest(tester, sharedPreferences);
      });

      testWidgets('sort by category works', (WidgetTester tester) async {
        await runSortByCategoryTest(tester, sharedPreferences);
      });

      testWidgets('DebtSummaryTile displays debt information',
          (WidgetTester tester) async {
        await runDebtSummaryTest(tester, sharedPreferences);
      });

      testWidgets('BudgetBreakdownTile displays breakdown charts',
          (WidgetTester tester) async {
        await runBudgetBreakdownTest(tester, sharedPreferences);
      });

      testWidgets('expenses with various categories display correctly',
          (WidgetTester tester) async {
        await runExpenseCategoriesTest(tester, sharedPreferences);
      });

      testWidgets('expenses with and without dates display correctly',
          (WidgetTester tester) async {
        await runExpensesWithAndWithoutDatesTest(tester, sharedPreferences);
      });

      testWidgets('expenses from different sources display correctly',
          (WidgetTester tester) async {
        await runExpensesFromDifferentSourcesTest(tester, sharedPreferences);
      });

      testWidgets('multiple currencies handled correctly',
          (WidgetTester tester) async {
        await runMultipleCurrenciesTest(tester, sharedPreferences);
      });
    });

    group('TripEntity CRUD Tests', () {
      setUp(() async {
        // Setup authenticated state and create a test trip
        await TestHelpers.createTestTrip();
      });

      testWidgets('add new transit via FloatingActionButton',
          (WidgetTester tester) async {
        await runAddTransitTest(tester, sharedPreferences);
      });

      testWidgets('add new stay via FloatingActionButton',
          (WidgetTester tester) async {
        await runAddStayTest(tester, sharedPreferences);
      });

      testWidgets('add new expense via FloatingActionButton',
          (WidgetTester tester) async {
        await runAddExpenseTest(tester, sharedPreferences);
      });

      testWidgets('add new sight from itinerary viewer',
          (WidgetTester tester) async {
        await runAddSightTest(tester, sharedPreferences);
      });

      testWidgets('add new note from itinerary viewer',
          (WidgetTester tester) async {
        await runAddNoteTest(tester, sharedPreferences);
      });

      testWidgets('add new checklist from itinerary viewer',
          (WidgetTester tester) async {
        await runAddChecklistTest(tester, sharedPreferences);
      });

      testWidgets('edit existing transit from timeline',
          (WidgetTester tester) async {
        await runEditTransitTest(tester, sharedPreferences);
      });

      testWidgets('edit existing stay from timeline',
          (WidgetTester tester) async {
        await runEditStayTest(tester, sharedPreferences);
      });

      testWidgets('edit existing expense from budgeting page',
          (WidgetTester tester) async {
        await runEditExpenseTest(tester, sharedPreferences);
      });

      testWidgets('edit sight opens specific sight in editor',
          (WidgetTester tester) async {
        await runEditSightTest(tester, sharedPreferences);
      });

      testWidgets('edit note opens specific note in editor',
          (WidgetTester tester) async {
        await runEditNoteTest(tester, sharedPreferences);
      });

      testWidgets('edit checklist opens specific checklist in editor',
          (WidgetTester tester) async {
        await runEditChecklistTest(tester, sharedPreferences);
      });

      testWidgets('adding transit updates expense list view',
          (WidgetTester tester) async {
        await runTransitUpdatesExpenseListTest(tester, sharedPreferences);
      });

      testWidgets('adding stay updates multiple views',
          (WidgetTester tester) async {
        await runStayUpdatesMultipleViewsTest(tester, sharedPreferences);
      });

      testWidgets('adding sight updates itinerary',
          (WidgetTester tester) async {
        await runSightUpdatesItineraryTest(tester, sharedPreferences);
      });

      testWidgets('editing expense updates budget display',
          (WidgetTester tester) async {
        await runExpenseEditUpdatesBudgetTest(tester, sharedPreferences);
      });

      testWidgets('repository updates propagate to all views',
          (WidgetTester tester) async {
        await runRepositoryPropagationTest(tester, sharedPreferences);
      });

      testWidgets('navigate to specific itinerary component',
          (WidgetTester tester) async {
        await runNavigateToSpecificComponentTest(tester, sharedPreferences);
      });
    });

    group('Multi-Collaborator Tests', () {
      setUp(() async {
        // Setup authenticated state and create a test trip
        await TestHelpers.createTestTrip();
      });

      testWidgets('AppBar displays maximum of 3 contributors',
          (WidgetTester tester) async {
        await runCollaboratorListMaxThreeTest(tester, sharedPreferences);
      });

      testWidgets('clicking trip name/date opens trip metadata editor',
          (WidgetTester tester) async {
        await runTripNameOpensMetadataEditorTest(tester, sharedPreferences);
      });

      testWidgets('edit trip name in metadata editor',
          (WidgetTester tester) async {
        await runEditTripNameTest(tester, sharedPreferences);
      });

      testWidgets('edit trip dates in metadata editor',
          (WidgetTester tester) async {
        await runEditTripDatesTest(tester, sharedPreferences);
      });

      testWidgets('add/remove contributors in metadata editor',
          (WidgetTester tester) async {
        await runEditContributorsTest(tester, sharedPreferences);
      });

      testWidgets('edit trip budget in metadata editor',
          (WidgetTester tester) async {
        await runEditTripBudgetTest(tester, sharedPreferences);
      });

      testWidgets('expense splitting displays all contributors',
          (WidgetTester tester) async {
        await runExpenseSplittingDisplayTest(tester, sharedPreferences);
      });

      testWidgets('transit expense splitting', (WidgetTester tester) async {
        await runTransitExpenseSplittingTest(tester, sharedPreferences);
      });

      testWidgets('stay/lodging expense splitting',
          (WidgetTester tester) async {
        await runStayExpenseSplittingTest(tester, sharedPreferences);
      });

      testWidgets('sight expense splitting', (WidgetTester tester) async {
        await runSightExpenseSplittingTest(tester, sharedPreferences);
      });

      testWidgets('debt summary with multiple contributors',
          (WidgetTester tester) async {
        await runDebtSummaryMultipleContributorsTest(tester, sharedPreferences);
      });

      testWidgets('debt calculation logic', (WidgetTester tester) async {
        await runDebtCalculationTest(tester, sharedPreferences);
      });

      testWidgets('adding contributor updates expense splitting',
          (WidgetTester tester) async {
        await runAddContributorUpdatesExpensesTest(tester, sharedPreferences);
      });

      testWidgets('removing contributor validation',
          (WidgetTester tester) async {
        await runRemoveContributorValidationTest(tester, sharedPreferences);
      });

      testWidgets('expense splitting UI shows all contributors',
          (WidgetTester tester) async {
        await runExpenseSplittingUITest(tester, sharedPreferences);
      });

      testWidgets('collaborator avatars in app bar',
          (WidgetTester tester) async {
        await runCollaboratorAvatarsTest(tester, sharedPreferences);
      });

      testWidgets('trip metadata persistence after edit',
          (WidgetTester tester) async {
        await runTripMetadataPersistenceTest(tester, sharedPreferences);
      });

      testWidgets('multiple contributors scenario',
          (WidgetTester tester) async {
        await runMultipleContributorsScenarioTest(tester, sharedPreferences);
      });
    });

    // =========================================================================
    // VALIDATION TESTS (Section 23 — Model-level validation rules)
    // =========================================================================
    group('Validation Rules Tests', () {
      testWidgets('REQ-CT-002: TripMetadata validation',
          (WidgetTester tester) async {
        await runTripMetadataValidationTest(tester, sharedPreferences);
      });

      testWidgets('REQ-ST-002: Lodging validation',
          (WidgetTester tester) async {
        await runLodgingValidationTest(tester, sharedPreferences);
      });

      testWidgets('REQ-TR-002/005: Transit validation',
          (WidgetTester tester) async {
        await runTransitValidationTest(tester, sharedPreferences);
      });

      testWidgets('Sight validation', (WidgetTester tester) async {
        await runSightValidationTest(tester, sharedPreferences);
      });

      testWidgets('CheckList validation', (WidgetTester tester) async {
        await runCheckListValidationTest(tester, sharedPreferences);
      });

      testWidgets('REQ-IPD-007: ItineraryPlanData validation',
          (WidgetTester tester) async {
        await runItineraryPlanDataValidationTest(tester, sharedPreferences);
      });

      testWidgets('REQ-EX-005: ExpenseFacade validation',
          (WidgetTester tester) async {
        await runExpenseFacadeValidationTest(tester, sharedPreferences);
      });

      testWidgets('REQ-SE-003: StandaloneExpense validation',
          (WidgetTester tester) async {
        await runStandaloneExpenseValidationTest(tester, sharedPreferences);
      });
    });

    // =========================================================================
    // CONFLICT DETECTION TESTS (REQ-CD-001 through REQ-CD-011)
    // =========================================================================
    group('Conflict Detection Tests', () {
      setUpAll(() async {
        await FirebaseEmulatorHelper.createFirebaseAuthUser(
          email: TestConfig.testEmail,
          password: TestConfig.testEmail,
          shouldAddToFirestore: true,
          shouldSignIn: true,
        );
        await MockLocationApiService.initialize();
        await TestHelpers.createTestTrip();
      });

      tearDownAll(() async {
        await FirebaseEmulatorHelper.cleanupAfterTest();
        await sharedPreferences.clear();
      });

      // --- TimeRange position analysis (REQ-CD-003, REQ-CD-003a) ---
      testWidgets('REQ-CD-003a: adjacent events are not conflicts',
          (WidgetTester tester) async {
        await runAdjacentEventsAreNotConflictsTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-003: exact boundary match positions',
          (WidgetTester tester) async {
        await runExactBoundaryMatchPositionTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-003: containment positions',
          (WidgetTester tester) async {
        await runContainmentPositionTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-003: partial overlap positions',
          (WidgetTester tester) async {
        await runPartialOverlapPositionTest(tester, sharedPreferences);
      });

      // --- Stay conflict tests (REQ-CD-004, REQ-ST-003) ---
      testWidgets('REQ-CD-004: transit contained in stay is NOT a conflict',
          (WidgetTester tester) async {
        await runStayNoConflictWhenTransitContainedTest(
            tester, sharedPreferences);
      });

      testWidgets('REQ-CD-004: stay vs stay overlapping IS a conflict',
          (WidgetTester tester) async {
        await runStayConflictWithOverlappingStayTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-003: stay exact boundary match is a conflict',
          (WidgetTester tester) async {
        await runStayConflictAtExactBoundaryTest(tester, sharedPreferences);
      });

      testWidgets(
          'REQ-CD-003a: adjacent stays (checkout==checkin) NOT a conflict',
          (WidgetTester tester) async {
        await runStayNoConflictWhenAdjacentTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-005: stay partial overlap + clamping',
          (WidgetTester tester) async {
        await runStayPartialOverlapClampingTest(tester, sharedPreferences);
      });

      // --- Transit conflict tests ---
      testWidgets('REQ-CD-004: transit during stay NOT a conflict',
          (WidgetTester tester) async {
        await runTransitNoConflictDuringStayTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-003: transit at stay boundary IS a conflict',
          (WidgetTester tester) async {
        await runTransitConflictAtStayBoundaryTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-003a: transit adjacent to stay NOT a conflict',
          (WidgetTester tester) async {
        await runTransitNoConflictAdjacentToStayTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-004: two overlapping transits IS a conflict',
          (WidgetTester tester) async {
        await runTransitConflictWithOtherTransitTest(tester, sharedPreferences);
      });

      testWidgets('REQ-JE-006: journey conflict deduplication',
          (WidgetTester tester) async {
        await runJourneyConflictDeduplicationTest(tester, sharedPreferences);
      });

      // --- Sight conflict tests ---
      testWidgets('REQ-IPD-004: two sights same time → overlap error',
          (WidgetTester tester) async {
        await runSightOverlapSameDayTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-004: sight during stay NOT a conflict',
          (WidgetTester tester) async {
        await runSightNoConflictDuringStayTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-003: sight at stay boundary IS a conflict',
          (WidgetTester tester) async {
        await runSightConflictAtStayBoundaryTest(tester, sharedPreferences);
      });

      testWidgets(
          'REQ-CD-001: non-time changes do NOT trigger conflict detection',
          (WidgetTester tester) async {
        await runSightNoConflictOnNonTimeChangeTest(tester, sharedPreferences);
      });

      // --- Metadata conflict tests ---
      testWidgets('REQ-TD-003: shrink date range → out-of-bounds conflicts',
          (WidgetTester tester) async {
        await runMetadataShrinkDateRangeConflictTest(tester, sharedPreferences);
      });

      testWidgets('REQ-TD-004: add contributor → expense split changes',
          (WidgetTester tester) async {
        await runMetadataContributorAddExpenseSplitTest(
            tester, sharedPreferences);
      });

      // --- Clamping tests ---
      testWidgets('REQ-CD-005: unclampable → marked for deletion',
          (WidgetTester tester) async {
        await runClampingImpossibleMarkedForDeletionTest(
            tester, sharedPreferences);
      });

      // --- Plan management tests ---
      testWidgets('REQ-CD-007: conflict plan confirmation',
          (WidgetTester tester) async {
        await runConflictPlanConfirmationTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-009: toggle deletion syncs expense change',
          (WidgetTester tester) async {
        await runToggleDeletionSyncsExpenseTest(tester, sharedPreferences);
      });

      // --- Scan exclusion tests ---
      testWidgets('REQ-CD-011: editing existing entity excludes self',
          (WidgetTester tester) async {
        await runSelfExclusionEditingExistingTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-011: new entity has no exclusions',
          (WidgetTester tester) async {
        await runNoExclusionForNewEntityTest(tester, sharedPreferences);
      });

      testWidgets('REQ-CD-011: journey excludes all leg IDs',
          (WidgetTester tester) async {
        await runJourneyExcludesAllLegsTest(tester, sharedPreferences);
      });
    });

    // =========================================================================
    // ENTITY EDITING TESTS (REQ-TE, REQ-TR, REQ-ST, REQ-IPD, REQ-SE, REQ-IT)
    // =========================================================================
    group('Entity Editing Tests', () {
      setUpAll(() async {
        await FirebaseEmulatorHelper.createFirebaseAuthUser(
          email: TestConfig.testEmail,
          password: TestConfig.testEmail,
          shouldAddToFirestore: true,
          shouldSignIn: true,
        );
        await MockLocationApiService.initialize();
        await TestHelpers.createTestTrip();
      });

      tearDownAll(() async {
        await FirebaseEmulatorHelper.cleanupAfterTest();
        await sharedPreferences.clear();
      });

      testWidgets('REQ-TE-003: creator bottom sheet options',
          (WidgetTester tester) async {
        await runCreatorBottomSheetOptionsTest(tester, sharedPreferences);
      });

      testWidgets('REQ-TR-001: transit editor opens',
          (WidgetTester tester) async {
        await runTransitEditorOpensTest(tester, sharedPreferences);
      });

      testWidgets('REQ-TR-003: transit type change visibility',
          (WidgetTester tester) async {
        await runTransitTypeChangeVisibilityTest(tester, sharedPreferences);
      });

      testWidgets('REQ-ST-001: stay editor opens', (WidgetTester tester) async {
        await runStayEditorOpensTest(tester, sharedPreferences);
      });

      testWidgets('REQ-IPD-001: itinerary item creation from bottom sheet',
          (WidgetTester tester) async {
        await runItineraryItemCreationFromBottomSheetTest(
            tester, sharedPreferences);
      });

      testWidgets('REQ-IPD-002: itinerary editor tabs',
          (WidgetTester tester) async {
        await runItineraryEditorTabsTest(tester, sharedPreferences);
      });

      testWidgets('REQ-SE-001: expense editor opens',
          (WidgetTester tester) async {
        await runExpenseEditorOpensTest(tester, sharedPreferences);
      });

      testWidgets('REQ-IT-001: day navigation arrows',
          (WidgetTester tester) async {
        await runItineraryDayNavigationTest(tester, sharedPreferences);
      });

      testWidgets('REQ-IT-004: timeline event card content',
          (WidgetTester tester) async {
        await runTimelineEventCardContentTest(tester, sharedPreferences);
      });

      testWidgets('REQ-TE-001: trip editor layout adaptation',
          (WidgetTester tester) async {
        await runTripEditorLayoutAdaptationTest(tester, sharedPreferences);
      });

      testWidgets('REQ-TD-001: trip details editor fields',
          (WidgetTester tester) async {
        await runTripDetailsEditorFieldsTest(tester, sharedPreferences);
      });

      testWidgets('REQ-BU-001: budgeting page sections',
          (WidgetTester tester) async {
        await runBudgetingPageSectionsTest(tester, sharedPreferences);
      });

      testWidgets('REQ-IT-003: timeline events aggregation per day',
          (WidgetTester tester) async {
        await runTimelineAggregationTest(tester, sharedPreferences);
      });

      testWidgets('REQ-TE-004: entity editor presented as modal bottom sheet',
          (WidgetTester tester) async {
        await runEntityEditorPresentationTest(tester, sharedPreferences);
      });

      testWidgets('REQ-TE-005: entity editor modes (create vs edit)',
          (WidgetTester tester) async {
        await runEntityEditorModesTest(tester, sharedPreferences);
      });

      testWidgets('REQ-TE-006: editor view switching (editor + conflicts)',
          (WidgetTester tester) async {
        await runEditorViewSwitchingTest(tester, sharedPreferences);
      });

      testWidgets('REQ-IT-002: day view has 4 tabs',
          (WidgetTester tester) async {
        await runDayViewTabsTest(tester, sharedPreferences);
      });

      testWidgets('REQ-IT-005: connected journey display',
          (WidgetTester tester) async {
        await runConnectedJourneyDisplayTest(tester, sharedPreferences);
      });

      testWidgets('REQ-IT-006: timeline rebuild rules',
          (WidgetTester tester) async {
        await runTimelineRebuildRulesTest(tester, sharedPreferences);
      });
    });
  });
}
