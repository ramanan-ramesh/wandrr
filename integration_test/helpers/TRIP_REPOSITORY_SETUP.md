# Trip Repository Setup Guide

## Overview

This document explains how the trip repository and related data structures work in the Wandrr app,
and how to set up mock data for integration testing.

---

## Architecture Overview

### 1. Trip Repository Structure

```
TripRepository
├── TripMetadataCollection (List of all trips for a user)
│   └── TripMetadata (Trip name, dates, budget, contributors)
│
└── ActiveTrip (TripData - Currently loaded trip)
    ├── TripMetadata
    ├── TransitCollection
    ├── LodgingCollection
    ├── ExpenseCollection
    ├── ItineraryCollection
    └── BudgetingModule
```

### 2. Data Flow

```
1. User Authentication
   └── TripManagementBloc._onStartup()
       └── TripRepositoryImplementation.createInstance()
           ├── Load TripMetadataCollection from Firestore
           └── Load supported currencies from assets

2. User Selects/Creates Trip
   └── TripManagementBloc._onLoadTrip()
       └── TripRepository.loadTrip()
           ├── Create ApiServicesRepository
           └── TripDataModelImplementation.createInstance()
               ├── Load TransitCollection
               ├── Load LodgingCollection
               ├── Load ExpenseCollection
               ├── Create ItineraryCollection
               └── Create BudgetingModule
```

---

## Key Components

### TripRepositoryImplementation

**Location:** `lib/data/trip/implementations/trip_repository.dart`

**Responsibilities:**

- Manages trip metadata collection for current user
- Loads/unloads active trip
- Subscribes to trip metadata updates/deletions
- Provides access to supported currencies

**Key Methods:**

```dart
static Future<TripRepositoryImplementation> createInstance
(
{
required
String
userName,
required AppLocalizations appLocalizations,
})

Future loadTrip(
TripMetadataFacade tripMetadata,
ApiServicesRepositoryFacade apiServicesRepository,
)

Future unloadActiveTrip()
```

### TripDataModelImplementation

**Location:** `lib/data/trip/implementations/trip_data.dart`

**Responsibilities:**

- Represents a single loaded trip
- Manages all collections within the trip
- Coordinates between different data modules

**Key Collections:**

```dart
ModelCollectionModifier<TransitFacade> transitCollection

ModelCollectionModifier<LodgingFacade> lodgingCollection

ModelCollectionModifier<ExpenseFacade> expenseCollection

ItineraryCollection itineraryCollection

BudgetingModule budgetingModule
```

---

## Firestore Data Structure

### Collection Names

**Location:** `lib/data/trip/implementations/collection_names.dart`

```dart
class FirestoreCollections {
  static const tripMetadataCollectionName = 'trips';
  static const tripCollectionName = 'trip_data';
  static const transitCollectionName = 'transits';
  static const lodgingCollectionName = 'lodgings';
  static const expenseCollectionName = 'expenses';
// ... other collections
}
```

### Firestore Structure

```
/trips (TripMetadataCollection)
  /{tripId}
    - tripName: "European Adventure"
    - startDate: Timestamp
    - endDate: Timestamp
    - budget: { amount: 5000, currency: "USD" }
    - contributors: ["user1@example.com", "user2@example.com"]
    - thumbnailIndex: 0

/trip_data
  /{tripId}
    (This document may contain summary data)
    
    /transits (TransitCollection)
      /{transitId}
        - transitOption: "flight"
        - departureLocation: { name, city, country }
        - departureDateTime: Timestamp
        - arrivalLocation: { name, city, country }
        - arrivalDateTime: Timestamp
        - operator: "Air France"
        - confirmationId: "AF123456"
        - notes: "Window seat"
        - expense: { linked expense data }
    
    /lodgings (LodgingCollection)
      /{lodgingId}
        - location: { name, city, country }
        - checkinDateTime: Timestamp
        - checkoutDateTime: Timestamp
        - confirmationId: "HTL789"
        - notes: "Room 305"
        - expense: { linked expense data }
    
    /expenses (ExpenseCollection)
      /{expenseId}
        - title: "Museum Tickets"
        - amount: 50
        - currency: "EUR"
        - category: "entertainment"
        - paidBy: { "user1": 50, "user2": 0 }
        - splitBy: ["user1", "user2"]
    
    /itineraries (ItineraryCollection)
      /{date}
        - notes: [{ id, content }]
        - checklists: [{ id, items }]
        - sights: [{ id, name, location, visitTime, description }]
```

---

## Mock Data Setup for Integration Tests

### Current Limitations

The integration tests currently **DO NOT** create actual Firestore data because:

1. **FakeFirebaseFirestore** doesn't integrate with the real Firebase initialization
2. Tests use **MethodChannel mocks** for Firebase Core and Remote Config
3. The app's repository queries real Firestore (or mocked channels), not FakeFirebaseFirestore
   instances

### What Tests Currently Verify

✅ **UI Structure**

- Widgets exist and are rendered
- Navigation works
- Tab switching functions
- Buttons are enabled/disabled correctly

✅ **User Interactions**

- Tapping buttons
- Scrolling
- Entering text
- Selecting options

❌ **Data Validation** (Not Currently Tested)

- Actual trip data displayed
- Timeline item sorting with real data
- Data persistence
- CRUD operations on entities

---

## Solution: Create Mock Trip Data

### Option 1: Pre-populate FakeFirebaseFirestore (Recommended for Unit Tests)

This approach works for **widget tests** where you can inject dependencies.

```dart
// In test setup
final firestore = FakeFirebaseFirestore();

// Add trip metadata
await
firestore.collection
('trips
'
)
.doc('test_trip_001').set({
'tripName': 'Test Trip',
'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
'endDate': Timestamp.fromDate(DateTime(2025, 6, 5)),
'budget': {'amount': 5000, 'currency': 'USD'},
'contributors': ['test@example.com'],
'thumbnailIndex': 0,
});

// Add transits
await firestore
    .collection('trip_data')
    .doc('test_trip_001')
    .collection('transits')
    .doc('transit_001')
    .set({
'transitOption': 'flight',
'departureLocation': {
'name': 'JFK Airport',
'city': 'New York',
'country': 'USA',
},
'departureDateTime': Timestamp.fromDate(DateTime(2025, 6, 1, 8, 0)),
'arrivalLocation': {
'name': 'CDG Airport',
'city': 'Paris',
'country': 'France',
},
'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 6, 1, 22, 0)),
'operator': 'Air France',
'confirmationId': 'AF123456',
'notes': 'Window seat',
});

// Add lodgings
await firestore
    .collection('trip_data')
    .doc('test_trip_001')
    .collection('lodgings')
    .doc('lodging_001')
    .set({
'location': {
'name': 'Hotel Le Marais',
'city': 'Paris',
'country': 'France',
},
'checkinDateTime': Timestamp.fromDate(DateTime(2025, 6, 1, 23, 30)),
'checkoutDateTime': Timestamp.fromDate(DateTime(2025, 6, 3, 11, 0)),
'confirmationId': 'HLM789',
'notes': 'Room 305',
});

// Then inject this firestore into your widget
await tester.pumpWidget(
MultiProvider(
providers: [
Provider<FirebaseFirestore>.value(value: firestore),
// ... other providers
],
child: MyApp()
,
)
,
);
```

### Option 2: Mock at MethodChannel Level (Current Approach)

For **integration tests** that run the full app, you need to mock at the channel level or use a test
Firestore emulator.

**Challenges:**

- firebase_auth_mocks and fake_cloud_firestore don't integrate automatically
- Need to intercept TripRepository creation
- Would require significant refactoring to inject dependencies

**Possible Solutions:**

#### A. Use Firebase Emulator Suite

```bash
# Start Firestore emulator
firebase emulators:start --only firestore

# Configure app to use emulator in test mode
if (kDebugMode && isTestMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

Then populate emulator with test data before running tests.

#### B. Add Test-Specific Repository Factory

Refactor to allow dependency injection:

```dart
// In TripRepository
static Future<TripRepositoryImplementation> createInstance
(
{
required
String
userName,
required AppLocalizations appLocalizations,
FirebaseFirestore? firestoreInstance, // Add optional parameter
}) async {
var firestore = firestoreInstance ?? FirebaseFirestore.instance;
var tripsCollectionReference = firestore.collection('trips');
// ... rest of implementation
}
```

Then in tests:

```dart

final mockFirestore = FakeFirebaseFirestore();
// Populate mockFirestore with test data
final repository = await
TripRepositoryImplementation.createInstance
(
userName: 'test@example.com',
appLocalizations: localizations,
firestoreInstance:
mockFirestore
,
);
```

---

## Current Test Strategy

Given the current architecture, the integration tests focus on:

### ✅ What Works Well

1. **UI Rendering Tests**
    - Verify widgets exist
    - Check layout responds to screen size
    - Validate navigation between screens

2. **User Interaction Tests**
    - Button clicks work
    - Tab switching functions
    - Date navigation operates correctly

3. **State Management Tests**
    - Buttons enable/disable appropriately
    - Navigation boundaries respected
    - Animations trigger correctly

### ⚠️ Current Limitations

1. **No Real Data Validation**
    - Can't verify specific trip entities display
    - Can't test data sorting with known values
    - Can't validate CRUD operations persist

2. **Mock Data Not Loaded**
    - Timeline may be empty
    - Lodgings/transits not present
    - Sights/notes/checklists missing

3. **Tests Pass Without Data**
    - Tests check for widget types, not content
    - Gracefully handles empty states
    - Logs warnings instead of failing

---

## Recommendations for Future Improvement

### Short Term (Easy)

1. **Add Firestore Emulator Tests**
    - Run separate test suite with emulator
    - Pre-populate with comprehensive test data
    - Validate actual data operations

2. **Create Widget Tests**
    - Test individual components in isolation
    - Inject mock repositories
    - Validate data display with known inputs

3. **Add More Logging**
    - Enhanced debug output in tests
    - Verify expected vs actual state
    - Identify missing data scenarios

### Long Term (Requires Refactoring)

1. **Dependency Injection**
    - Refactor repositories to accept optional Firestore instances
    - Allow bloc injection in widgets
    - Enable full mocking in integration tests

2. **Test Factories**
    - Create TripDataFactory for tests
    - Generate realistic test entities
    - Provide various test scenarios

3. **Enhanced Test Helpers**
    - Helper to create complete trip with entities
    - Methods to verify specific data displays
    - Utilities for complex assertions

---

## Helper Method: Create Test Trip Data

Here's a helper method you can add to `test_helpers.dart`:

```dart
/// Create comprehensive test trip data in Firestore
/// NOTE: Only works with dependency injection or emulator setup
static Future<void> createComprehensiveTestTrip

(
FakeFirebaseFirestore firestore,
String tripId,
String userEmail,
) async
{
// Trip Metadata
await
firestore.collection
('trips
'
)
.doc(tripId).set({
'tripName': 'European Adventure',
'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
'endDate': Timestamp.fromDate(DateTime(2025, 6, 5)),
'budget': {'amount': 5000, 'currency': 'USD'},
'contributors': [userEmail],
'thumbnailIndex': 0,
});

final tripData = firestore.collection('trip_data').doc(tripId);

// Day 1: Arrival - Flight + Taxi + Hotel Checkin
await tripData.collection('transits').doc('transit_001').set({
'transitOption': 'flight',
'departureLocation': {'name': 'JFK Airport', 'city': 'New York', 'country': 'USA'},
'departureDateTime': Timestamp.fromDate(DateTime(2025, 6, 1, 8, 0)),
'arrivalLocation': {'name': 'CDG Airport', 'city': 'Paris', 'country': 'France'},
'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 6, 1, 22, 0)),
'operator': 'Air France',
'confirmationId': 'AF123456',
});

await tripData.collection('transits').doc('transit_002').set({
'transitOption': 'taxi',
'departureLocation': {'name': 'CDG Airport'},
'departureDateTime': Timestamp.fromDate(DateTime(2025, 6, 1, 22, 30)),
'arrivalLocation': {'name': 'Hotel Le Marais'},
'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 6, 1, 23, 15)),
});

await tripData.collection('lodgings').doc('lodging_001').set({
'location': {'name': 'Hotel Le Marais', 'city': 'Paris', 'country': 'France'},
'checkinDateTime': Timestamp.fromDate(DateTime(2025, 6, 1, 23, 30)),
'checkoutDateTime': Timestamp.fromDate(DateTime(2025, 6, 3, 11, 0)),
'confirmationId': 'HLM789',
});

// Day 2: Sightseeing - Metro + Sights
await tripData.collection('transits').doc('transit_003').set({
'transitOption': 'train',
'departureLocation': {'name': 'République Station'},
'departureDateTime': Timestamp.fromDate(DateTime(2025, 6, 2, 9, 0)),
'arrivalLocation': {'name': 'Louvre-Rivoli Station'},
'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 6, 2, 9, 15)),
});

await tripData.collection('itineraries').doc('2025-06-02')
    .collection('sights').doc('sight_001').set({
'name': 'Louvre Museum',
'location': {'name': 'Musée du Louvre', 'city': 'Paris'},
'visitTime': Timestamp.fromDate(DateTime(2025, 6, 2, 10, 0)),
'description': 'Pre-booked time slot',
});

// Add more days as needed...
}
```

---

## Summary

### Current State

- ✅ Integration tests validate UI structure and user interactions
- ✅ Tests work without actual data (graceful handling)
- ❌ No validation of actual trip data display
- ❌ Mock trip data not loaded in integration tests

### To Add Data to Tests

1. **Use Firebase Emulator** (recommended for integration tests)
2. **Refactor for dependency injection** (allows widget tests with mocks)
3. **Create separate test suite** (for data-heavy validation)

### What You Can Do Now

- Run existing tests to validate UI/UX
- Use emulator for manual testing with real data
- Add widget tests for components with injected mock data
- Enhance logging to understand test behavior

The current tests are valuable for UI regression testing, but need architectural changes to validate
data operations fully.

