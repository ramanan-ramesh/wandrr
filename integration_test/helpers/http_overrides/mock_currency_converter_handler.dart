import 'dart:convert';

import 'mock_http_overrides.dart';

/// Mock handler for Currency Converter API
/// Intercepts calls to cdn.jsdelivr.net/npm/@fawazahmed0/currency-api
class MockCurrencyConverterHandler implements MockApiHandler {
  static const String _apiHost = 'cdn.jsdelivr.net';
  static const String _apiPathPrefix = '/npm/@fawazahmed0/currency-api';

  /// Cached currency data - embedded directly to avoid file loading issues in tests
  static Map<String, dynamic>? _currencyData;

  /// Initialize the handler by loading currency data
  static Future<void> loadCurrencyData() async {
    if (_currencyData != null) {
      return;
    }
    _currencyData = _getEmbeddedCurrencyData();
  }

  /// Get embedded currency data for common currencies used in tests
  /// Based on essential currencies for EUR-based test trips
  static Map<String, dynamic> _getEmbeddedCurrencyData() {
    return {
      'date': '2026-01-16',
      'eur': {
        'inr': 104.85, // 1/0.0095374051
        'usd': 1.05,
        'gbp': 0.87,
        'jpy': 168.5,
        'aud': 1.73,
        'cad': 1.61,
        'chf': 0.93,
        'cny': 8.09,
        'eur': 1.0,
      },
      'inr': {
        'eur': 0.0095374051,
        'usd': 0.011071674,
        'gbp': 0.008272818,
        'jpy': 1.75519556,
        'aud': 0.016529722,
        'cad': 0.015382926,
        'chf': 0.0088922593,
        'cny': 0.077145152,
        'inr': 1.0,
      },
      'usd': {
        'inr': 90.32,
        'eur': 0.95,
        'gbp': 0.79,
        'jpy': 148.5,
        'aud': 1.53,
        'cad': 1.37,
        'chf': 0.87,
        'cny': 7.2,
        'usd': 1.0,
      },
    };
  }

  @override
  bool canHandle(Uri url) {
    return url.host == _apiHost && url.path.contains(_apiPathPrefix);
  }

  @override
  Future<MockHttpResponse> handleRequest(Uri url) async {
    await loadCurrencyData();

    // Extract currency from URL path
    // URL format: /npm/@fawazahmed0/currency-api@latest/v1/currencies/{currency}.json
    final pathSegments = url.pathSegments;
    final currencyFileName = pathSegments.last;
    final currency = currencyFileName.replaceAll('.json', '').toLowerCase();

    if (_currencyData == null) {
      return MockHttpResponse.notFound();
    }

    // Check if we have data for this currency
    if (_currencyData!.containsKey(currency)) {
      final currencyRates = _currencyData![currency];
      final response = {
        'date': _currencyData!['date'],
        currency: currencyRates,
      };
      return MockHttpResponse.ok(jsonEncode(response));
    }

    // Try to derive rates from INR if available
    if (_currencyData!.containsKey('inr')) {
      final inrRates = _currencyData!['inr'] as Map<String, dynamic>;
      if (inrRates.containsKey(currency)) {
        // Convert from INR to requested currency
        final inrToTargetRate = inrRates[currency] as num;
        final derivedRates = <String, dynamic>{};

        for (final entry in inrRates.entries) {
          if (entry.key != currency) {
            // Calculate cross rate: target/other = (target/inr) / (other/inr)
            final otherRate = entry.value as num;
            derivedRates[entry.key] = inrToTargetRate / otherRate;
          }
        }
        derivedRates['inr'] = inrToTargetRate;

        final response = {
          'date': _currencyData!['date'],
          currency: derivedRates,
        };
        return MockHttpResponse.ok(jsonEncode(response));
      }
    }

    return MockHttpResponse.notFound();
  }

  /// Clear cached data (useful for testing)
  static void clearCache() {
    _currencyData = null;
  }
}
