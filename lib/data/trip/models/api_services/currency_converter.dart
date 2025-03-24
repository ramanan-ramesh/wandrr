import 'dart:async';

import 'package:wandrr/data/trip/models/money.dart';

abstract class CurrencyConverterService {
  FutureOr<double?> performQuery(
      {required Money currencyAmount, required String currencyToConvertTo});
}
