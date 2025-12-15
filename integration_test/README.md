# Wandrr Integration Tests

Complete guide for integration testing the Wandrr Travel Planner Flutter application.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Test Structure](#test-structure)
4. [Running Tests](#running-tests)
5. [Test Coverage](#test-coverage)
6. [Best Practices](#best-practices)
7. [Helper Utilities](#helper-utilities)
8. [Troubleshooting](#troubleshooting)
9. [CI/CD Integration](#cicd-integration)
10. [Writing New Tests](#writing-new-tests)
11. [Trip Repository Setup](#trip-repository-setup)

*Note: If links open in browser, scroll down or use Ctrl+F to search for section titles.*

---

## 1. Overview

This directory contains comprehensive integration tests for the Wandrr Travel Planner app, covering:

- ✅ **83 test cases** across 8 major features
- ✅ **Device-agnostic testing** (adapts to actual device size)
- ✅ **Widget-based waiting** (fast and reliable)
- ✅ **Native splash screen handling** (automatic)
- ✅ **Multi-platform support** (iOS, Android, Web)

### Key Features

- **Real Device Testing**: Tests run on actual devices/emulators
- **Automatic Splash Handling**: Native splash screen wait is built-in
- **Smart Waiting**: Waits for widgets, not arbitrary timeouts
- **Responsive Testing**: Adapts to device screen size automatically

---

## 2. Quick Start

### Install Dependencies

```bash
flutter pub get
```

### Run All Tests

```bash
# Run all integration tests
flutter test integration_test/app_integration_test.dart

# Run on specific device
flutter devices  # List available devices
flutter test integration_test/app_integration_test.dart -d <device_id>

# Run on Chrome
flutter test integration_test/app_integration_test.dart -d chrome
```

### Using PowerShell Script

```powershell
# Run all tests
.\integration_test\run_integration_tests.ps1

# Run specific test group
.\integration_test\run_integration_tests.ps1 -Command startup
.\integration_test\run_integration_tests.ps1 -Command login
.\integration_test\run_integration_tests.ps1 -Command home
.\integration_test\run_integration_tests.ps1 -Command trip-editor

# Run on specific device
.\integration_test\run_integration_tests.ps1 -Device chrome

# Run with verbose output
.\integration_test\run_integration_tests.ps1 -Verbose

# Show help
.\integration_test\run_integration_tests.ps1 -Command help
```

---

## 3. Test Structure

```
integration_test/
├── app_integration_test.dart          # Main test suite entry point (83 tests)
├── driver/
│   └── integration_test_driver.dart   # Test driver for real devices
├── helpers/
│   ├── test_config.dart               # Test configuration & constants
│   ├── test_helpers.dart              # 30+ utility functions
│   └── mock_firebase_setup.dart       # Firebase mocking
├── tests/
│   ├── startup_page_test.dart         # 3 test functions
│   ├── login_page_test.dart           # 2 test functions
│   ├── home_page_test.dart            # 8 test functions
│   ├── trip_editor_page_test.dart     # 6 test functions
│   ├── itinerary_viewer_test.dart     # 12 test functions
│   ├── budgeting_page_test.dart       # 16 test functions
│   ├── crud_operations_test.dart      # 18 test functions
│   └── multi_collaborator_test.dart   # 18 test functions
├── README.md                          # This comprehensive guide
└── run_integration_tests.ps1          # PowerShell test runner
```

---

## 4. Running Tests

### Command Line Options

#### Run Specific Test Groups

```bash
# Startup page tests only
flutter test integration_test/app_integration_test.dart --name "Startup Page Tests"

# Login page tests only
flutter test integration_test/app_integration_test.dart --name "Login Page Tests"

# Home page tests only
flutter test integration_test/app_integration_test.dart --name "Home Page Tests"

# Trip editor tests only
flutter test integration_test/app_integration_test.dart --name "Trip Editor Page Tests"

# Itinerary viewer tests only
flutter test integration_test/app_integration_test.dart --name "Itinerary Viewer Tests"

# Budgeting page tests only
flutter test integration_test/app_integration_test.dart --name "Budgeting Page Tests"

# CRUD operations tests only
flutter test integration_test/app_integration_test.dart --name "CRUD Operations Tests"

# Multi-collaborator tests only
flutter test integration_test/app_integration_test.dart --name "Multi-Collaborator Tests"
```

#### Run Individual Tests

```bash
# Run a specific test by name
flutter test integration_test/app_integration_test.dart --name "displays OnboardingPage and LoginPage side by side"
```

#### Device Selection

```bash
# List available devices
flutter devices

# Run on specific device
flutter test integration_test/app_integration_test.dart -d emulator-5554
flutter test integration_test/app_integration_test.dart -d iphone_14
flutter test integration_test/app_integration_test.dart -d chrome

# Run with verbose output
flutter test integration_test/app_integration_test.dart --verbose
```

### Recommended Device Matrix

Run tests on multiple devices to cover different scenarios:

| Device Type | Example     | Screen Size    | Tests Coverage     |
|-------------|-------------|----------------|--------------------|
| Small Phone | Pixel 3     | < 1000px width | Small layout tests |
| Large Phone | Pixel 6 Pro | < 1000px width | Small layout tests |
| Tablet      | iPad Pro    | ≥ 1000px width | Large layout tests |
| Desktop     | Chrome      | ≥ 1000px width | Large layout tests |

---

## 5. Test Coverage

### Summary

- **Total Tests**: 83 test cases
- **Test Files**: 8 files
- **Coverage**: All major user flows including itinerary management, budgeting, CRUD operations, and
  multi-collaborator features

### 1. Startup Page Tests (3 tests)

✅ **Large Screen Layout**

- Displays OnboardingPage and LoginPage side by side when width ≥ 1000px
- No next button shown

✅ **Small Screen Layout**

- Displays OnboardingPage with next button when width < 1000px
- LoginPage not visible initially

✅ **Navigation**

- Clicking next button navigates to LoginPage

### 2. Login Page Tests (2 tests)

✅ **Authentication Flow**

- Enter username and password
- Tap login button
- Navigate to TripProvider (loading page with Rive animation)
- TripProvider loads trip repository
- Navigate to HomePage after loading completes
- Verify successful navigation

✅ **Loading Animation**

- Rive animation displayed during TripProvider loading
- Automatic wait for HomePage after repository loading

### 3. Home Page Tests (8 tests)

✅ **Layout Responsiveness**

- `isBigLayout = true` when width ≥ 1000px
- `isBigLayout = false` when width < 1000px

✅ **Empty State**

- TripsListView displays when no trips exist

✅ **Settings**

- Language selection updates locale and repository
- Theme mode switcher toggles dark/light mode
- Logout navigates back to StartupPage

✅ **Trip Creation**

- "Plan a Trip" button shows trip creator dialog
- Dialog allows thumbnail, name, dates, and budget input
- Submitting navigates to TripEditorPage

### 4. Trip Editor Page Tests (6 tests)

✅ **Large Layout** (width ≥ 1000px)

- ItineraryViewer and BudgetingPage side by side
- FloatingActionButton at center bottom with padding
- No BottomNavigationBar

✅ **Small Layout** (width < 1000px)

- ItineraryViewer displayed by default
- BottomNavigationBar for navigation
- FloatingActionButton docked in center of BottomNavBar
- Can switch between Itinerary and Budgeting views

### 5. Itinerary Viewer Tests (12 tests)

✅ **Default Display**

- Displays first trip date's itinerary by default
- ItineraryNavigator and ItineraryViewer present

✅ **Timeline Items**

- Transits displayed correctly (full-day and short-duration)
- Lodgings displayed correctly (full-day, check-in, check-out)
- Timeline items sorted chronologically

✅ **Tab Navigation**

- Notes tab accessible and functional
- Checklists tab accessible and functional
- Sights tab accessible and functional (with/without dates)

✅ **Date Navigation**

- Navigate to next date using right chevron
- Navigate to previous date using left chevron
- Cannot navigate before trip start date (button disabled)
- Cannot navigate beyond trip end date (button disabled)
- Itinerary viewer refreshes when navigating between dates

### 6. Budgeting Page Tests (16 tests)

✅ **Page Structure**

- Three collapsible sections present: Expenses, Debt, Breakdown
- ExpenseListView displays with BudgetTile
- Sort options toggle buttons available

✅ **Budget Display**

- BudgetTile shows total expense percentage and budget amount
- Progress indicator when expenses under budget (colored bar)
- Error indicator when expenses over budget (red color scheme)
- Currency conversion applied to all expenses

✅ **Sort Options**

- Default sort: Date (newest to oldest)
- Sort by cost ascending (low to high) ✅
- Sort by cost descending (high to low) ✅
- Sort by date ascending (oldest to newest) ✅
- Sort by date descending (newest to oldest) ✅
- Sort by category ✅

✅ **Expense Types**

- Expenses from transits (flights, trains, taxis)
- Expenses from lodgings (hotels, hostels)
- Expenses from sights (tickets, tours)
- Pure expenses (meals, shopping, misc)
- Expenses with dates (linked to trip entities)
- Expenses without dates (standalone)

✅ **Categories**

- Transport category
- Lodging category
- Food category
- Entertainment category
- Sightseeing category
- Miscellaneous category

✅ **Multiple Currencies**

- Expenses in various currencies (USD, EUR, GBP, JPY, etc.)
- Currency conversion to base currency
- Total displayed in trip's base currency

✅ **Debt Summary**

- Debt information displayed
- Shows who owes whom
- Amounts formatted correctly

✅ **Breakdown**

- Category breakdown chart
- Day-by-day breakdown chart
- Tab navigation between breakdown views

### 7. CRUD Operations Tests (18 tests)

✅ **Create Operations (6 tests)**

- Add new transit via FloatingActionButton
- Add new stay/lodging via FloatingActionButton
- Add new expense via FloatingActionButton
- Add new sight from itinerary viewer
- Add new note from itinerary viewer
- Add new checklist from itinerary viewer

✅ **Update/Edit Operations (6 tests)**

- Edit existing transit from timeline
- Edit existing stay from timeline
- Edit existing expense from budgeting page
- Edit sight opens specific sight in editor
- Edit note opens specific note in editor
- Edit checklist opens specific checklist in editor

✅ **Repository Propagation (6 tests)**

- Adding transit updates expense list view
- Adding stay updates multiple views (timeline + expenses + breakdown)
- Adding sight updates itinerary and optionally expenses
- Editing expense updates budget display (percentage, total, charts)
- Repository updates propagate to all subscribed views
- Navigate to specific itinerary component (sight/note/checklist by index)

✅ **Data Flow Validation**

- User action → TripManagementBloc event
- Bloc → Repository update
- Repository → Firestore collection
- Stream broadcasts change
- All subscribed widgets rebuild

✅ **Affected Components on Update**

- ItineraryViewer (timeline, notes, checklists, sights tabs)
- ExpenseListView (sorted expense list)
- BudgetTile (total expense and percentage)
- DebtSummaryTile (debt calculations)
- BudgetBreakdownTile (charts by category and day)

✅ **Editor Configuration**

- PlanDataType enum (sight, note, checklist)
- CreateNewItineraryPlanDataComponentConfig (for adding)
- UpdateItineraryPlanDataComponentConfig (for editing with index)
- Editor opens correct tab and scrolls to item

### 8. Multi-Collaborator Tests (18 tests)

✅ **Collaborator Display (2 tests)**

- AppBar displays maximum of 3 contributors (CircleAvatars)
- First avatar shows current user (may have photo)
- Other avatars show generic person icon
- Avatars overlap for compact display

✅ **Trip Metadata Editor Access (1 test)**

- Clicking trip name/date opens metadata editor
- InkWell tappable area in AppBar
- Opens dialog or bottom sheet for editing

✅ **Trip Metadata Editing (5 tests)**

- Edit trip name (TextFormField)
- Edit trip start/end dates (calendar picker)
- Add/remove contributors (person_add/remove icons)
- Edit trip budget amount and currency
- All changes persist via repository

✅ **Expense Splitting (4 tests)**

- Transit expense splitting (flights, trains, taxis)
- Stay/lodging expense splitting (hotels, hostels)
- Sight expense splitting (tickets, tours)
- Pure expense splitting (meals, shopping)

✅ **Expense Splitting Structure**

- **paidBy**: Map<String, double> - Who paid and how much
- **splitBy**: List<String> - Who shares the cost
- All contributors shown in expense editor
- Can split payment between multiple people
- Cost divided equally among splitBy contributors

✅ **Debt Summary (3 tests)**

- Debt summary with multiple contributors
- Shows simplified debt relationships
- Format: "X owes Y: amount"
- Calculated from all expenses (paidBy vs fair share)

✅ **Debt Calculation Logic**

```
For each contributor:
1. Total paid = Sum of all paidBy amounts
2. Fair share = Sum of (expense / splitBy.length) for expenses where contributor in splitBy
3. Debt = Fair share - Total paid
4. Positive debt = owes money, Negative debt = owed money
5. Simplify and display net debts
```

✅ **Contributor Management (3 tests)**

- Adding contributor updates expense editors
- New contributor available in paidBy/splitBy
- Removing contributor validation (must not have expenses)
- Cannot remove current user
- Contributor changes propagate to all UI

✅ **Example Scenario**

```
Trip with Alice, Bob, and Charlie:

Day 1 Expenses:
- Flight: $600 (Alice paid, split 3 ways = $200 each)
- Hotel: $300 (Bob paid, split 3 ways = $100 each)
- Dinner: $90 (Charlie paid, split 3 ways = $30 each)

Calculations:
- Alice: Paid $600, Share $330 → Others owe $270
- Bob: Paid $300, Share $330 → Owes $30
- Charlie: Paid $90, Share $330 → Owes $240

Debt Summary:
- Bob owes Alice: $30
- Charlie owes Alice: $240
```

---

## 6. Best Practices

### ✅ DO: Use Widget-Based Waiting

```dart
// ✅ GOOD: Wait for specific widget
await
TestHelpers.waitForWidget
(
tester,
find.byType(HomePage),
timeout: const Duration(seconds: 10),
);
```

### ✅ DO: Use pumpAndSettle() for Animations

```dart
// ✅ GOOD: After UI interaction
await
tester.tap
(
button
);
await
tester
.
pumpAndSettle
(
); // Wait for animation
```

### ❌ DON'T: Use Fixed Duration Waits

```dart
// ❌ BAD: Fixed duration wait (deprecated)
await
TestHelpers.waitForAsync
(
tester, duration: Duration(seconds: 3));

// ❌ BAD: Don't do this
await tester.pumpAndSettle(Duration(seconds: 5
)
);
```

### Native Splash Screen

The native splash screen (3 seconds on Android) is **automatically handled** by
`pumpAndSettleApp()`. You don't need to wait for it explicitly.

```dart
// ✅ Automatically waits for native splash screen
await
TestHelpers.pumpAndSettleApp
(
tester
,
MasterPage
(
prefs
)
);
// Native splash wait is built-in, continue with test...
```

---

## 7. Helper Utilities

### TestHelpers Class

The `TestHelpers` class provides 30+ utility methods:

#### App & Device Utilities

```dart
// Launch app and wait for splash screen (automatic)
await
TestHelpers.pumpAndSettleApp
(
tester, MasterPage(prefs));

// Get device screen size
final size = TestHelpers.getScreenSize(tester);

// Check device type
if (TestHelpers.isLargeScreen(tester)) {
// Large screen (width ≥ 1000px)
}
if (TestHelpers.isSmallScreen(tester)) {
// Small screen (width < 1000px)
}

// Log device info
print(TestHelpers.getDeviceSizeDescription(tester));
// Output: "Large screen (1200x800)"
```

#### Widget Interaction

```dart
// Tap on widget
await
TestHelpers.tapWidget
(tester, finder);

// Enter text
await
TestHelpers.enterText
(
tester, finder, 'text');

// Long press
await TestHelpers.longPressWidget(tester, finder);

// Drag widget
await TestHelpers.dragWidget(tester, finder, Offset(100,
0
)
);
```

#### Widget Finding

```dart
// Find by key
final finder = TestHelpers.findByKey('my_key');

// Find by type
final finder = TestHelpers.findByType<HomePage>();

// Find by text
final finder = TestHelpers.findByText('Hello');
```

#### Widget Verification

```dart
// Verify widget exists
TestHelpers.verifyWidgetExists
(
finder);

// Verify multiple widgets
TestHelpers.verifyWidgetsExist(finder, 3);

// Verify widget doesn't exist
TestHelpers.verifyWidgetDoesNotExist(finder);

// Verify text is displayed
TestHelpers.verifyTextDisplayed
(
'
Welcome
'
);
```

#### Waiting

```dart
// Wait for widget to appear (RECOMMENDED)
await
TestHelpers.waitForWidget
(
tester,
find.byType(HomePage),
timeout: const Duration(seconds: 10),
);

// Scroll until visible
await TestHelpers.scrollUntilVisible(
tester,
finder,
find.
byType
(
ListView
)
,
);
```

#### Position & Size

```dart
// Get widget size
final size = TestHelpers.getWidgetSize(tester, finder);

// Get widget position
final position = TestHelpers.getWidgetPosition(tester, finder);
```

### TestConfig Class

Configuration constants and test data:

```dart
// Test credentials
TestConfig.testEmail // 'test@example.com'
TestConfig.testPassword // 'testPassword123'
TestConfig.testUserId // 'test_user_id'

// Test trip data
TestConfig.testTripId // 'test_trip_id'
TestConfig.testTripName // 'Test Trip to Paris'
TestConfig.getTestTripData
() // Full trip object

// Timeouts
TestConfig.defaultTimeout // 10 seconds
TestConfig.longTimeout // 30 seconds
TestConfig.shortTimeout // 5 seconds

// Breakpoints
TestConfig.bigLayoutBreakpoint // 1000.0
```

---

## 8. Troubleshooting

### Common Issues

#### 1. Widget Not Found

**Problem**: Test fails with "Widget not found" error

**Solution**:

```dart
// Use waitForWidget with appropriate timeout
await
TestHelpers.waitForWidget
(
tester,
find.byType(MyWidget),
timeout: const Duration(seconds: 10),
);
```

#### 2. Layout Differences on Devices

**Problem**: Test passes on one device but fails on another

**Solution**: Tests automatically adapt to device size. Run on both large and small devices:

```bash
# Small device
flutter test integration_test/app_integration_test.dart -d pixel_3

# Large device
flutter test integration_test/app_integration_test.dart -d ipad_pro
```

#### 3. Firebase Initialization Errors

**Problem**: Test fails with "Firebase.initializeApp not called" error or Remote Config throws "
type 'Null' is not a subtype of type 'int'"

**Solution**: Firebase (including Remote Config) is automatically initialized in `setUpAll()`. The
mock setup uses official mock packages:

- ✅ **firebase_auth_mocks** for Auth
- ✅ **fake_cloud_firestore** for Firestore
- ✅ **fake_firebase_remote_config** for Remote Config

**Remote Config Default Values**:

```
latest_version: '3.0.1+16'  (matches pubspec.yaml version)
min_version: '3.0.1+16'      (matches pubspec.yaml version)
release_notes: 'Test release notes'
```

**⚠️ IMPORTANT**: The version values match the current app version in `pubspec.yaml` (3.0.1+16).
This prevents `MasterPageBloc` from triggering "update available" events during tests, which would
interfere with test execution.

**When you update app version**: If you change the version in `pubspec.yaml`, you MUST also update
these values in `integration_test/helpers/mock_firebase_setup.dart` in the `_setupRemoteConfig()`
method.

Otherwise, tests will fail because the app will think an update is available.

If you're creating a new test file, ensure you include:

```dart
import 'helpers/mock_firebase_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase before any tests run
    await MockFirebaseSetup.setupFirebaseMocks();
  });

  // Your tests here...
}
```

#### 4. Flaky Tests

**Problem**: Tests sometimes pass, sometimes fail

**Solutions**:

- Use `waitForWidget()` instead of fixed waits
- Increase timeout for slow operations
- Check network conditions
- Verify widget keys are unique

#### 5. Splash Screen Issues

**Problem**: Test times out waiting for app to start

**Solution**: The splash screen wait is automatic in `pumpAndSettleApp()`. If you still have issues:

```dart
// Splash wait is built into pumpAndSettleApp, but you can adjust timeout
// in test_helpers.dart if needed (currently 5 seconds)
```

### Debugging Tips

```bash
# Run with verbose output
flutter test integration_test/app_integration_test.dart --verbose

# Run single test
flutter test integration_test/app_integration_test.dart --name "specific test name"

# Check device logs
adb logcat  # Android
xcrun simctl spawn booted log stream  # iOS
```

---

## 9. CI/CD Integration

### GitHub Actions

Tests automatically run on:

- Push to `main` or `develop` branches
- Pull requests
- Multiple platforms (iOS, Android, Web)

See `.github/workflows/integration_tests.yml` for configuration.

### Manual CI/CD Setup

```yaml
name: Integration Tests

on: [ push, pull_request ]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: flutter pub get
      - run: flutter test integration_test/app_integration_test.dart
```

---

## 10. Writing New Tests

### Step 1: Create Test Function

Create your test function in the appropriate file (or create a new file):

```dart
// tests/my_feature_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> runMyFeatureTest(WidgetTester tester,
    SharedPreferences sharedPreferences,) async {
  // Launch app (splash screen wait is automatic)
  await TestHelpers.pumpAndSettleApp(
    tester,
    MasterPage(sharedPreferences),
  );

  print('Testing on ${TestHelpers.getDeviceSizeDescription(tester)}');

  // Your test logic here
  TestHelpers.verifyWidgetExists(find.byType(MyWidget));

  await TestHelpers.tapWidget(tester, find.text('Button'));

  await TestHelpers.waitForWidget(tester, find.byType(NextPage));
}
```

### Step 2: Add to Main Test Suite

Add your test to `app_integration_test.dart`:

```dart
group
('My Feature Tests
'
, () {
testWidgets('my feature works correctly', (WidgetTester tester) async {
await runMyFeatureTest(tester, sharedPreferences);
});
});
```

### Step 3: Run Your Test

```bash
flutter test integration_test/app_integration_test.dart --name "My Feature Tests"
```

### Tips for Writing Good Tests

1. **Be Specific**: Wait for exact widgets, not arbitrary timeouts
2. **Clean State**: Each test should be independent
3. **Clear Names**: Use descriptive test names
4. **Comments**: Explain complex logic
5. **Verify Everything**: Don't assume - verify with assertions
6. **Handle Device Sizes**: Tests should adapt to screen size
7. **Use Helpers**: Leverage TestHelpers utilities

---

## Configuration

### Test Credentials

Update in `helpers/test_config.dart`:

```dart

static const String testEmail = 'test@example.com';
static const String testPassword = 'testPassword123';
```

### Timeouts

Adjust in `helpers/test_config.dart`:

```dart

static const Duration defaultTimeout = Duration(seconds: 10);
static const Duration longTimeout = Duration(seconds: 30);
```

### Widget Keys

Ensure your app widgets have the required keys:

```dart
// In your app
TextField
(
key: Key('username_field'))
ElevatedButton(key
:
Key
(
'
login_submit_button
'
)
)
```

---

## Performance

### Test Execution Times

| Test Group  | Tests  | Typical Duration   |
|-------------|--------|--------------------|
| Startup     | 3      | ~5-10 seconds      |
| Login       | 2      | ~10-15 seconds     |
| Home        | 8      | ~20-30 seconds     |
| Trip Editor | 6      | ~15-25 seconds     |
| **Total**   | **19** | **~50-80 seconds** |

*Times vary by device speed and network conditions*

### Optimization Tips

1. **Use Specific Finders**: More specific finders are faster
2. **Avoid Unnecessary Waits**: Use widget-based waiting
3. **Reuse State**: Setup authenticated state once
4. **Parallel Execution**: Run on multiple devices simultaneously

---

## Resources

### Documentation

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [WidgetTester API](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)

### Internal Docs

- **Test Helpers**: See `helpers/test_helpers.dart` for all utilities
- **Test Config**: See `helpers/test_config.dart` for configuration
- **Examples**: See test files in `tests/` folder

---

## FAQ

### Q: Why are some tests skipped?

**A**: Tests automatically skip when the device size doesn't match. For example, small screen tests
skip on tablets.

### Q: How do I test on specific screen sizes?

**A**: Run tests on devices with the desired screen size. Tests adapt automatically.

### Q: Can I disable the splash screen wait?

**A**: The splash screen wait is built into `pumpAndSettleApp()`. If you need to bypass it, use
`tester.pumpWidget()` directly.

### Q: How do I mock Firebase?

**A**: See `helpers/mock_firebase_setup.dart` for Firebase mocking utilities.

### Q: Tests are slow, how can I speed them up?

**A**: Ensure you're using `waitForWidget()` instead of fixed duration waits. Check that timeouts
are reasonable.

### Q: How do I test on CI/CD?

**A**: See the GitHub Actions workflow in `.github/workflows/integration_tests.yml`.

---

## Support

For questions or issues:

1. Check this documentation
2. Review test examples in `tests/` folder
3. Check `test_helpers.dart` for available utilities
4. Contact the development team
5. Create an issue in the repository

---

## Changelog

### Version 2.0.0 (Current)

- ✅ Moved native splash screen wait into `pumpAndSettleApp()`
- ✅ Consolidated all documentation into single README
- ✅ Simplified test structure
- ✅ Removed redundant calls to `waitForNativeSplashScreen()`

### Version 1.0.0

- ✅ Initial release with 19 test cases
- ✅ Device-agnostic testing
- ✅ Widget-based waiting strategy
- ✅ Multi-platform support

---

**Last Updated**: November 30, 2025  
**Test Framework**: Flutter Integration Test  
**Total Tests**: 19  
**Platform Support**: iOS, Android, Web, Desktop  
**Status**: ✅ Production Ready




---

## 11. Trip Repository Setup

For detailed information about how trip data and repository are structured, see:

**[Trip Repository Setup Guide](helpers/TRIP_REPOSITORY_SETUP.md)**

This guide covers:

- Architecture overview of TripRepository
- Firestore data structure
- How data flows through the app
- Mock data setup for testing
- Current limitations and recommendations
- Future improvements for data validation

Key topics:

- **TripRepositoryImplementation** - Manages trip metadata and active trip
- **TripDataModelImplementation** - Represents a loaded trip with all collections
- **Firestore collections** - transits, lodgings, expenses, itineraries
- **Mock data strategies** - FakeFirebaseFirestore vs Firebase Emulator
- **Integration test limitations** - Why tests don't validate actual data yet
- **Recommendations** - How to add comprehensive data validation


