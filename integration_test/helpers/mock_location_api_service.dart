import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/trip/implementations/api_services/constants.dart';
import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

/// Mock Location API Service that provides dummy location data for testing
/// Uses HttpOverrides to intercept HTTP requests without modifying lib code
class MockLocationApiService {
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
    if (_cachedLocations == null) {
      _cachedLocations = dummyLocationJsons.map((json) {
        return LocationFacade(
          latitude: double.parse(json['lat'] as String),
          longitude: double.parse(json['lon'] as String),
          context: GeoLocationApiContext.fromApi(json),
        );
      }).toList();
    }
    return _cachedLocations!;
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

  /// Initialize the mock service and set up HTTP overrides
  static Future<void> initialize() async {
    await _initializeApiServiceConfigurations();
    HttpOverrides.global = _MockHttpOverrides();
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
    HttpOverrides.global = null;
    _cachedLocations = null;
  }
}

/// HttpOverrides implementation that intercepts HTTP requests
class _MockHttpOverrides extends HttpOverrides {
  static bool _isCreatingRealClient = false;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // If we're creating a real client, bypass our mock
    if (_isCreatingRealClient) {
      return super.createHttpClient(context);
    }
    return _MockHttpClient();
  }
}

/// Mock HttpClient that intercepts locationiq.com requests
class _MockHttpClient implements HttpClient {
  // Create a real HttpClient bypassing the override
  HttpClient? __realClient;

  HttpClient get _realClient {
    if (__realClient == null) {
      // Set flag to prevent infinite recursion
      _MockHttpOverrides._isCreatingRealClient = true;
      __realClient = HttpClient();
      _MockHttpOverrides._isCreatingRealClient = false;
    }
    return __realClient!;
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    // Intercept locationiq.com API calls
    if (url.host.contains('locationiq.com')) {
      final query = url.queryParameters['q'] ?? '';
      return _MockHttpClientRequest(query);
    }
    // For other URLs, use the real HTTP client
    return _realClient.getUrl(url);
  }

  // Delegate all other methods to the real client
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  void addCredentials(
          Uri url, String realm, HttpClientCredentials credentials) =>
      _realClient.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(String host, int port, String realm,
          HttpClientCredentials credentials) =>
      _realClient.addProxyCredentials(host, port, realm, credentials);

  @override
  set authenticate(
          Future<bool> Function(Uri url, String scheme, String? realm)? f) =>
      _realClient.authenticate = f;

  @override
  set authenticateProxy(
          Future<bool> Function(
                  String host, int port, String scheme, String? realm)?
              f) =>
      _realClient.authenticateProxy = f;

  @override
  set badCertificateCallback(
          bool Function(X509Certificate cert, String host, int port)?
              callback) =>
      _realClient.badCertificateCallback = callback;

  @override
  void close({bool force = false}) => _realClient.close(force: force);

  @override
  set connectionFactory(
          Future<ConnectionTask<Socket>> Function(
                  Uri url, String? proxyHost, int? proxyPort)?
              f) =>
      _realClient.connectionFactory = f;

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _realClient.delete(host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _realClient.deleteUrl(url);

  @override
  set findProxy(String Function(Uri url)? f) => _realClient.findProxy = f;

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _realClient.get(host, port, path);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _realClient.head(host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => _realClient.headUrl(url);

  @override
  set keyLog(Function(String line)? callback) => _realClient.keyLog = callback;

  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      _realClient.open(method, host, port, path);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _realClient.openUrl(method, url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _realClient.patch(host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _realClient.patchUrl(url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _realClient.post(host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _realClient.postUrl(url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _realClient.put(host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => _realClient.putUrl(url);
}

/// Mock HttpClientRequest for intercepted requests
class _MockHttpClientRequest implements HttpClientRequest {
  final String _query;

  _MockHttpClientRequest(this._query);

  @override
  Future<HttpClientResponse> close() async {
    final responseBody = MockLocationApiService._getMockResponse(_query);
    return _MockHttpClientResponse(responseBody);
  }

  @override
  Encoding encoding = utf8;

  @override
  HttpConnectionInfo? connectionInfo;

  @override
  List<Cookie> cookies = [];

  @override
  Future<HttpClientResponse> get done => close();

  @override
  HttpHeaders headers = _MockHttpHeaders();

  @override
  String method = 'GET';

  @override
  Uri uri = Uri.parse('https://api.locationiq.com/v1/autocomplete');

  @override
  bool bufferOutput = true;

  @override
  int contentLength = -1;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  // All the write methods do nothing
  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  Future flush() async {}

  @override
  void write(Object? object) {}

  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = '']) {}

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

/// Mock HttpClientResponse for intercepted requests
class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final String _response;

  _MockHttpClientResponse(this._response);

  @override
  X509Certificate? certificate;

  @override
  HttpConnectionInfo? connectionInfo;

  @override
  int contentLength = -1;

  @override
  List<Cookie> cookies = [];

  @override
  HttpHeaders headers = _MockHttpHeaders();

  @override
  bool isRedirect = false;

  @override
  bool persistentConnection = false;

  @override
  String reasonPhrase = 'OK';

  @override
  List<RedirectInfo> redirects = [];

  @override
  int statusCode = 200;

  @override
  HttpClientResponseCompressionState compressionState =
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(utf8.encode(_response)).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) async =>
      this;

  @override
  Future<Socket> detachSocket() {
    throw UnsupportedError('detachSocket not supported in mock');
  }
}

/// Mock HttpHeaders - minimal implementation
class _MockHttpHeaders implements HttpHeaders {
  @override
  ContentType? contentType = ContentType.json;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = false;

  @override
  bool chunkedTransferEncoding = false;

  @override
  String? host;

  @override
  int? port;

  @override
  DateTime? date;

  @override
  DateTime? expires;

  @override
  DateTime? ifModifiedSince;

  // All mutation methods do nothing since we don't need them
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void clear() {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  String? value(String name) =>
      name == 'content-type' ? 'application/json' : null;

  @override
  List<String>? operator [](String name) =>
      name == 'content-type' ? ['application/json'] : null;
}
