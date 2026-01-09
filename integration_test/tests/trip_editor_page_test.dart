import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list_item.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/presentation/trip/pages/home/trips_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/budgeting_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_navigator.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/bottom_nav_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';

import '../helpers/facade_matchers.dart';
import '../helpers/test_config.dart';
import '../helpers/test_helpers.dart';

/// Single comprehensive test for TripEditorPage layout characteristics
/// Tests both big layout and small layout based on context.isBigLayout
/// Also verifies isBigLayout setting based on screen width (>= 1000px)
Future<void> runTripEditorLayoutTest(
  WidgetTester tester,
) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  // Wait for TripsListView to be displayed
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripListView),
    timeout: const Duration(seconds: 5),
  );

  await _navigateToTripEditorPage(tester);

  // Wait for navigation animation and TripEditorPage to appear
  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10), // Allow extra time for Rive animation
  );

  // Verify TripEditorPage is displayed
  expect(find.byType(TripEditorPage), findsOneWidget);

  // Get screen size and verify isBigLayout setting
  final screenSize = TestHelpers.getScreenSize(tester);
  final expectedIsBigLayout =
      screenSize.width >= 1000.0; // TripProviderPageConstants.cutOffPageWidth

  // Get the BuildContext from the element
  final tripEditorFinder = find.byType(TripEditorPage);
  final BuildContext tripEditorContext = tester.element(tripEditorFinder);

  // Verify isBigLayout is set correctly based on screen width
  expect(tripEditorContext.isBigLayout, expectedIsBigLayout,
      reason:
          'isBigLayout should be $expectedIsBigLayout when screen width is >= 1000');

  if (tripEditorContext.isBigLayout) {
    // === BIG LAYOUT TESTS ===
    print(
        'Testing big layout characteristics (screen width: ${screenSize.width})');

    // Verify both ItineraryNavigator and BudgetingPage are displayed side by side
    expect(find.byType(ItineraryNavigator), findsOneWidget);
    expect(find.byType(BudgetingPage), findsOneWidget);

    // Verify they are in a Row layout (side by side)
    final itineraryRow = find.ancestor(
      of: find.byType(ItineraryNavigator),
      matching: find.byType(Row),
    );
    expect(itineraryRow, findsOneWidget,
        reason: 'ItineraryNavigator should be in a Row for big layout');

    final budgetingRow = find.ancestor(
      of: find.byType(BudgetingPage),
      matching: find.byType(Row),
    );
    expect(budgetingRow, findsOneWidget,
        reason: 'BudgetingPage should be in a Row for big layout');

    // Verify both widgets share the same Row ancestor
    final itineraryRowWidget = tester.widget<Row>(itineraryRow);
    final budgetingRowWidget = tester.widget<Row>(budgetingRow);
    expect(itineraryRowWidget, same(budgetingRowWidget),
        reason:
            'Both ItineraryNavigator and BudgetingPage should share the same Row ancestor for side-by-side layout');

    // Verify no BottomNavigationBar is displayed
    expect(find.byType(BottomNavBar), findsNothing,
        reason: 'BottomNavBar should not be displayed in big layout');

    // === FAB TESTS FOR BIG LAYOUT ===
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget,
        reason: 'FAB should be displayed in big layout');

    // Verify Scaffold has centerDocked FAB location
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.floatingActionButtonLocation,
        FloatingActionButtonLocation.centerDocked,
        reason: 'Scaffold should have centerDocked FAB location in big layout');
  } else {
    // === SMALL LAYOUT TESTS ===
    print(
        'Testing small layout characteristics (screen width: ${screenSize.width})');

    // Verify ItineraryNavigator is displayed by default
    expect(find.byType(ItineraryNavigator), findsOneWidget,
        reason:
            'ItineraryNavigator should be displayed by default in small layout');

    // Verify BudgetingPage is NOT displayed by default
    expect(find.byType(BudgetingPage), findsNothing,
        reason:
            'BudgetingPage should not be displayed by default in small layout');

    // Verify BottomNavigationBar is displayed
    expect(find.byType(BottomNavBar), findsOneWidget,
        reason: 'BottomNavBar should be displayed in small layout');

    // === NAVIGATION TESTS ===
    // Find BottomNavigationBar
    final bottomNavBar = find.byType(BottomNavBar);
    expect(bottomNavBar, findsOneWidget);

    // Find icon for budgeting (adjust icon based on your implementation)
    final budgetIcon = find.descendant(
      of: bottomNavBar,
      matching: find.byIcon(Icons.wallet_travel_rounded),
    );

    await TestHelpers.tapWidget(tester, budgetIcon);

    // Verify BudgetingPage is now displayed after navigation
    expect(find.byType(BudgetingPage), findsOneWidget,
        reason:
            'BudgetingPage should be displayed after navigation in small layout');

    // Verify ItineraryNavigator is NOT displayed after navigation to budgeting
    expect(find.byType(ItineraryNavigator), findsNothing,
        reason:
            'ItineraryNavigator should not be displayed when BudgetingPage is active in small layout');

    // === NAVIGATION BACK TESTS ===
    // Find icon for itinerary (adjust icon based on your implementation)
    final itineraryIcon = find.descendant(
      of: bottomNavBar,
      matching: find.byIcon(Icons.travel_explore_rounded),
    );

    await TestHelpers.tapWidget(tester, itineraryIcon);

    // Verify ItineraryNavigator is displayed again after navigation back
    expect(find.byType(ItineraryNavigator), findsOneWidget,
        reason:
            'ItineraryNavigator should be displayed after navigating back in small layout');

    // Verify BudgetingPage is NOT displayed after navigation back
    expect(find.byType(BudgetingPage), findsNothing,
        reason:
            'BudgetingPage should not be displayed after navigating back to itinerary in small layout');

    // === FAB TESTS FOR SMALL LAYOUT ===
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget,
        reason: 'FAB should be displayed in small layout');

    // Verify Scaffold has centerDocked FAB location
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.floatingActionButtonLocation,
        FloatingActionButtonLocation.centerDocked,
        reason:
            'Scaffold should have centerDocked FAB location in small layout');
  }

  print('✅ TripEditorPage layout test completed successfully');
}

/// Test: Verify trip repository values match the createTestTrip setup
/// Checks all data created by TestHelpers.createTestTrip() in the repository
Future<void> runTripRepositoryValuesTest(WidgetTester tester) async {
  // Launch the app (already authenticated with test trip)
  await TestHelpers.pumpAndSettleApp(tester);

  await _navigateToTripEditorPage(tester);

  // Get repository and active trip
  final context = tester.element(find.byType(TripEditorPage));
  final tripRepo = RepositoryProvider.of<TripRepositoryFacade>(context);
  final trip = tripRepo.activeTrip!;
  const tripId = 'test_trip_123';
  const defaultCurrency = 'EUR';
  final contributors = [TestConfig.testEmail, TestConfig.tripMateUserName];

  print('✓ Verifying trip repository values for createTestTrip setup');
  print('✓ Creating expected facade instances for comparison...');

  // === CREATE EXPECTED EXPENSE FACADES ===
  // Pure expenses only (transit/lodging/sight expenses are embedded in their respective collections)

  // Pure expenses
  final expectedDinnerExpense = StandaloneExpense(
    tripId: tripId,
    title: 'Dinner at Le Comptoir',
    expense: ExpenseFacade(
      currency: defaultCurrency,
      paidBy: {TestConfig.testEmail: 45.0},
      splitBy: contributors,
      dateTime: DateTime(2025, 9, 24, 20, 0),
      description: 'French cuisine',
    ),
    category: ExpenseCategory.food,
  );

  final expectedSouvenirsExpense = StandaloneExpense(
    tripId: tripId,
    title: 'Souvenirs from Louvre',
    expense: ExpenseFacade(
      currency: defaultCurrency,
      paidBy: {TestConfig.testEmail: 25.0},
      splitBy: contributors,
      dateTime: DateTime(2025, 9, 25, 12, 0),
      description: 'Gift cards',
    ),
    category: ExpenseCategory.other,
  );

  final expectedGroceriesExpense = StandaloneExpense(
    tripId: tripId,
    title: 'Groceries',
    expense: ExpenseFacade(
      currency: defaultCurrency,
      paidBy: {TestConfig.testEmail: 15.5},
      splitBy: contributors,
      dateTime: DateTime(2025, 9, 26),
      description: 'Snacks for the bus',
    ),
    category: ExpenseCategory.food,
  );

  // === CREATE EXPECTED LOCATION FACADES ===
  // London Airport
  final londonAirportDocument = {
    'name': 'London Airport',
    'city': 'London',
    'iata': 'YXU',
  };
  final expectedLondonAirportContext =
      AirportLocationContext.fromDocument(londonAirportDocument);
  final expectedLondonAirport = LocationFacade(
    latitude: 51.5074,
    longitude: -0.1278,
    context: expectedLondonAirportContext,
  );

  // Paris Airport
  final parisAirportDocument = {
    'name': 'Charles de Gaulle International Airport',
    'city': 'Paris (Roissy-en-France, Val-d\'Oise)',
    'iata': 'CDG',
  };
  final expectedParisAirportContext =
      AirportLocationContext.fromDocument(parisAirportDocument);
  final expectedParisAirport = LocationFacade(
    latitude: 48.8566,
    longitude: 2.3522,
    context: expectedParisAirportContext,
  );

  // Paris City
  final parisCityDocument = {
    'type': 'city',
    'locationType': 'city',
    'class': 'place',
    'name': 'Paris',
    'address': 'Paris, Île-de-France, France',
    'boundingbox': {
      'maxLat': 48.9021,
      'minLat': 48.8156,
      'maxLon': 2.4699,
      'minLon': 2.2242
    },
    'place_id': 'paris_city',
    'city': 'Paris',
    'state': 'Île-de-France',
    'country': 'France',
  };
  final expectedParisCityContext =
      GeoLocationApiContext.fromDocument(parisCityDocument);
  final expectedParisCity = LocationFacade(
    latitude: 48.8566,
    longitude: 2.3522,
    context: expectedParisCityContext,
  );

  // Versailles
  final versaillesDocument = {
    'type': 'town',
    'locationType': 'city',
    'class': 'place',
    'name': 'Versailles',
    'address': 'Versailles, Île-de-France, France',
    'boundingbox': {
      'maxLat': 48.8200,
      'minLat': 48.7900,
      'maxLon': 2.1500,
      'minLon': 2.1200
    },
    'place_id': 'versailles_town',
    'city': 'Versailles',
    'state': 'Île-de-France',
    'country': 'France',
  };
  final expectedVersaillesContext =
      GeoLocationApiContext.fromDocument(versaillesDocument);
  final expectedVersailles = LocationFacade(
    latitude: 48.8049,
    longitude: 2.1204,
    context: expectedVersaillesContext,
  );

  // Brussels
  final brusselsDocument = {
    'type': 'city',
    'locationType': 'city',
    'class': 'place',
    'name': 'Brussels',
    'address': 'Brussels, Brussels-Capital, Belgium',
    'boundingbox': {
      'maxLat': 50.8800,
      'minLat': 50.8300,
      'maxLon': 4.4300,
      'minLon': 4.3100
    },
    'place_id': 'brussels_city',
    'city': 'Brussels',
    'state': 'Brussels-Capital',
    'country': 'Belgium',
  };
  final expectedBrusselsContext =
      GeoLocationApiContext.fromDocument(brusselsDocument);
  final expectedBrussels = LocationFacade(
    latitude: 50.8503,
    longitude: 4.3517,
    context: expectedBrusselsContext,
  );

  // Amsterdam
  final amsterdamDocument = {
    'type': 'city',
    'locationType': 'city',
    'class': 'place',
    'name': 'Amsterdam',
    'address': 'Amsterdam, North Holland, Netherlands',
    'boundingbox': {
      'maxLat': 52.4200,
      'minLat': 52.3500,
      'maxLon': 5.0000,
      'minLon': 4.8300
    },
    'place_id': 'amsterdam_city',
    'city': 'Amsterdam',
    'state': 'North Holland',
    'country': 'Netherlands',
  };
  final expectedAmsterdamContext =
      GeoLocationApiContext.fromDocument(amsterdamDocument);
  final expectedAmsterdam = LocationFacade(
    latitude: 52.3676,
    longitude: 4.9041,
    context: expectedAmsterdamContext,
  );

  // Eiffel Tower
  final eiffelTowerDocument = {
    'type': 'attraction',
    'locationType': 'attraction',
    'class': 'tourism',
    'name': 'Eiffel Tower',
    'address': 'Eiffel Tower, Paris, Île-de-France, France',
    'boundingbox': {
      'maxLat': 48.8584,
      'minLat': 48.8577,
      'maxLon': 2.2950,
      'minLon': 2.2942
    },
    'place_id': 'eiffel_tower',
    'city': 'Paris',
    'state': 'Île-de-France',
    'country': 'France',
  };
  final expectedEiffelTowerContext =
      GeoLocationApiContext.fromDocument(eiffelTowerDocument);
  final expectedEiffelTower = LocationFacade(
    latitude: 48.8584,
    longitude: 2.2945,
    context: expectedEiffelTowerContext,
  );

  // Louvre Museum
  final louvreDocument = {
    'type': 'attraction',
    'locationType': 'attraction',
    'class': 'tourism',
    'name': 'Louvre Museum',
    'address': 'Louvre Museum, Paris, Île-de-France, France',
    'boundingbox': {
      'maxLat': 48.8620,
      'minLat': 48.8600,
      'maxLon': 2.3400,
      'minLon': 2.3300
    },
    'place_id': 'louvre_museum',
    'city': 'Paris',
    'state': 'Île-de-France',
    'country': 'France',
  };
  final expectedLouvreContext =
      GeoLocationApiContext.fromDocument(louvreDocument);
  final expectedLouvre = LocationFacade(
    latitude: 48.8606,
    longitude: 2.3376,
    context: expectedLouvreContext,
  );

  // Atomium
  final atomiumDocument = {
    'type': 'attraction',
    'locationType': 'attraction',
    'class': 'tourism',
    'name': 'Atomium',
    'address': 'Atomium, Brussels, Brussels-Capital, Belgium',
    'boundingbox': {
      'maxLat': 50.8955,
      'minLat': 50.8940,
      'maxLon': 4.3420,
      'minLon': 4.3400
    },
    'place_id': 'atomium_brussels',
    'city': 'Brussels',
    'state': 'Brussels-Capital',
    'country': 'Belgium',
  };
  final expectedAtomiumContext =
      GeoLocationApiContext.fromDocument(atomiumDocument);
  final expectedAtomium = LocationFacade(
    latitude: 50.8950,
    longitude: 4.3414,
    context: expectedAtomiumContext,
  );

  // Rijksmuseum
  final rijksmuseumDocument = {
    'type': 'attraction',
    'locationType': 'attraction',
    'class': 'tourism',
    'name': 'Rijksmuseum',
    'address': 'Rijksmuseum, Amsterdam, North Holland, Netherlands',
    'boundingbox': {
      'maxLat': 52.3610,
      'minLat': 52.3590,
      'maxLon': 4.8860,
      'minLon': 4.8800
    },
    'place_id': 'rijksmuseum_amsterdam',
    'city': 'Amsterdam',
    'state': 'North Holland',
    'country': 'Netherlands',
  };
  final expectedRijksmuseumContext =
      GeoLocationApiContext.fromDocument(rijksmuseumDocument);
  final expectedRijksmuseum = LocationFacade(
    latitude: 52.3600,
    longitude: 4.8852,
    context: expectedRijksmuseumContext,
  );

  // === CREATE EXPECTED TRANSIT FACADES ===
  // Flight: London to Paris
  final expectedFlightExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 250.0},
    splitBy: contributors,
  );
  final expectedFlightTransit = TransitFacade(
    tripId: tripId,
    transitOption: TransitOption.flight,
    departureLocation: expectedLondonAirport,
    arrivalLocation: expectedParisAirport,
    departureDateTime: DateTime(2025, 9, 24, 8, 0),
    arrivalDateTime: DateTime(2025, 9, 24, 11, 0),
    expense: expectedFlightExpense,
    operator: 'Air France AF 542',
    confirmationId: 'AF123456',
    notes: 'Direct flight',
  );

  // Train: Paris to Versailles
  final expectedTrainExpense1 = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 7.5},
    splitBy: contributors,
  );
  final expectedTrainToVersailles = TransitFacade(
    tripId: tripId,
    transitOption: TransitOption.train,
    departureLocation: expectedParisCity,
    arrivalLocation: expectedVersailles,
    departureDateTime: DateTime(2025, 9, 25, 9, 0),
    arrivalDateTime: DateTime(2025, 9, 25, 10, 0),
    expense: expectedTrainExpense1,
    operator: 'RER C',
    notes: 'Regional train',
  );

  // Train return: Versailles to Paris
  final expectedTrainExpense2 = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 7.5},
    splitBy: contributors,
  );
  final expectedTrainFromVersailles = TransitFacade(
    tripId: tripId,
    transitOption: TransitOption.train,
    departureLocation: expectedVersailles,
    arrivalLocation: expectedParisCity,
    departureDateTime: DateTime(2025, 9, 25, 17, 0),
    arrivalDateTime: DateTime(2025, 9, 25, 18, 0),
    expense: expectedTrainExpense2,
    operator: 'RER C',
    notes: 'Return trip',
  );

  // Bus: Paris to Brussels
  final expectedBusExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 35.0},
    splitBy: contributors,
  );
  final expectedBusTransit = TransitFacade(
    tripId: tripId,
    transitOption: TransitOption.bus,
    departureLocation: expectedParisCity,
    arrivalLocation: expectedBrussels,
    departureDateTime: DateTime(2025, 9, 26, 22, 0),
    arrivalDateTime: DateTime(2025, 9, 27, 2, 30),
    expense: expectedBusExpense,
    operator: 'FlixBus',
    confirmationId: 'FLIX789',
    notes: 'Overnight bus',
  );

  // Rented vehicle: Brussels to Atomium
  final expectedRentedVehicleExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 60.0},
    splitBy: contributors,
  );
  final expectedRentedVehicleTransit = TransitFacade(
    tripId: tripId,
    transitOption: TransitOption.rentedVehicle,
    departureLocation: expectedBrussels,
    arrivalLocation: expectedAtomium,
    departureDateTime: DateTime(2025, 9, 27, 10, 0),
    arrivalDateTime: DateTime(2025, 9, 27, 10, 30),
    expense: expectedRentedVehicleExpense,
    operator: 'Hertz',
    confirmationId: 'HERTZ456',
    notes: 'Full day rental',
  );

  // Taxi: Atomium to Brussels
  final expectedTaxiExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 25.0},
    splitBy: contributors,
  );
  final expectedTaxiTransit = TransitFacade(
    tripId: tripId,
    transitOption: TransitOption.taxi,
    departureLocation: expectedAtomium,
    arrivalLocation: expectedBrussels,
    departureDateTime: DateTime(2025, 9, 27, 16, 0),
    arrivalDateTime: DateTime(2025, 9, 27, 16, 30),
    expense: expectedTaxiExpense,
    operator: 'Uber',
    notes: 'Quick ride',
  );

  // Ferry: Brussels to Amsterdam
  final expectedFerryExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 45.0},
    splitBy: contributors,
  );
  final expectedFerryTransit = TransitFacade(
    tripId: tripId,
    transitOption: TransitOption.ferry,
    departureLocation: expectedBrussels,
    arrivalLocation: expectedAmsterdam,
    departureDateTime: DateTime(2025, 9, 27, 18, 0),
    arrivalDateTime: DateTime(2025, 9, 27, 21, 0),
    expense: expectedFerryExpense,
    operator: 'P&O Ferries',
    confirmationId: 'PO999',
    notes: 'Scenic route',
  );

  // Walk: Amsterdam to Rijksmuseum
  final expectedWalkExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 0.0},
    splitBy: contributors,
  );
  final expectedWalkTransit = TransitFacade(
    tripId: tripId,
    transitOption: TransitOption.walk,
    departureLocation: expectedAmsterdam,
    arrivalLocation: expectedRijksmuseum,
    departureDateTime: DateTime(2025, 9, 28, 9, 0),
    arrivalDateTime: DateTime(2025, 9, 28, 9, 30),
    expense: expectedWalkExpense,
    notes: 'Morning stroll',
  );

  // Public transport: Rijksmuseum to Amsterdam
  final expectedPublicTransportExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 3.0},
    splitBy: contributors,
  );
  final expectedPublicTransportTransit = TransitFacade(
    tripId: tripId,
    transitOption: TransitOption.publicTransport,
    departureLocation: expectedRijksmuseum,
    arrivalLocation: expectedAmsterdam,
    departureDateTime: DateTime(2025, 9, 28, 14, 0),
    arrivalDateTime: DateTime(2025, 9, 28, 14, 30),
    expense: expectedPublicTransportExpense,
    operator: 'Amsterdam Metro',
    notes: 'Metro line 52',
  );

  // === CREATE EXPECTED LODGING FACADES ===
  // Paris hotel
  final expectedParisLodgingExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 450.0},
    splitBy: contributors,
  );
  final expectedParisLodging = LodgingFacade(
    tripId: tripId,
    location: expectedParisCity,
    checkinDateTime: DateTime(2025, 9, 24, 14, 0),
    checkoutDateTime: DateTime(2025, 9, 26, 11, 0),
    expense: expectedParisLodgingExpense,
    confirmationId: 'PARIS-HTL-001',
    notes: 'City center, 2 nights',
  );

  // Brussels hotel (overnight)
  final expectedBrusselsLodgingExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 120.0},
    splitBy: contributors,
  );
  final expectedBrusselsLodging = LodgingFacade(
    tripId: tripId,
    location: expectedBrussels,
    checkinDateTime: DateTime(2025, 9, 27, 3, 0),
    checkoutDateTime: DateTime(2025, 9, 28, 10, 0),
    expense: expectedBrusselsLodgingExpense,
    confirmationId: 'BRU-HTL-789',
    notes: 'Brussels hotel, 1 night',
  );

  // Amsterdam hostel
  final expectedAmsterdamLodgingExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 60.0},
    splitBy: contributors,
  );
  final expectedAmsterdamLodging = LodgingFacade(
    tripId: tripId,
    location: expectedAmsterdam,
    checkinDateTime: DateTime(2025, 9, 28, 14, 0),
    checkoutDateTime: DateTime(2025, 9, 29, 11, 0),
    expense: expectedAmsterdamLodgingExpense,
    confirmationId: 'AMS-HSTL-123',
    notes: 'Budget hostel',
  );

  // === CREATE EXPECTED SIGHT FACADES ===
  // Eiffel Tower sight
  final expectedEiffelTowerExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 26.0},
    splitBy: contributors,
  );
  final expectedEiffelTowerSight = SightFacade(
    tripId: tripId,
    name: 'Eiffel Tower',
    day: DateTime(2025, 9, 24),
    expense: expectedEiffelTowerExpense,
    location: expectedEiffelTower,
    visitTime: DateTime(2025, 9, 24, 15, 30),
    description: 'Iconic landmark',
  );

  // Palace of Versailles sight
  final expectedVersaillesExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 20.0},
    splitBy: contributors,
  );
  final expectedVersaillesSight = SightFacade(
    tripId: tripId,
    name: 'Palace of Versailles',
    day: DateTime(2025, 9, 25),
    expense: expectedVersaillesExpense,
    location: expectedVersailles,
    visitTime: DateTime(2025, 9, 25, 10, 30),
    description: 'Royal palace',
  );

  // Louvre Museum sight
  final expectedLouvreExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 17.0},
    splitBy: contributors,
  );
  final expectedLouvreSight = SightFacade(
    tripId: tripId,
    name: 'Louvre Museum',
    day: DateTime(2025, 9, 25),
    expense: expectedLouvreExpense,
    location: expectedLouvre,
    visitTime: DateTime(2025, 9, 25, 13, 0),
    description: 'Art museum',
  );

  // Atomium sight
  final expectedAtomiumExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 16.0},
    splitBy: contributors,
  );
  final expectedAtomiumSight = SightFacade(
    tripId: tripId,
    name: 'Atomium',
    day: DateTime(2025, 9, 27),
    expense: expectedAtomiumExpense,
    location: expectedAtomium,
    visitTime: DateTime(2025, 9, 27, 11, 0),
    description: 'Brussels landmark',
  );

  // Rijksmuseum sight
  final expectedRijksmuseumExpense = ExpenseFacade(
    currency: defaultCurrency,
    paidBy: {TestConfig.testEmail: 22.5},
    splitBy: contributors,
  );
  final expectedRijksmuseumSight = SightFacade(
    tripId: tripId,
    name: 'Rijksmuseum',
    day: DateTime(2025, 9, 28),
    expense: expectedRijksmuseumExpense,
    location: expectedRijksmuseum,
    visitTime: DateTime(2025, 9, 28, 10, 0),
    description: 'Dutch art',
  );

  // === CREATE EXPECTED CHECKLIST FACADES ===
  // Day 1 checklist
  final expectedDay1ChecklistItems = [
    CheckListItem(item: 'Exchange currency', isChecked: false),
    CheckListItem(item: 'Buy metro pass', isChecked: false),
  ];
  final expectedDay1Checklist = CheckListFacade(
    tripId: tripId,
    title: 'Day 1',
    items: expectedDay1ChecklistItems,
  );

  // Day 2 checklist
  final expectedDay2ChecklistItems = [
    CheckListItem(item: 'Book tour', isChecked: true),
    CheckListItem(item: 'Pack snacks', isChecked: false),
  ];
  final expectedDay2Checklist = CheckListFacade(
    tripId: tripId,
    title: 'Day 2',
    items: expectedDay2ChecklistItems,
  );

  // Day 3 checklist
  final expectedDay3ChecklistItems = [
    CheckListItem(item: 'Pack bags', isChecked: false),
    CheckListItem(item: 'Hotel checkout', isChecked: false),
  ];
  final expectedDay3Checklist = CheckListFacade(
    tripId: tripId,
    title: 'Travel day',
    items: expectedDay3ChecklistItems,
  );

  // Day 4 checklist
  final expectedDay4ChecklistItems = [
    CheckListItem(item: 'Try waffles', isChecked: false),
    CheckListItem(item: 'Buy chocolates', isChecked: false),
  ];
  final expectedDay4Checklist = CheckListFacade(
    tripId: tripId,
    title: 'Brussels',
    items: expectedDay4ChecklistItems,
  );

  // Day 5 checklist
  final expectedDay5ChecklistItems = [
    CheckListItem(item: 'Buy souvenirs', isChecked: false),
    CheckListItem(item: 'Pack bags', isChecked: false),
  ];
  final expectedDay5Checklist = CheckListFacade(
    tripId: tripId,
    title: 'Last day',
    items: expectedDay5ChecklistItems,
  );

  // === CREATE EXPECTED NOTES ===
  // Day 1 notes
  final expectedDay1Notes = [
    Note('Arrive from London'),
    Note('Check in'),
    Note('Visit Eiffel Tower'),
  ];

  // Day 2 notes
  final expectedDay2Notes = [
    Note('Versailles trip'),
    Note('Louvre visit'),
    Note('Dinner'),
  ];

  // Day 3 notes
  final expectedDay3Notes = [
    Note('Morning in Paris'),
    Note('Check out'),
    Note('Night bus to Brussels'),
  ];

  // Day 4 notes
  final expectedDay4Notes = [
    Note('Early arrival'),
    Note('Rest'),
    Note('Visit Atomium'),
    Note('Ferry to Amsterdam'),
  ];

  // Day 5 notes
  final expectedDay5Notes = [
    Note('Final day'),
    Note('Museum visit'),
    Note('Canal walk'),
    Note('Departure prep'),
  ];

  print('✓ Expected facade instances created');

  // === VERIFY TRIP METADATA ===
  var expectedTripMetadata = TripMetadataFacade(
    id: tripId,
    name: 'European Adventure',
    startDate: DateTime(2025, 9, 24),
    endDate: DateTime(2025, 9, 29),
    budget: Money(currency: 'EUR', amount: 800),
    contributors: contributors,
    thumbnailTag: 'urban',
  );
  expect(trip.tripMetadata, expectedTripMetadata,
      reason: 'Trip metadata should match expected facade');

  print('✓ Trip metadata verified');

  // === VERIFY TRANSITS ===
  // Day 1: September 24 - Flight from London to Paris
  final day1Itinerary =
      trip.itineraryCollection.getItineraryForDay(DateTime(2025, 9, 24));
  expect(day1Itinerary.transits.length, 1,
      reason: 'Day 1 should have 1 transit (flight)');
  final flight = day1Itinerary.transits.single;
  expect(flight, matchesTransit(expectedFlightTransit),
      reason: 'Day 1 flight entry from London to Paris is incorrect');

  // Day 2: September 25 - Train from Paris to Versailles (2 transits)
  final day2Itinerary =
      trip.itineraryCollection.getItineraryForDay(DateTime(2025, 9, 25));
  expect(day2Itinerary.transits.length, 2,
      reason: 'Day 2 should have 2 transits (train to/from Versailles)');
  final trainToVersailles = day2Itinerary.transits.first;
  expect(trainToVersailles, matchesTransit(expectedTrainToVersailles),
      reason: 'Day 2 train to Versailles entry is incorrect');

  final trainFromVersailles = day2Itinerary.transits.last;
  expect(trainFromVersailles, matchesTransit(expectedTrainFromVersailles),
      reason: 'Day 2 train from Versailles entry is incorrect');

  // Day 3: September 26 - Bus from Paris to Brussels (overnight)
  final day3Itinerary =
      trip.itineraryCollection.getItineraryForDay(DateTime(2025, 9, 26));
  expect(day3Itinerary.transits.length, 1,
      reason: 'Day 3 should have 1 transit (bus)');
  final bus = day3Itinerary.transits.single;
  expect(bus, matchesTransit(expectedBusTransit),
      reason: 'Day 3 bus entry is incorrect');

  // Day 4: September 27 - Arrival at brussels(overnight journey), Rented vehicle, taxi, ferry (4 transits)
  final day4Itinerary =
      trip.itineraryCollection.getItineraryForDay(DateTime(2025, 9, 27));
  expect(day4Itinerary.transits.length, 4,
      reason:
          'Day 4 should have 4 transits (arrival at brussels(overnight journey), rented vehicle, taxi, ferry)');
  final day4Transits = day4Itinerary.transits.toList();
  final overnightJourneyArrival = day4Transits[0];
  expect(overnightJourneyArrival, matchesTransit(expectedBusTransit),
      reason: 'Day 4 overnight journey arrival is incorrect');

  final rentedVehicle = day4Transits[1];
  expect(rentedVehicle, matchesTransit(expectedRentedVehicleTransit),
      reason: 'Day 4 rented vehicle entry is incorrect');

  final taxi = day4Transits[2];
  expect(taxi, matchesTransit(expectedTaxiTransit),
      reason: 'Day 4 taxi entry is incorrect');

  final ferry = day4Transits[3];
  expect(ferry, matchesTransit(expectedFerryTransit),
      reason: 'Day 4 ferry entry is incorrect');

  // Day 5: September 28 - Walk, public transport (2 transits)
  final day5Itinerary =
      trip.itineraryCollection.getItineraryForDay(DateTime(2025, 9, 28));
  expect(day5Itinerary.transits.length, 2,
      reason: 'Day 5 should have 2 transits (walk, public transport)');
  final day5Transits = day5Itinerary.transits.toList();
  final walk = day5Transits[0];
  expect(walk, matchesTransit(expectedWalkTransit),
      reason: 'Day 5 walk entry is incorrect');

  final publicTransport = day5Transits[1];
  expect(publicTransport, matchesTransit(expectedPublicTransportTransit),
      reason: 'Day 5 public transport entry is incorrect');

  print('✓ All transits verified for itineraries');

  // === VERIFY TRANSIT COLLECTION ===
  final transitCollection = trip.transitCollection;
  expect(transitCollection.collectionItems.length, 9,
      reason: 'Transit collection should contain 9 transits');

  // Verify transits in collection match expected facade instances
  final expectedTransits = [
    expectedFerryTransit,
    expectedPublicTransportTransit,
    expectedWalkTransit,
    expectedTaxiTransit,
    expectedRentedVehicleTransit,
    expectedBusTransit,
    expectedFlightTransit,
    expectedTrainFromVersailles,
    expectedTrainToVersailles,
  ];

  // Check each expected transit has a match in the collection
  for (var expectedTransit in expectedTransits) {
    final matchFound = transitCollection.collectionItems.any(
      (actualTransit) =>
          matchesTransit(expectedTransit).matches(actualTransit, {}),
    );
    expect(matchFound, true,
        reason: 'Transit collection should contain transit: $expectedTransit');
  }

  print(
      '✓ Transit collection verified (9 transits with all properties matching expected facades)');

  // === VERIFY LODGING COLLECTION ===
  final lodgingCollection = trip.lodgingCollection;
  expect(lodgingCollection.collectionItems.length, 3,
      reason: 'Lodging collection should contain 3 lodgings');

  final expectedLodgings = [
    expectedParisLodging,
    expectedBrusselsLodging,
    expectedAmsterdamLodging,
  ];

  // Check each expected lodging has a match in the collection
  for (var expectedLodging in expectedLodgings) {
    final matchFound = lodgingCollection.collectionItems.any(
      (actualLodging) =>
          matchesLodging(expectedLodging).matches(actualLodging, {}),
    );
    expect(matchFound, true,
        reason: 'Lodging collection should contain lodging: $expectedLodging');
  }

  print(
      '✓ Lodging collection verified (3 lodgings with all properties matching expected facades)');

  // === VERIFY EXPENSES COLLECTION ===
  final expensesCollection = trip.expenseCollection.collectionItems;
  expect(expensesCollection.length, 3,
      reason: 'Expenses collection should contain 3 pure expenses');

  final expectedExpenses = [
    expectedGroceriesExpense,
    expectedDinnerExpense,
    expectedSouvenirsExpense
  ];

  // Check each expected expense has a match in the collection
  for (var expectedExpense in expectedExpenses) {
    final matchFound = expensesCollection.any(
      (actualExpense) =>
          matchesStandaloneExpense(expectedExpense).matches(actualExpense, {}),
    );
    expect(matchFound, true,
        reason: 'Expenses collection should contain expense: $expectedExpense');
  }

  print(
      '✓ Expenses collection verified (3 pure expenses with all properties matching expected facades)');

  // === VERIFY LODGINGS ===
  // Day 1-2: Paris hotel (multi-day)
  final parisLodgingItineraryDay1 = day1Itinerary.checkInLodging;
  expect(parisLodgingItineraryDay1, matchesLodging(expectedParisLodging),
      reason: 'Day 1 check-in to Paris should match expected');
  final parisLodgingItineraryDay2 = day2Itinerary.fullDayLodging;
  expect(parisLodgingItineraryDay2, matchesLodging(expectedParisLodging),
      reason: 'Day 2 full day lodging in Paris should match expected');

  // Day 3 (Sept 26): Paris hotel check-out
  final day3CheckOut = day3Itinerary.checkOutLodging;
  expect(day3CheckOut, matchesLodging(expectedParisLodging),
      reason: 'Day 3 check-out from Paris should match expected');

  // Day 4 (Sept 27): Brussels hotel check-in
  final day4CheckIn = day4Itinerary.checkInLodging;
  expect(day4CheckIn, matchesLodging(expectedBrusselsLodging),
      reason: 'Day 4 check-in to Brussels should match expected');

  // Day 5 (Sept 28): Brussels check-out, Amsterdam check-in
  final day5CheckOut = day5Itinerary.checkOutLodging;
  expect(day5CheckOut, matchesLodging(expectedBrusselsLodging),
      reason: 'Day 5 check-out from Brussels should match expected');
  final day5CheckIn = day5Itinerary.checkInLodging;
  expect(day5CheckIn, matchesLodging(expectedAmsterdamLodging),
      reason: 'Day 5 check-in to Amsterdam should match expected');

  // Day 6 (Sept 29): Amsterdam hotel check-in
  final day6Itinerary =
      trip.itineraryCollection.getItineraryForDay(DateTime(2025, 9, 29));
  final day6CheckOut = day6Itinerary.checkOutLodging;
  expect(day6CheckOut, matchesLodging(expectedAmsterdamLodging),
      reason: 'Day 6 check-out from Amsterdam should match expected');

  print('✓ All lodgings verified');

  // === VERIFY ITINERARY DATA ===
  // Day 1: September 24
  final day1PlanData = day1Itinerary.planData;
  expect(day1PlanData.sights.length, 1,
      reason: 'Day 1 should have 1 sight (Eiffel Tower)');
  final eiffelTower = day1PlanData.sights.first;
  expect(eiffelTower, matchesSight(expectedEiffelTowerSight),
      reason: 'Day 1 sight is incorrect');

  expect(
      listEquals(day1PlanData.notes,
          expectedDay1Notes.map((note) => note.text).toList()),
      true,
      reason: 'Day 1 notes should match');
  expect(listEquals(day1PlanData.checkLists, [expectedDay1Checklist]), true,
      reason: 'Day 1 checklist is incorrect');

  // Day 2: September 25 (Versailles trip)
  var day2PlanData = day2Itinerary.planData;
  expect(day2PlanData.sights.length, 2,
      reason: 'Day 2 should have 2 sights (Palace of Versailles, Louvre)');
  expect(day2PlanData.sights[0], matchesSight(expectedVersaillesSight),
      reason: 'Day 2 first sight should be Palace of Versailles');
  expect(day2PlanData.sights[1], matchesSight(expectedLouvreSight),
      reason: 'Day 2 second sight should be Louvre Museum');

  expect(
      listEquals(day2PlanData.notes,
          expectedDay2Notes.map((note) => note.text).toList()),
      true,
      reason: 'Day 2 notes should match');
  expect(listEquals(day2PlanData.checkLists, [expectedDay2Checklist]), true,
      reason: 'Day 2 checklist is incorrect');

  // Day 3: September 26 (travel day)
  final day3PlanData = day3Itinerary.planData;
  expect(day3PlanData.sights.length, 0, reason: 'Day 3 should have no sights');

  expect(
      listEquals(day3PlanData.notes,
          expectedDay3Notes.map((note) => note.text).toList()),
      true,
      reason: 'Day 3 notes should match');
  expect(listEquals(day3PlanData.checkLists, [expectedDay3Checklist]), true,
      reason: 'Day 3 checklist is incorrect');

  // Day 4: September 27 (Brussels)
  final day4PlanData = day4Itinerary.planData;
  expect(day4PlanData.sights.single, matchesSight(expectedAtomiumSight),
      reason: 'Day 4 sight should be Atomium');
  expect(
      listEquals(day4PlanData.notes,
          expectedDay4Notes.map((note) => note.text).toList()),
      true,
      reason: 'Day 4 notes should match');
  expect(listEquals(day4PlanData.checkLists, [expectedDay4Checklist]), true,
      reason: 'Day 4 checklist is incorrect');

  // Day 5: September 28 (Amsterdam)
  final day5PlanData = day5Itinerary.planData;
  expect(day5PlanData.sights.length, 1,
      reason: 'Day 5 should have 1 sight (Rijksmuseum)');
  expect(day5PlanData.sights.single, matchesSight(expectedRijksmuseumSight),
      reason: 'Day 5 sight should be Rijksmuseum');
  expect(
      listEquals(day5PlanData.notes,
          expectedDay5Notes.map((note) => note.text).toList()),
      true,
      reason: 'Day 5 notes should match');
  expect(listEquals(day5PlanData.checkLists, [expectedDay5Checklist]), true,
      reason: 'Day 5 checklist is incorrect');

  print('✓ All itinerary data (sights, notes, checklists) verified');
}

Future<void> _navigateToTripEditorPage(WidgetTester tester) async {
  // Find the test trip grid item by its name "European Adventure"
  final testTripItem = find.ancestor(
    of: find.text('European Adventure'),
    matching: find.byType(InkWell),
  );

  // Verify the test trip item is found
  expect(testTripItem, findsOneWidget,
      reason:
          'Test trip "European Adventure" should be displayed in TripsListView');

  // Click on the test trip item to navigate to TripEditorPage
  await TestHelpers.tapWidget(tester, testTripItem);
}
