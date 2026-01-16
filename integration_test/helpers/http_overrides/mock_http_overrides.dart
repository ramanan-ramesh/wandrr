import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Common HTTP override infrastructure for intercepting API calls in tests.
/// Supports multiple API handlers (Location API, Currency Converter API, etc.)
class MockHttpOverrides extends HttpOverrides {
  static bool _isCreatingRealClient = false;
  static final List<MockApiHandler> _handlers = [];

  /// Register an API handler
  static void registerHandler(MockApiHandler handler) {
    _handlers.add(handler);
  }

  /// Clear all registered handlers
  static void clearHandlers() {
    _handlers.clear();
  }

  /// Initialize the HTTP overrides
  static void initialize() {
    HttpOverrides.global = MockHttpOverrides();
  }

  /// Dispose and restore original HTTP behavior
  static void dispose() {
    HttpOverrides.global = null;
    clearHandlers();
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    if (_isCreatingRealClient) {
      return super.createHttpClient(context);
    }
    return _MockHttpClient(_handlers);
  }

  /// Create a real HttpClient bypassing the mock
  static HttpClient createRealHttpClient() {
    _isCreatingRealClient = true;
    final client = HttpClient();
    _isCreatingRealClient = false;
    return client;
  }
}

/// Abstract base class for API handlers
abstract class MockApiHandler {
  /// Check if this handler can handle the given URL
  bool canHandle(Uri url);

  /// Get the mock response for the given URL
  Future<MockHttpResponse> handleRequest(Uri url);
}

/// Mock HTTP response data
class MockHttpResponse {
  final int statusCode;
  final String body;
  final String contentType;

  const MockHttpResponse({
    required this.statusCode,
    required this.body,
    this.contentType = 'application/json',
  });

  factory MockHttpResponse.ok(String body) => MockHttpResponse(
        statusCode: 200,
        body: body,
      );

  factory MockHttpResponse.notFound() => const MockHttpResponse(
        statusCode: 404,
        body: '{"error": "Not found"}',
      );
}

/// Mock HttpClient that routes requests to appropriate handlers
class _MockHttpClient implements HttpClient {
  final List<MockApiHandler> _handlers;
  HttpClient? __realClient;

  _MockHttpClient(this._handlers);

  HttpClient get _realClient {
    __realClient ??= MockHttpOverrides.createRealHttpClient();
    return __realClient!;
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    // Find a handler that can handle this URL
    for (final handler in _handlers) {
      if (handler.canHandle(url)) {
        return _MockHttpClientRequest(url, handler);
      }
    }
    // No handler found, use real HTTP client
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
  final Uri _url;
  final MockApiHandler _handler;

  _MockHttpClientRequest(this._url, this._handler);

  @override
  Future<HttpClientResponse> close() async {
    final response = await _handler.handleRequest(_url);
    return _MockHttpClientResponse(response);
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
  Uri get uri => _url;

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
  final MockHttpResponse _response;

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
  int get statusCode => _response.statusCode;

  @override
  HttpClientResponseCompressionState compressionState =
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(utf8.encode(_response.body)).listen(onData,
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
