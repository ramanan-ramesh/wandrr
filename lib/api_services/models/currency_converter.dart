import 'dart:async';

import 'package:wandrr/trip_data/models/money.dart';

import 'currency_data.dart';

abstract class CurrencyConverterService {
  FutureOr<double?> performQuery(
      {required Money currencyAmount, required String currencyToConvertTo});

  Iterable<CurrencyData> get supportedCurrencies;
}
