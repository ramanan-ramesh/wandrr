import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wandrr/data/trip/models/api_services/currency_converter.dart';
import 'package:wandrr/data/trip/models/api_services/currency_data.dart';
import 'package:wandrr/data/trip/models/money.dart';

import 'constants.dart';

class CurrencyConverter implements CurrencyConverterService {
  static const _apiSurfaceUrl =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1';

  final List<_CurrencyExchangeData> _exchangeRates = [];

  static CurrencyConverter create() {
    var currencyDataList = Constants.currencies
        .map((currencyJson) => CurrencyData.fromJson(currencyJson))
        .toList();
    return CurrencyConverter._(currencyDataList);
  }

  @override
  FutureOr<double?> performQuery(
      {required Money currencyAmount,
      required String currencyToConvertTo}) async {
    if (currencyAmount.amount == 0) {
      return 0;
    }

    if (currencyAmount.currency == currencyToConvertTo) {
      return currencyAmount.amount;
    }

    //expectation : 80 eur to inr= 92eur/inr * 80 (7362)
    //searched for eur/inr

    //eur/inr (= 92) present in cache
    var cachedForwardExchangeRate = _exchangeRates
        .where((element) =>
            element.currency == currencyAmount.currency &&
            element.currencyToConvertTo == currencyToConvertTo)
        .firstOrNull;
    if (cachedForwardExchangeRate != null) {
      return cachedForwardExchangeRate.exchangeRate *
          currencyAmount.amount; // 92 * 80 = 7362
    }

    //inr/eur (=0.011) present in cache
    var cachedReverseExchangeRate = _exchangeRates
        .where((element) =>
            element.currencyToConvertTo == currencyAmount.currency &&
            element.currency == currencyToConvertTo)
        .firstOrNull;
    if (cachedReverseExchangeRate != null) {
      return (1.0 / cachedReverseExchangeRate.exchangeRate) *
          currencyAmount.amount;
    }

    var queryUrl = _constructQuery(currencyToConvertTo);
    _CurrencyExchangeData? exchangeRate;
    try {
      var response = await http.get(Uri.parse(queryUrl));
      if (response.statusCode == 200) {
        var decodedJsonResponse = json.decode(response
            .body); // TODO: Why does inbuilt function jsonDecode not work?
        var responseValue = Map.from(decodedJsonResponse);
        var exchangeRates =
            Map.from(responseValue[currencyToConvertTo.toLowerCase()]);
        for (var exchangeRate in exchangeRates.entries) {
          _exchangeRates.add(_CurrencyExchangeData(
              currency: exchangeRate.key.toString().toUpperCase(),
              currencyToConvertTo: currencyToConvertTo.toUpperCase(),
              exchangeRate: 1.0 / exchangeRate.value));
        }
        exchangeRate = _exchangeRates
            .where((element) =>
                element.currency == currencyAmount.currency &&
                element.currencyToConvertTo == currencyToConvertTo)
            .firstOrNull;
      }
    } catch (e) {
      return null;
    }
    return exchangeRate != null
        ? exchangeRate.exchangeRate * currencyAmount.amount
        : null;
  }

  @override
  List<CurrencyData> supportedCurrencies;

  String _constructQuery(String currencyToConvertTo) {
    return '$_apiSurfaceUrl/currencies/${currencyToConvertTo.toLowerCase()}.json';
    // return '$_apiSurfaceUrl/${currencyToConvertTo.toLowerCase()}.json';
  }

  CurrencyConverter._(this.supportedCurrencies);
}

class _CurrencyExchangeData {
  String currency;
  String currencyToConvertTo;
  double exchangeRate;

  _CurrencyExchangeData(
      {required this.currency,
      required this.currencyToConvertTo,
      required this.exchangeRate});
}
