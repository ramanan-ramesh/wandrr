import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mock_firebase_setup.dart';
import 'helpers/test_helpers.dart';
import 'tests/budgeting_page_test.dart';
import 'tests/crud_operations_test.dart';
import 'tests/home_page_test.dart';
import 'tests/itinerary_viewer_test.dart';
import 'tests/login_page_test.dart';
import 'tests/multi_collaborator_test.dart';
import 'tests/startup_page_test.dart';
import 'tests/trip_editor_page_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Wandrr Travel Planner Integration Tests', () {
    late SharedPreferences sharedPreferences;

    setUpAll(() async {
      await MockFirebaseSetup.setupFirebaseMocks(
        remoteConfigDefaults: {
          'latest_version': '3.0.1+16',
          'min_version': '3.0.1+16',
          'release_notes': 'Test notes',
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
          'adapts layout based on screen size (large: side-by-side, small: navigation)',
          (WidgetTester tester) async {
        await runStartupPageTest(tester, sharedPreferences);
      });
    });

    group('Login Page Tests', () {
      testWidgets(
          'authenticates with username and password and navigates to HomePage',
          (WidgetTester tester) async {
        await runLoginAuthenticationTest(tester, sharedPreferences);
      });

      testWidgets('displays rive animation during TripProvider loading',
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

    group('Itinerary Viewer Tests', () {
      setUp(() async {
        // Setup authenticated state and create a test trip
        await TestHelpers.setupAuthenticatedState(sharedPreferences);
        await TestHelpers.createTestTrip(sharedPreferences);
      });

      testWidgets('displays the first trip date\'s itinerary by default',
          (WidgetTester tester) async {
        await runItineraryViewerDefaultDateTest(tester, sharedPreferences);
      });

      testWidgets('displays transits correctly in timeline',
          (WidgetTester tester) async {
        await runItineraryViewerTransitsTest(tester, sharedPreferences);
      });

      testWidgets('displays lodgings correctly in timeline',
          (WidgetTester tester) async {
        await runItineraryViewerLodgingsTest(tester, sharedPreferences);
      });

      testWidgets('displays notes tab correctly', (WidgetTester tester) async {
        await runItineraryViewerNotesTest(tester, sharedPreferences);
      });

      testWidgets('displays checklists tab correctly',
          (WidgetTester tester) async {
        await runItineraryViewerChecklistsTest(tester, sharedPreferences);
      });

      testWidgets('displays sights tab correctly', (WidgetTester tester) async {
        await runItineraryViewerSightsTest(tester, sharedPreferences);
      });

      testWidgets('timeline items are sorted correctly',
          (WidgetTester tester) async {
        await runItineraryViewerTimelineSortingTest(tester, sharedPreferences);
      });

      testWidgets('navigates to next date correctly',
          (WidgetTester tester) async {
        await runItineraryViewerNavigateNextTest(tester, sharedPreferences);
      });

      testWidgets('navigates to previous date correctly',
          (WidgetTester tester) async {
        await runItineraryViewerNavigatePreviousTest(tester, sharedPreferences);
      });

      testWidgets('cannot navigate before trip start date',
          (WidgetTester tester) async {
        await runItineraryViewerNavigationBoundaryStartTest(
            tester, sharedPreferences);
      });

      testWidgets('cannot navigate beyond trip end date',
          (WidgetTester tester) async {
        await runItineraryViewerNavigationBoundaryEndTest(
            tester, sharedPreferences);
      });

      testWidgets('refreshes correctly when navigating between dates',
          (WidgetTester tester) async {
        await runItineraryViewerRefreshOnNavigationTest(
            tester, sharedPreferences);
      });
    });

    group('Budgeting Page Tests', () {
      setUp(() async {
        // Setup authenticated state and create a test trip
        await TestHelpers.setupAuthenticatedState(sharedPreferences);
        await TestHelpers.createTestTrip(sharedPreferences);
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

    group('CRUD Operations Tests', () {
      setUp(() async {
        // Setup authenticated state and create a test trip
        await TestHelpers.setupAuthenticatedState(sharedPreferences);
        await TestHelpers.createTestTrip(sharedPreferences);
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
        await TestHelpers.setupAuthenticatedState(sharedPreferences);
        await TestHelpers.createTestTrip(sharedPreferences);
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
  });
}
