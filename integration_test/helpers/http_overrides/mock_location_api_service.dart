import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/trip/implementations/api_services/constants.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

import 'mock_currency_converter_handler.dart';
import 'mock_http_overrides.dart';
import 'mock_location_api_handler.dart';

/// Mock API Services that provides mock data for testing.
/// Initializes HTTP overrides to intercept API calls without modifying lib code.
///
/// Supported APIs:
/// - Location API (locationiq.com)
/// - Currency Converter API (cdn.jsdelivr.net)
class MockApiServices {
  // Re-export from handler for backward compatibility
  static const List<String> acceptedQueries =
      MockLocationApiHandler.acceptedQueries;
  static final List<Map<String, dynamic>> dummyLocationJsons =
      MockLocationApiHandler.dummyLocationJsons;

  /// Get all dummy locations as LocationFacade objects
  static List<LocationFacade> getDummyLocations() =>
      MockLocationApiHandler.getDummyLocations();

  /// Initialize all mock API services to intercept HTTP requests.
  /// Registers handlers for:
  /// - Location API
  /// - Currency Converter API
  static Future<void> initialize() async {
    await _initializeApiServiceConfigurations();

    // Load currency data for mock responses
    await MockCurrencyConverterHandler.loadCurrencyData();

    // Register all API handlers
    MockHttpOverrides.registerHandler(MockLocationApiHandler());
    MockHttpOverrides.registerHandler(MockCurrencyConverterHandler());

    // Initialize the HTTP overrides
    MockHttpOverrides.initialize();
  }

  static Future<void> _initializeApiServiceConfigurations() async {
    var apiServicesCollection = FirebaseFirestore.instance
        .collection(Constants.apiServicesCollectionName);
    await apiServicesCollection.add({'type': 'geoLocator', 'key': 'DummyKey'});
    await apiServicesCollection.add({
      'type': 'airlinesData',
      'lastRefreshedAt': Timestamp.fromDate(DateTime(2025, 11, 11)),
      'dataUrl':
          'https://ramanan-ramesh.github.io/wandrr/docs/airlines_data.json'
    });
    await apiServicesCollection.add({
      'type': 'airportsData',
      'lastRefreshedAt': Timestamp.fromDate(DateTime(2025, 11, 11)),
      'dataUrl':
          'https://ramanan-ramesh.github.io/wandrr/docs/airports_data.json'
    });
  }

  /// Clean up and restore original HTTP behavior
  static void dispose() {
    MockHttpOverrides.dispose();
    MockLocationApiHandler.clearCache();
    MockCurrencyConverterHandler.clearCache();
  }
}

/// @deprecated Use [MockApiServices] instead
/// Kept for backward compatibility
typedef MockLocationApiService = MockApiServices;
