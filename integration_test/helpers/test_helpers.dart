import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/app/pages/master_page/master_page.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';

import 'firebase_emulator_helper.dart';
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

  /// Pump the app and wait for animations to settle
  ///
  /// This method automatically waits for the native splash screen to complete
  /// before proceeding with the test.
  static Future<void> pumpAndSettleAppWithTestUser(
      WidgetTester tester, bool shouldAddToFirestore, bool shouldSignIn) async {
    await FirebaseEmulatorHelper.createFirebaseAuthUser(
      email: TestConfig.testEmail,
      password: TestConfig.testPassword,
      shouldAddToFirestore: shouldAddToFirestore,
      shouldSignIn: shouldSignIn,
    );

    final sharedPreferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(MasterPage(sharedPreferences));
    await tester.pumpAndSettle();
    // Wait for native splash screen to complete (Android/iOS)
    await _waitForNativeSplashScreen(tester);
    // Log device size after splash screen
    print(_getDeviceSizeDescription(tester));
  }

  static AppLocalizations getAppLocalizations(WidgetTester tester, Type type) {
    final context = tester.element(find.byType(type));
    return AppLocalizations.of(context)!;
  }

  /// Create a test trip for trip editor tests
  /// Create a 5-day test trip for integration tests (European tour)
  static Future<void> createTestTrip() async {
    final firestore = FirebaseFirestore.instance;

    // Test trip data
    const tripId = 'test_trip_123';
    final startDate = DateTime(2025, 9, 24);
    final endDate = DateTime(2025, 9, 28);
    const tripName = 'European Adventure';
    const defaultCurrency = 'EUR';
    final contributors = [TestConfig.testEmail];

    // Create trip metadata
    await firestore
        .collection(FirestoreCollections.tripMetadataCollectionName)
        .doc(tripId)
        .set({
      'name': tripName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'thumbnailTag': 'urban',
      'contributors': contributors,
      'budget': '800.00 EUR',
    });

    // === LOCATIONS ===
    final londonAirport = {
      'latLon': GeoPoint(51.5074, -0.1278),
      'context': {
        'type': 'airport',
        'name': 'London Airport',
        'city': 'London',
        "iata": 'YXU',
        'locationType': 'airport',
      }
    };

    final parisAirport = {
      'latLon': GeoPoint(48.8566, 2.3522),
      'context': {
        'type': 'airport',
        'name': 'Charles de Gaulle International Airport',
        'city': 'Paris (Roissy-en-France, Val-d\'Oise)',
        'iata': 'CDG',
        'locationType': 'airport',
      }
    };

    // City locations
    final parisCity = {
      'latLon': GeoPoint(48.8566, 2.3522),
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
      'latLon': GeoPoint(48.8049, 2.1204),
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
      'latLon': GeoPoint(50.8503, 4.3517),
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
      'latLon': GeoPoint(52.3676, 4.9041),
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
      'latLon': GeoPoint(48.8584, 2.2945),
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
      'latLon': GeoPoint(48.8606, 2.3376),
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
      'latLon': GeoPoint(50.8950, 4.3414),
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
      'latLon': GeoPoint(52.3600, 4.8852),
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

    var tripDataCollection = firestore
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripId);

    var itineraryDataCollection = tripDataCollection
        .collection(FirestoreCollections.itineraryDataCollectionName);
    var lodgingCollection = tripDataCollection
        .collection(FirestoreCollections.lodgingCollectionName);
    var transitCollection = tripDataCollection
        .collection(FirestoreCollections.transitCollectionName);

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

    // Same-day check-in/out: Brussels day room
    await lodgingCollection.add({
      'location': brusselsLocation,
      'checkinDateTime': Timestamp.fromDate(DateTime(2025, 9, 27, 3, 0)),
      'checkoutDateTime': Timestamp.fromDate(DateTime(2025, 9, 27, 15, 0)),
      'confirmationId': 'BRU-DAY-789',
      'expense': {
        'currency': defaultCurrency,
        'category': 'lodging',
        'paidBy': {TestConfig.testEmail: 80.0},
        'splitBy': contributors,
      },
      'notes': 'Rest after night bus',
    });

    // Amsterdam hostel
    await lodgingCollection.add({
      'location': amsterdamLocation,
      'checkinDateTime': Timestamp.fromDate(DateTime(2025, 9, 27, 22, 0)),
      'checkoutDateTime': Timestamp.fromDate(DateTime(2025, 9, 28, 16, 0)),
      'confirmationId': 'AMS-HSTL-123',
      'expense': {
        'currency': defaultCurrency,
        'category': 'lodging',
        'paidBy': {TestConfig.testEmail: 90.0},
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
      'notes': ['Final day', 'Museum visit', 'Canal walk', 'Departure prep'],
      'checkLists': [
        {
          'title': 'Last day',
          'items': [
            {'item': 'Buy souvenirs', 'status': false},
            {'item': 'Pack bags', 'status': false},
          ]
        }
      ],
    });

    print('✅ 5-day test trip created: $tripId');
    print('   Route: London → Paris → Brussels → Amsterdam');
    print(
        '   Transits: flight, train, bus, rentedVehicle, taxi, ferry, walk, publicTransport');
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

  /// Get the position of a widget
  static Offset getWidgetPosition(WidgetTester tester, Finder finder) {
    final RenderBox renderBox = tester.renderObject(finder);
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
      WidgetTester tester,
      bool shouldOpenDateRangePickerDialog,
      DateTime tripStartDate,
      int numberOfDays) async {
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

  static Future<void> enterMoneyAmount(WidgetTester tester, Money money) async {
    var textField = find.byKey(Key('ExpenseAmountEditField_TextField'));
    await tester.enterText(textField, money.amount.toString());
    await TestHelpers.tapWidget(
        tester, find.byKey(Key('PlatformMoneyEditField_CurrencyPickerButton')));
    var searchField = find.byKey(Key('PlatformMoneyEditField_TextField'));
    await tester.enterText(searchField, money.currency);
    await tester.pumpAndSettle(); // Wait for filtered list to render

    final currencyListTile = find.byKey(
        Key('PlatformMoneyEditField_CurrencyListTile_${money.currency}'));
    await TestHelpers.tapWidget(tester, currencyListTile, warnIfMissed: false);
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
}
