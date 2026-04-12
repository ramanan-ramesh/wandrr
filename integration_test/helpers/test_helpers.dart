import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/app/pages/master_page/master_page.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/trip/pages/home/trips_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_navigator.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_viewer.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/bottom_nav_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import 'matchers.dart';
import 'test_config.dart';

class TestHelpers {
  /// Test credentials
  static const String testUsername = TestConfig.testEmail;
  static const String testPassword = TestConfig.testPassword;

  /// Pump the app and wait for animations to settle
  ///
  /// This method automatically waits for the native splash screen to complete
  /// before proceeding with the test.
  static Future<void> pumpAndSettleApp(WidgetTester tester) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(MasterPage(sharedPreferences));
    await tester.pumpAndSettle();
    // Wait for native splash screen to complete (Android/iOS)
    await _waitForNativeSplashScreen(tester);
    // Log device size after splash screen
    print(_getDeviceSizeDescription(tester));
  }

  static Future<void> navigateToTripEditorPage(WidgetTester tester) async {
    // Wait for TripsListView to appear
    await TestHelpers.waitForWidget(
      tester,
      find.byType(TripListView),
      timeout: const Duration(seconds: 5),
    );

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

    // Wait for TripEditorPage to appear
    await TestHelpers.waitForWidget(
      tester,
      find.byType(TripEditorPage),
      timeout: const Duration(seconds: 10),
    );
    print('[OK] Navigated to TripEditorPage for trip - "European Adventure"');
  }

  static AppLocalizations getAppLocalizations(WidgetTester tester, Type type) {
    final context = tester.element(find.byType(type));
    return AppLocalizations.of(context)!;
  }

  static TripRepositoryFacade getTripRepository(WidgetTester tester,
      {Type type = TripEditorPage}) {
    final context = tester.element(find.byType(type));
    return RepositoryProvider.of<TripRepositoryFacade>(context);
  }

  static ApiServicesRepositoryFacade getApiServicesRepository(
      WidgetTester tester,
      {Type type = TripEditorPage}) {
    final context = tester.element(find.byType(type));
    return RepositoryProvider.of<ApiServicesRepositoryFacade>(context);
  }

  /// Create a test trip for trip editor tests
  /// Create a 5-day test trip for integration tests (European tour)
  static Future<void> createTestTrip() async {
    final firestore = FirebaseFirestore.instance;

    // Test trip data
    final startDate = DateTime(2025, 9, 24);
    final endDate = DateTime(2025, 9, 29);
    const tripName = 'European Adventure';
    const defaultCurrency = 'EUR';
    final contributors = [TestConfig.testEmail, TestConfig.tripMateUserName];

    // Create trip metadata
    await firestore
        .collection(FirestoreCollections.tripMetadataCollectionName)
        .doc(TestConfig.testTripId)
        .set({
      'name': tripName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'thumbnailTag': 'urban',
      'contributors': contributors,
      'budget': '1500.00 EUR',
    });

    // === LOCATIONS ===
    final londonAirport = {
      'latLon': const GeoPoint(51.5074, -0.1278),
      'context': {
        'type': 'airport',
        'name': 'London Airport',
        'city': 'London',
        "iata": 'YXU',
        'locationType': 'airport',
      }
    };

    final parisAirport = {
      'latLon': const GeoPoint(48.8566, 2.3522),
      'context': {
        'type': 'airport',
        'name': 'Charles de Gaulle International Airport',
        'city': "Paris (Roissy-en-France, Val-d'Oise)",
        'iata': 'CDG',
        'locationType': 'airport',
      }
    };
    final amsterdamAirport = {
      'latLon': const GeoPoint(52.3779, 4.76389),
      'context': {
        'type': 'airport',
        'name': 'Amsterdam Airport Schiphol',
        'city': 'Amsterdam',
        'iata': 'AMS',
        'locationType': 'airport',
      }
    };

    // City locations
    final parisCity = {
      'latLon': const GeoPoint(48.8566, 2.3522),
      'context': {
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
      }
    };

    final versaillesLocation = {
      'latLon': const GeoPoint(48.8049, 2.1204),
      'context': {
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
      }
    };

    final brusselsLocation = {
      'latLon': const GeoPoint(50.8503, 4.3517),
      'context': {
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
      }
    };

    final amsterdamLocation = {
      'latLon': const GeoPoint(52.3676, 4.9041),
      'context': {
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
      }
    };

    // Attraction locations
    final eiffelTowerLocation = {
      'latLon': const GeoPoint(48.8584, 2.2945),
      'context': {
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
      }
    };

    final louvreLocation = {
      'latLon': const GeoPoint(48.8606, 2.3376),
      'context': {
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
      }
    };

    final atomiumLocation = {
      'latLon': const GeoPoint(50.8950, 4.3414),
      'context': {
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
      }
    };

    final rijksmuseumLocation = {
      'latLon': const GeoPoint(52.3600, 4.8852),
      'context': {
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
      }
    };

    final keukenhofLocation = {
      'latLon': const GeoPoint(52.3600, 4.8852),
      'context': {
        'type': 'attraction',
        'locationType': 'attraction',
        'class': 'tourism',
        'name': 'Keukenhof',
        'address':
            'Keukenhof flower show, Amsterdam, North Holland, Netherlands',
        'boundingbox': {
          'maxLat': 52.3610,
          'minLat': 52.3590,
          'maxLon': 4.8860,
          'minLon': 4.88
        },
        'place_id': 'keukenhof_flower_show_amsterdam',
        'city': 'Amsterdam',
        'state': 'North Holland',
        'country': 'Netherlands',
      }
    };

    var tripDataCollection = firestore
        .collection(FirestoreCollections.tripCollectionName)
        .doc(TestConfig.testTripId);

    var itineraryDataCollection = tripDataCollection
        .collection(FirestoreCollections.itineraryDataCollectionName);
    var lodgingCollection = tripDataCollection
        .collection(FirestoreCollections.lodgingCollectionName);
    var transitCollection = tripDataCollection
        .collection(FirestoreCollections.transitCollectionName);
    var expenseCollection = tripDataCollection
        .collection(FirestoreCollections.expenseCollectionName);

    // === TRANSITS===
    // Flight: London to Paris
    await transitCollection.add({
      'transitOption': 'flight',
      'departureLocation': londonAirport,
      'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 24, 8, 0)),
      'arrivalLocation': parisAirport,
      'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 24, 11, 0)),
      'operator': 'Air France AF 542',
      'confirmationId': 'AF123456',
      'totalExpense': {
        'currency': defaultCurrency,
        'category': 'flights',
        'paidBy': {TestConfig.testEmail: 250.0},
        'splitBy': contributors,
      },
      'notes': 'Direct flight',
    });

    // Train: Paris to Versailles
    await transitCollection.add({
      'transitOption': 'train',
      'departureLocation': parisCity,
      'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 25, 9, 0)),
      'arrivalLocation': versaillesLocation,
      'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 25, 10, 0)),
      'operator': 'RER C',
      'totalExpense': {
        'currency': defaultCurrency,
        'category': 'publicTransit',
        'paidBy': {TestConfig.testEmail: 7.5},
        'splitBy': contributors,
      },
      'notes': 'Regional train',
    });

    // Train return
    await transitCollection.add({
      'transitOption': 'train',
      'departureLocation': versaillesLocation,
      'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 25, 17, 0)),
      'arrivalLocation': parisCity,
      'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 25, 18, 0)),
      'operator': 'RER C',
      'totalExpense': {
        'currency': defaultCurrency,
        'category': 'publicTransit',
        'paidBy': {TestConfig.testEmail: 7.5},
        'splitBy': contributors,
      },
      'notes': 'Return trip',
    });

    // Bus: Paris to Brussels (overnight/multi-day)
    await transitCollection.add({
      'transitOption': 'bus',
      'departureLocation': parisCity,
      'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 26, 22, 0)),
      'arrivalLocation': brusselsLocation,
      'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 27, 2, 30)),
      'operator': 'FlixBus',
      'confirmationId': 'FLIX789',
      'totalExpense': {
        'currency': defaultCurrency,
        'category': 'publicTransit',
        'paidBy': {TestConfig.testEmail: 35.0},
        'splitBy': contributors,
      },
      'notes': 'Overnight bus',
    });

    // Rented vehicle
    await transitCollection.add({
      'transitOption': 'rentedVehicle',
      'departureLocation': brusselsLocation,
      'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 27, 10, 0)),
      'arrivalLocation': atomiumLocation,
      'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 27, 10, 30)),
      'operator': 'Hertz',
      'confirmationId': 'HERTZ456',
      'totalExpense': {
        'currency': defaultCurrency,
        'category': 'carRental',
        'paidBy': {TestConfig.testEmail: 60.0},
        'splitBy': contributors,
      },
      'notes': 'Full day rental',
    });

    // Taxi
    await transitCollection.add({
      'transitOption': 'taxi',
      'departureLocation': atomiumLocation,
      'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 27, 16, 0)),
      'arrivalLocation': brusselsLocation,
      'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 27, 16, 30)),
      'operator': 'Uber',
      'totalExpense': {
        'currency': defaultCurrency,
        'category': 'taxi',
        'paidBy': {TestConfig.testEmail: 25.0},
        'splitBy': contributors,
      },
      'notes': 'Quick ride',
    });

    // Ferry
    await transitCollection.add({
      'transitOption': 'ferry',
      'departureLocation': brusselsLocation,
      'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 27, 18, 0)),
      'arrivalLocation': amsterdamLocation,
      'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 27, 21, 0)),
      'operator': 'P&O Ferries',
      'confirmationId': 'PO999',
      'totalExpense': {
        'currency': defaultCurrency,
        'category': 'publicTransit',
        'paidBy': {TestConfig.testEmail: 45.0},
        'splitBy': contributors,
      },
      'notes': 'Scenic route',
    });

    // Walk
    await transitCollection.add({
      'transitOption': 'walk',
      'departureLocation': amsterdamLocation,
      'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 28, 9, 0)),
      'arrivalLocation': rijksmuseumLocation,
      'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 28, 9, 30)),
      'totalExpense': {
        'currency': defaultCurrency,
        'category': 'other',
        'paidBy': {TestConfig.testEmail: 0.0},
        'splitBy': contributors,
      },
      'notes': 'Morning stroll',
    });

    // Public transport
    await transitCollection.add({
      'transitOption': 'publicTransport',
      'departureLocation': rijksmuseumLocation,
      'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 28, 14, 0)),
      'arrivalLocation': amsterdamLocation,
      'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 28, 14, 30)),
      'operator': 'Amsterdam Metro',
      'totalExpense': {
        'currency': defaultCurrency,
        'category': 'publicTransit',
        'paidBy': {TestConfig.testEmail: 3.0},
        'splitBy': contributors,
      },
      'notes': 'Metro line 52',
    });

    // Flight: Amsterdam to London
    await transitCollection.add({
      'transitOption': 'flight',
      'departureLocation': amsterdamAirport,
      'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 29, 13, 0)),
      'arrivalLocation': londonAirport,
      'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 29, 15, 30)),
      'operator': 'British Airways BA 621',
      'confirmationId': 'BA345612',
      'totalExpense': {
        'currency': defaultCurrency,
        'category': 'flights',
        'paidBy': {TestConfig.testEmail: 200.0},
        'splitBy': contributors,
      },
      'notes': 'Direct flight',
    });

    // === LODGINGS ===
    // Multi-day lodging: Paris (2 nights)
    await lodgingCollection.add({
      'location': parisCity,
      'checkinDateTime': Timestamp.fromDate(DateTime(2025, 9, 24, 14, 0)),
      'checkoutDateTime': Timestamp.fromDate(DateTime(2025, 9, 26, 11, 0)),
      'confirmationId': 'PARIS-HTL-001',
      'expense': {
        'currency': defaultCurrency,
        'category': 'lodging',
        'paidBy': {TestConfig.testEmail: 450.0},
        'splitBy': contributors,
      },
      'notes': 'City center, 2 nights',
    });

    // Multi-day lodging: Brussels  (spans Sept 27-28)
    await lodgingCollection.add({
      'location': brusselsLocation,
      'checkinDateTime': Timestamp.fromDate(DateTime(2025, 9, 27, 3, 0)),
      'checkoutDateTime': Timestamp.fromDate(DateTime(2025, 9, 28, 10, 0)),
      'confirmationId': 'BRU-HTL-789',
      'expense': {
        'currency': defaultCurrency,
        'category': 'lodging',
        'paidBy': {TestConfig.testEmail: 120.0},
        'splitBy': contributors,
      },
      'notes': 'Brussels hotel, 1 night',
    });

    // Amsterdam hostel (check-in on Sept 28)
    await lodgingCollection.add({
      'location': amsterdamLocation,
      'checkinDateTime': Timestamp.fromDate(DateTime(2025, 9, 28, 14, 0)),
      'checkoutDateTime': Timestamp.fromDate(DateTime(2025, 9, 29, 11, 0)),
      'confirmationId': 'AMS-HSTL-123',
      'expense': {
        'currency': defaultCurrency,
        'category': 'lodging',
        'paidBy': {TestConfig.testEmail: 60.0},
        'splitBy': contributors,
      },
      'notes': 'Budget hostel',
    });

    // === ITINERARY DATA ===
    // Day 1: September 24
    await itineraryDataCollection.doc('24092025').set({
      'sights': [
        {
          'name': 'Eiffel Tower',
          'location': eiffelTowerLocation,
          'visitTime': Timestamp.fromDate(DateTime(2025, 9, 24, 15, 30)),
          'expense': {
            'currency': defaultCurrency,
            'category': 'sightseeing',
            'paidBy': {TestConfig.testEmail: 26.0},
            'splitBy': contributors,
          },
          'description': 'Iconic landmark',
        }
      ],
      'notes': ['Arrive from London', 'Check in', 'Visit Eiffel Tower'],
      'checkLists': [
        {
          'title': 'Day 1',
          'items': [
            {'item': 'Exchange currency', 'status': false},
            {'item': 'Buy metro pass', 'status': false},
          ]
        }
      ],
    });

    // Day 2: September 25
    await itineraryDataCollection.doc('25092025').set({
      'sights': [
        {
          'name': 'Palace of Versailles',
          'location': versaillesLocation,
          'visitTime': Timestamp.fromDate(DateTime(2025, 9, 25, 10, 30)),
          'expense': {
            'currency': defaultCurrency,
            'category': 'sightseeing',
            'paidBy': {TestConfig.testEmail: 20.0},
            'splitBy': contributors,
          },
          'description': 'Royal palace',
        },
        {
          'name': 'Louvre Museum',
          'location': louvreLocation,
          'visitTime': Timestamp.fromDate(DateTime(2025, 9, 25, 13, 0)),
          'expense': {
            'currency': defaultCurrency,
            'category': 'sightseeing',
            'paidBy': {TestConfig.testEmail: 17.0},
            'splitBy': contributors,
          },
          'description': 'Art museum',
        }
      ],
      'notes': ['Versailles trip', 'Louvre visit', 'Dinner'],
      'checkLists': [
        {
          'title': 'Day 2',
          'items': [
            {'item': 'Book tour', 'status': true},
            {'item': 'Pack snacks', 'status': false},
          ]
        }
      ],
    });

    // Day 3: September 26
    await itineraryDataCollection.doc('26092025').set({
      'sights': [],
      'notes': ['Morning in Paris', 'Check out', 'Night bus to Brussels'],
      'checkLists': [
        {
          'title': 'Travel day',
          'items': [
            {'item': 'Pack bags', 'status': false},
            {'item': 'Hotel checkout', 'status': false},
          ]
        }
      ],
    });

    // Day 4: September 27
    await itineraryDataCollection.doc('27092025').set({
      'sights': [
        {
          'name': 'Atomium',
          'location': atomiumLocation,
          'visitTime': Timestamp.fromDate(DateTime(2025, 9, 27, 11, 0)),
          'expense': {
            'currency': defaultCurrency,
            'category': 'sightseeing',
            'paidBy': {TestConfig.testEmail: 16.0},
            'splitBy': contributors,
          },
          'description': 'Brussels landmark',
        }
      ],
      'notes': ['Early arrival', 'Rest', 'Visit Atomium', 'Ferry to Amsterdam'],
      'checkLists': [
        {
          'title': 'Brussels',
          'items': [
            {'item': 'Try waffles', 'status': false},
            {'item': 'Buy chocolates', 'status': false},
          ]
        }
      ],
    });

    // Day 5: September 28
    await itineraryDataCollection.doc('28092025').set({
      'sights': [
        {
          'name': 'Rijksmuseum',
          'location': rijksmuseumLocation,
          'visitTime': Timestamp.fromDate(DateTime(2025, 9, 28, 10, 0)),
          'expense': {
            'currency': defaultCurrency,
            'category': 'sightseeing',
            'paidBy': {TestConfig.testEmail: 22.5},
            'splitBy': contributors,
          },
          'description': 'Dutch art',
        }
      ],
      'notes': ['Museum visit', 'Canal walk', 'Departure prep'],
      'checkLists': [
        {
          'title': 'Amsterdam exploration day',
          'items': [
            {'item': 'Buy souvenirs', 'status': false},
            {'item': 'Eat waffles', 'status': true},
          ]
        }
      ],
    });

    // Day 6: September 29
    await itineraryDataCollection.doc('29092025').set({
      'sights': [
        {
          'name': 'Keukenhof flower show',
          'location': keukenhofLocation,
          'visitTime': Timestamp.fromDate(DateTime(2025, 9, 29, 12, 0)),
          'expense': {
            'currency': defaultCurrency,
            'category': 'sightseeing',
            'paidBy': {TestConfig.testEmail: 40},
            'splitBy': contributors,
          },
          'description': 'Flower show',
        }
      ],
      'notes': ['Breakfast', 'Visit Keukenhof', 'Return home'],
      'checkLists': [
        {
          'title': 'Last day',
          'items': [
            {'item': 'Pack bags', 'status': false},
            {'item': 'Prepare journal', 'status': false},
          ]
        }
      ],
    });

    // === PURE EXPENSES (not linked to transits/lodgings/sights) ===
    // Restaurant meal on Day 1
    await expenseCollection.add({
      'title': 'Dinner at Le Comptoir',
      'category': 'food',
      'expense': {
        'currency': defaultCurrency,
        'paidBy': {TestConfig.testEmail: 45.0},
        'splitBy': contributors,
        'dateTime': Timestamp.fromDate(DateTime(2025, 9, 24, 20, 0)),
        'description': 'French cuisine',
      },
    });

    // Souvenirs on Day 2
    await expenseCollection.add({
      'title': 'Souvenirs from Louvre',
      'category': 'other',
      'expense': {
        'currency': defaultCurrency,
        'paidBy': {TestConfig.testEmail: 25.0},
        'splitBy': contributors,
        'dateTime': Timestamp.fromDate(DateTime(2025, 9, 25, 12, 0)),
        'description': 'Postcards and magnets',
      },
    });

    // Groceries on Day 3
    await expenseCollection.add({
      'title': 'Groceries',
      'category': 'food',
      'expense': {
        'currency': defaultCurrency,
        'paidBy': {TestConfig.testEmail: 15.5},
        'splitBy': contributors,
        'dateTime': Timestamp.fromDate(DateTime(2025, 9, 26)),
        'description': 'Snacks for the bus',
      },
    });

    print('✅ 5-day test trip created: ${TestConfig.testTripId}');
    print('   Route: London → Paris → Brussels → Amsterdam');
    print(
        '   Transits: flight, train, bus, rentedVehicle, taxi, ferry, walk, publicTransport');
    print('   Pure expenses: 3 (2 food, 1 other)');
  }

  /// Get the current device screen size
  static Size getScreenSize(WidgetTester tester) {
    return tester.view.physicalSize / tester.view.devicePixelRatio;
  }

  /// Check if the current device has a large screen (>= 1000px width)
  static bool isLargeScreen(WidgetTester tester) {
    final size = getScreenSize(tester);
    return size.width >= TestConfig.bigLayoutBreakpoint;
  }

  /// Enter text into a text field
  static Future<void> enterText(
      WidgetTester tester, Finder finder, String text) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Tap on a widget
  static Future<void> tapWidget(WidgetTester tester, Finder finder,
      {bool warnIfMissed = true}) async {
    await tester.tap(finder, warnIfMissed: warnIfMissed);
    await tester.pumpAndSettle();
  }

  /// Navigates the itinerary viewer to [date].
  /// Convenience alias for [navigateToItineraryTab] used in transit CRUD tests.
  static Future<void> navigateToDateInItineraryViewer(
          WidgetTester tester, DateTime date) =>
      navigateToItineraryTab(tester, date: date);

  static Future<void> navigateToBudgetingTab(WidgetTester tester) async {
    final bottomNavBar = find.descendant(
        of: find.byType(TripEditorPage), matching: find.byType(BottomNavBar));
    expect(bottomNavBar, findsOneWidget);

    final tabIconFinder = find.descendant(
      of: bottomNavBar,
      matching: find.byIcon(Icons.wallet_travel_rounded),
    );
    await TestHelpers.tapWidget(tester, tabIconFinder);
    print('  [OK] Switched to Budgeting tab');
  }

  static Future<void> navigateToItineraryTab(WidgetTester tester,
      {DateTime? date}) async {
    final bottomNavBar = find.descendant(
        of: find.byType(TripEditorPage), matching: find.byType(BottomNavBar));
    expect(bottomNavBar, findsOneWidget);

    final tabIconFinder = find.descendant(
      of: bottomNavBar,
      matching: find.byIcon(Icons.travel_explore_rounded),
    );
    print('  [OK] Switched to Itinerary tab');
    await TestHelpers.tapWidget(tester, tabIconFinder);
    if (date != null) {
      final repo = TestHelpers.getTripRepository(tester);
      final startDate = repo.activeTrip!.tripMetadata.startDate!;
      final stepsForward = date.difference(startDate).inDays;
      final nextDayButton = find.descendant(
          of: find.byType(ItineraryNavigator),
          matching: find.byIcon(Icons.chevron_right_rounded));
      for (var i = 0; i < stepsForward; i++) {
        await TestHelpers.tapWidget(tester, nextDayButton);
      }
      final itineraryViewer = find
          .byType(ItineraryViewer)
          .evaluate()
          .single
          .widget as ItineraryViewer;
      assert(itineraryViewer.itineraryDay.isOnSameDayAs(date));
      print('  [OK] Navigated to ${date.itineraryDateFormat} day in itinerary');
    }
  }

  /// Get the position of a widget
  static Offset getWidgetPosition(WidgetTester tester, Finder finder) {
    final renderBox = tester.renderObject<RenderBox>(finder);
    return renderBox.localToGlobal(Offset.zero);
  }

  /// Wait for a specific widget to appear
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));

      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }

    throw Exception('Widget not found within timeout: $finder');
  }

  static Future<void> selectDateRange(
      WidgetTester tester, DateTime tripStartDate, int numberOfDays,
      {required bool shouldOpenDateRangePickerDialog}) async {
    if (shouldOpenDateRangePickerDialog) {
      final dateRangePicker = find.byType(PlatformDateRangePicker);
      await TestHelpers.tapWidget(tester, dateRangePicker);
    }
    await TestHelpers.tapWidget(
        tester, find.text(tripStartDate.day.toString()));
    final tripEndDate = tripStartDate.add(Duration(days: numberOfDays));
    if (tripStartDate.month < tripEndDate.month) {
      await TestHelpers.tapWidget(tester, find.byIcon(Icons.navigate_next));
    }
    await TestHelpers.tapWidget(tester, find.text(tripEndDate.day.toString()));

    final doneButton = find.descendant(
      of: find.byType(CalendarDatePicker2WithActionButtons),
      matching: find.byIcon(Icons.done_rounded),
    );
    await TestHelpers.tapWidget(tester, doneButton, warnIfMissed: false);
  }

  static Future<void> pickDate(
      WidgetTester tester, Finder datePicker, String day,
      {DateTime? expectedStartDate, DateTime? expectedEndDate}) async {
    await TestHelpers.tapWidget(tester, datePicker);

    // Verify possible selectable dates
    if (expectedStartDate != null || expectedEndDate != null) {
      final calendarPicker =
          tester.widget<CalendarDatePicker2WithActionButtons>(
              find.byType(CalendarDatePicker2WithActionButtons));
      final calendarPickerConfig = calendarPicker.config;
      if (expectedStartDate != null) {
        expect(calendarPickerConfig.firstDate, matchesDay(expectedStartDate),
            reason: 'First possible selectable date should be trip start date');
      }
      if (expectedEndDate != null) {
        expect(calendarPickerConfig.lastDate, matchesDay(expectedEndDate),
            reason: 'Last possible selectable date should be trip end date');
      }
    }

    // Select day
    final lastDateButton = find.descendant(
        of: find.byType(CalendarDatePicker2WithActionButtons),
        matching: find.text(day));
    await TestHelpers.tapWidget(tester, lastDateButton);
    final confirmButton = find.descendant(
        of: find.byType(CalendarDatePicker2WithActionButtons),
        matching: find.text('OK'));
    await TestHelpers.tapWidget(tester, confirmButton, warnIfMissed: false);
  }

  /// Wait for native splash screen to complete (Private helper)
  ///
  /// The Android/iOS native splash screen runs before Flutter's runApp() is called.
  /// On Android (MainActivity.kt), there's a 3-second animation with:
  /// - Spaceship animation (3 seconds)
  /// - Logo fade out (2 seconds)
  /// - Text fade in (1 second)
  /// Total delay before FlutterAppActivity starts: 3 seconds
  ///
  /// This method is called automatically by pumpAndSettleApp().
  static Future<void> _waitForNativeSplashScreen(WidgetTester tester) async {
    // The native splash screen takes ~3 seconds on Android
    // We wait for any Flutter widget to appear, which indicates the Flutter
    // engine has started and the native splash is complete

    // Give some initial time for native splash to potentially start
    await tester.pump(const Duration(milliseconds: 100));

    // Now wait for Flutter to actually render something
    // This is better than a fixed 3-second wait because:
    // 1. On some devices it might be faster
    // 2. On emulators it might take longer
    // 3. We verify that Flutter has actually started

    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  /// Get a description of the current device size for logging
  static String _getDeviceSizeDescription(WidgetTester tester) {
    final size = getScreenSize(tester);
    final category = isLargeScreen(tester) ? 'Large' : 'Small';
    return '$category screen (${size.width.toInt()}x${size.height.toInt()})';
  }

  /// Scroll guard that ensures a widget is visible before verifying it.
  ///
  /// This method scrolls through a SingleChildScrollView to find the target widget
  /// and executes the verification callback once the widget is found.
  ///
  /// [scrollableFinder] - Finder for the SingleChildScrollView or similar scrollable
  /// [widgetFinder] - Finder for the target widget to locate and verify
  /// [verification] - Callback to execute once the widget is found/visible
  /// [scrollToTop] - Whether to scroll to top before starting (default: true)
  /// [maxScrollAttempts] - Maximum number of scroll attempts (default: 10)
  /// [scrollDelta] - Amount to scroll each attempt (default: -300 pixels down)
  static Future<void> scrollGuardVerify(
    WidgetTester tester, {
    required Finder scrollableFinder,
    required Finder widgetFinder,
    required Future<void> Function() verification,
    ScrollController Function(Finder scrollableFinder)? getController,
    bool scrollToTop = true,
    int maxScrollAttempts = 10,
    Offset scrollDelta = const Offset(0, -300),
  }) async {
    await tester.pumpAndSettle();

    // Scroll to top first if requested
    if (scrollToTop) {
      final controller = getController != null
          ? getController(scrollableFinder)
          : tester.widget<SingleChildScrollView>(scrollableFinder).controller;
      controller?.jumpTo(0.0);
      await tester.pumpAndSettle();
    }

    // Check if widget is already visible
    if (widgetFinder.evaluate().isNotEmpty) {
      await verification();
      return;
    }

    // Scroll down to find the widget
    for (var attempt = 0; attempt < maxScrollAttempts; attempt++) {
      await tester.drag(scrollableFinder, scrollDelta);
      await tester.pumpAndSettle();

      if (widgetFinder.evaluate().isNotEmpty) {
        await verification();
        return;
      }
    }

    // Widget not found after all scroll attempts - still run verification
    // to get the proper failure message from the expect calls
    await verification();
  }

  /// Scroll guard that verifies a widget is NOT present (after scrolling through entire view).
  ///
  /// This method scrolls through the entire scrollable to verify a widget is not present.
  static Future<void> scrollGuardVerifyNotPresent(
    WidgetTester tester, {
    required Finder scrollableFinder,
    required Finder widgetFinder,
    required String reason,
    int maxScrollAttempts = 10,
    Offset scrollDelta = const Offset(0, -300),
  }) async {
    await tester.pumpAndSettle();

    // Scroll to top first
    for (var i = 0; i < 5; i++) {
      await tester.drag(scrollableFinder, const Offset(0, 500));
      await tester.pumpAndSettle();
    }

    // Check at top position
    expect(widgetFinder, findsNothing, reason: reason);

    // Scroll down and check at each position
    for (var attempt = 0; attempt < maxScrollAttempts; attempt++) {
      await tester.drag(scrollableFinder, scrollDelta);
      await tester.pumpAndSettle();
      expect(widgetFinder, findsNothing, reason: reason);
    }
  }

  /// Scroll guard that does scroll until widget is present (after scrolling through entire view).
  ///
  /// This method scrolls through the entire scrollable to verify a widget is not present.
  static Future<bool> scrollUntilPresent(
    WidgetTester tester, {
    required Finder scrollableFinder,
    required Finder widgetFinder,
    required String reason,
    ScrollController Function(Finder scrollableFinder)? getController,
    int maxScrollAttempts = 10,
    Offset scrollDelta = const Offset(0, -300),
  }) async {
    await tester.pumpAndSettle();

    // Scroll to top first
    final controller = getController != null
        ? getController(scrollableFinder)
        : tester.widget<SingleChildScrollView>(scrollableFinder).controller;
    controller?.jumpTo(0.0);
    await tester.pumpAndSettle();

    if (widgetFinder.evaluate().isNotEmpty) {
      return true;
    }

    // Scroll down and check at each position
    for (var attempt = 0; attempt < maxScrollAttempts; attempt++) {
      await tester.drag(scrollableFinder, scrollDelta);
      await tester.pumpAndSettle();
      if (widgetFinder.evaluate().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Collect widgets of a specific type by scrolling through a scrollable widget.
  ///
  /// Returns a list of widgets found by scrolling through the [scrollableFinder].
  /// If [expectedCount] is provided, the function will fail if not all items are found
  /// within the [timeout].
  ///
  /// The [getUniqueId] function is used to deduplicate widgets during scrolling.
  /// Widgets are returned in the order they appear visually (top to bottom).
  static Future<List<T>> collectWidgetsByScrolling<T extends Widget>({
    required WidgetTester tester,
    required Finder scrollableFinder,
    required Finder widgetFinder,
    required String Function(T widget) getUniqueId,
    int? expectedCount,
    Duration timeout = const Duration(seconds: 30),
    Offset scrollDelta = const Offset(0, -300),
  }) async {
    final stopwatch = Stopwatch()..start();
    final seenIds = <String>{};
    final orderedWidgets = <T>[];

    await tester.pumpAndSettle();

    // Scroll to top first
    for (var i = 0; i < 5; i++) {
      await tester.drag(scrollableFinder, const Offset(0, 500));
      await tester.pumpAndSettle();
    }

    // Keep scrolling and collecting until we have enough or timeout
    while (stopwatch.elapsed < timeout) {
      // Collect all currently visible widgets
      for (final element in widgetFinder.evaluate()) {
        final widget = element.widget as T;
        final id = getUniqueId(widget);
        if (!seenIds.contains(id)) {
          seenIds.add(id);
          orderedWidgets.add(widget);
        }
      }

      // Check if we have enough
      if (expectedCount != null && orderedWidgets.length >= expectedCount) {
        break;
      }

      // Scroll down
      await tester.drag(scrollableFinder, scrollDelta);
      await tester.pumpAndSettle();
    }

    // Validate
    if (expectedCount != null && orderedWidgets.length != expectedCount) {
      throw TestFailure(
        'Expected $expectedCount widgets of type $T, '
        'but found ${orderedWidgets.length}. '
        'Found IDs: ${seenIds.join(", ")}',
      );
    }

    return orderedWidgets;
  }

  static Future<void>
      evaluateWidgetsByScrollingWithPredicate<T extends Widget>({
    required WidgetTester tester,
    required Finder scrollableFinder,
    required Finder widgetFinder,
    required String Function(T widget) getUniqueId,
    required Future<String?> Function(T widget) predicate,
    int? expectedCount,
    Duration timeout = const Duration(minutes: 5),
    Offset scrollDelta = const Offset(0, -300),
  }) async {
    final stopwatch = Stopwatch()..start();
    final seenIds = <String>{};
    final orderedWidgets = <T>[];

    await tester.pumpAndSettle();

    // Scroll to top first
    for (var i = 0; i < 5; i++) {
      await tester.drag(scrollableFinder, const Offset(0, 500));
      await tester.pumpAndSettle();
    }

    // Keep scrolling and collecting until we have enough or timeout
    while (stopwatch.elapsed < timeout) {
      // Collect all currently visible widgets
      for (final element in widgetFinder.evaluate()) {
        final widget = element.widget as T;
        final id = getUniqueId(widget);
        if (!seenIds.contains(id)) {
          final evaluationResult = await predicate(widget);
          if (evaluationResult == null) {
            seenIds.add(id);
            orderedWidgets.add(widget);
          } else {
            fail(evaluationResult);
          }
        }
      }

      // Check if we have enough
      if (expectedCount != null && orderedWidgets.length >= expectedCount) {
        break;
      }

      // Scroll down
      await tester.drag(scrollableFinder, scrollDelta);
      await tester.pumpAndSettle();
    }

    // Validate
    if (expectedCount != null && orderedWidgets.length != expectedCount) {
      throw TestFailure(
        'Expected $expectedCount widgets of type $T, '
        'but found ${orderedWidgets.length}. '
        'Found IDs: ${seenIds.join(", ")}',
      );
    }
  }
}
