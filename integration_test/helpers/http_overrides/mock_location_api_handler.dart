import 'dart:convert';

import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

import 'mock_http_overrides.dart';

/// Mock handler for Location API (locationiq.com)
class MockLocationApiHandler implements MockApiHandler {
  static const String _apiHost = 'locationiq.com';

  // List of accepted input strings for testing
  static const List<String> acceptedQueries = [
    'hotel',
    'bus stand',
    'railway station',
    'sight',
    'paris',
    'london',
    'new york',
    'tokyo',
    'restaurant',
    'airport',
    'museum',
  ];

  // Dummy location JSON responses that match the locationiq API format
  static final List<Map<String, dynamic>> dummyLocationJsons = [
    // Hotel in Paris
    {
      'lat': '48.8566',
      'lon': '2.3522',
      'display_address': 'Grand Hotel Paris, 1 Rue de Rivoli, Paris, France',
      'place_id': 'mock_hotel_paris_1',
      'class': 'tourism',
      'type': 'hotel',
      'boundingbox': ['48.8556', '48.8576', '2.3512', '2.3532'],
      'address': {
        'name': 'Grand Hotel Paris',
        'city': 'Paris',
        'state': 'Île-de-France',
        'country': 'France',
      },
    },
    // Bus Station in London
    {
      'lat': '51.5074',
      'lon': '-0.1278',
      'display_address':
          'Victoria Coach Station, 164 Buckingham Palace Road, London, UK',
      'place_id': 'mock_bus_station_london_1',
      'class': 'highway',
      'type': 'bus_station',
      'boundingbox': ['51.5064', '51.5084', '-0.1288', '-0.1268'],
      'address': {
        'name': 'Victoria Coach Station',
        'city': 'London',
        'state': 'England',
        'country': 'United Kingdom',
      },
    },
    // Railway Station in Tokyo
    {
      'lat': '35.6812',
      'lon': '139.7671',
      'display_address':
          'Tokyo Station, 1 Chome Marunouchi, Chiyoda City, Tokyo, Japan',
      'place_id': 'mock_railway_tokyo_1',
      'class': 'railway',
      'type': 'station',
      'boundingbox': ['35.6802', '35.6822', '139.7661', '139.7681'],
      'address': {
        'name': 'Tokyo Station',
        'city': 'Tokyo',
        'state': 'Tokyo',
        'country': 'Japan',
      },
    },
    // Tourist Attraction (Eiffel Tower) in Paris
    {
      'lat': '48.8584',
      'lon': '2.2945',
      'display_address': 'Eiffel Tower, Champ de Mars, Paris, France',
      'place_id': 'mock_sight_paris_1',
      'class': 'attraction',
      'type': 'tourism',
      'boundingbox': ['48.8574', '48.8594', '2.2935', '2.2955'],
      'address': {
        'name': 'Eiffel Tower',
        'city': 'Paris',
        'state': 'Île-de-France',
        'country': 'France',
      },
    },
    // Restaurant in New York
    {
      'lat': '40.7128',
      'lon': '-74.0060',
      'display_address': 'The Modern, 9 W 53rd St, New York, NY, USA',
      'place_id': 'mock_restaurant_ny_1',
      'class': 'amenity',
      'type': 'restaurant',
      'boundingbox': ['40.7118', '40.7138', '-74.0070', '-74.0050'],
      'address': {
        'name': 'The Modern',
        'city': 'New York',
        'state': 'New York',
        'country': 'United States',
      },
    },
    // Airport in London
    {
      'lat': '51.4700',
      'lon': '-0.4543',
      'display_address': 'London Heathrow Airport, Longford, London, UK',
      'place_id': 'mock_airport_london_1',
      'class': 'aeroway',
      'type': 'aerodrome',
      'boundingbox': ['51.4600', '51.4800', '-0.4643', '-0.4443'],
      'address': {
        'name': 'London Heathrow Airport',
        'city': 'London',
        'county': 'Greater London',
        'state': 'England',
        'country': 'United Kingdom',
      },
    },
    // City - Paris
    {
      'lat': '48.8566',
      'lon': '2.3522',
      'display_address': 'Paris, Île-de-France, France',
      'place_id': 'mock_city_paris_1',
      'class': 'boundary',
      'type': 'city',
      'boundingbox': ['48.8156', '48.9022', '2.2241', '2.4699'],
      'address': {
        'name': 'Paris',
        'city': 'Paris',
        'state': 'Île-de-France',
        'country': 'France',
      },
    },
    // Museum in London
    {
      'lat': '51.5194',
      'lon': '-0.1270',
      'display_address': 'British Museum, Great Russell Street, London, UK',
      'place_id': 'mock_museum_london_1',
      'class': 'attraction',
      'type': 'tourism',
      'boundingbox': ['51.5184', '51.5204', '-0.1280', '-0.1260'],
      'address': {
        'name': 'British Museum',
        'city': 'London',
        'state': 'England',
        'country': 'United Kingdom',
      },
    },
  ];

  // Cache of parsed LocationFacade objects
  static List<LocationFacade>? _cachedLocations;

  /// Get all dummy locations as LocationFacade objects
  static List<LocationFacade> getDummyLocations() {
    _cachedLocations ??= dummyLocationJsons.map((json) {
        return LocationFacade(
          latitude: double.parse(json['lat'] as String),
          longitude: double.parse(json['lon'] as String),
          context: GeoLocationApiContext.fromApi(json),
        );
      }).toList();
    return _cachedLocations!;
  }

  @override
  bool canHandle(Uri url) {
    return url.host.contains(_apiHost);
  }

  @override
  Future<MockHttpResponse> handleRequest(Uri url) async {
    final query = url.queryParameters['q'] ?? '';
    final responseBody = _getMockResponse(query);
    return MockHttpResponse.ok(responseBody);
  }

  /// Get mock response based on query string
  static String _getMockResponse(String query) {
    final lowerQuery = query.toLowerCase().trim();

    // Filter locations based on query
    final matchingLocations = dummyLocationJsons.where((json) {
      final address = json['address'] as Map<String, dynamic>;
      final name = (address['name'] as String? ?? '').toLowerCase();
      final city = (address['city'] as String? ?? '').toLowerCase();
      final type = (json['type'] as String? ?? '').toLowerCase();
      final displayAddress =
          (json['display_address'] as String? ?? '').toLowerCase();

      return name.contains(lowerQuery) ||
          city.contains(lowerQuery) ||
          type.contains(lowerQuery) ||
          displayAddress.contains(lowerQuery) ||
          lowerQuery.contains(name) ||
          lowerQuery.contains(city);
    }).toList();

    // If no matches, return empty array
    if (matchingLocations.isEmpty) {
      return '[]';
    }

    return jsonEncode(matchingLocations);
  }

  /// Clear cached data
  static void clearCache() {
    _cachedLocations = null;
  }
}
