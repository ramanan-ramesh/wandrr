# Wandrr Integration Tests

Automated tests that launch the app, perform login, navigate to trips, and interact with trip items.

## Quick Start

### 1. Update Test Credentials

Edit `app_test.dart` lines 36-37:

```dart

const testUsername = 'your_test_email@example.com'; // ← Change this
const testPassword = 'YourTestPassword123!'; // ← Change this
```

⚠️ **Must be a valid Firebase account in your project!**

### 2. Start Emulator

```powershell
flutter devices  # Check if emulator is running
# If not, start one from Android Studio > AVD Manager
```

### 3. Run Tests

```powershell
# Simple method (recommended)
flutter test integration_test/app_test.dart

# Or use the PowerShell script
..\run_integration_tests.ps1
```

---

## What the Tests Do

**Test 1: Login & Navigation** (~15 seconds)

1. Launches app
2. Waits for loading animation
3. Enters username and password
4. Taps login button
5. Verifies navigation to trips list
6. Taps first trip item (if exists)

**Test 2: Invalid Login** (~8 seconds)

- Tests error handling with wrong credentials

---

## Common Issues

| Problem              | Solution                                                                |
|----------------------|-------------------------------------------------------------------------|
| "No device found"    | Start an emulator: `flutter devices`                                    |
| "Widget not found"   | Add more wait time: `await tester.pumpAndSettle(Duration(seconds: 5));` |
| Authentication fails | Check credentials exist in Firebase Console                             |
| Test times out       | Check internet connection or add timeout parameter                      |

---

## Adding More Tests

Example template:

```dart
testWidgets
('Your test description
'
, (WidgetTester tester) async {
// Launch app
app.main();
await tester.pumpAndSettle(Duration(seconds: 3));

// Login (if needed)
await tester.enterText(find.byKey(Key('username_field')), testUsername);
await tester.enterText(find.byKey(Key('password_field')), testPassword);
await tester.tap(find.byKey(Key('login_submit_button')));
await tester.pumpAndSettle(Duration(seconds: 5));

// Your test actions here
await tester.tap(find.text('Some Button'));
await tester.pumpAndSettle();

// Verify results
expect(find.text('Expected Text'), findsOneWidget);
});
```

---

## Widget Keys Available

These keys were added to the app for testing:

- `Key('username_field')` - Email input on login page
- `Key('password_field')` - Password input on login page
- `Key('login_submit_button')` - Login button

---

## Quick Reference

**Find widgets:**

```dart
find.byKey
(
Key('my_key')) // By key (most reliable)
find.text('Login') // By visible text
find.byType(TextFormField) // By widget type
```

**Perform actions:**

```dart
await
tester.tap
(
widget) // Tap/click
await tester.enterText(field, 'text'
) // Type text
await
tester
.
pumpAndSettle
(
) // Wait for UI to update
```

**Debug helpers:**

```dart
debugDumpApp(); // Print entire widget tree

print
(
find.byType(Widget).evaluate()); // Show all matches
```

---

## Files

- `app_test.dart` - Your test scenarios
- `test_driver.dart` - Driver for device testing
- `README.md` - This file

---

**Need more details?** Check Flutter docs: https://docs.flutter.dev/testing/integration-tests

