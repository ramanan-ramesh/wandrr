import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';

/// Handles currency formatting based on currency data
class CurrencyFormatter {
  final Iterable<CurrencyData> supportedCurrencies;

  const CurrencyFormatter(this.supportedCurrencies);

  /// Formats money according to currency rules
  String format(Money money) {
    final currencyData = supportedCurrencies
        .firstWhere((currency) => currency.code == money.currency);

    final formattedAmount = _formatAmount(
      money.amount,
      currencyData.thousandsSeparator,
      currencyData.decimalSeparator,
    );

    return _positionSymbol(
      formattedAmount,
      currencyData.symbol,
      currencyData.symbolOnLeft,
      currencyData.spaceBetweenAmountAndSymbol,
    );
  }

  /// Formats the numeric amount with separators
  String _formatAmount(
    double amount,
    String thousandsSeparator,
    String decimalSeparator,
  ) {
    final amountStr = amount.toStringAsFixed(2);
    final parts = amountStr.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final intBuffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i != 0 && (integerPart.length - i) % 3 == 0) {
        intBuffer.write(thousandsSeparator);
      }
      intBuffer.write(integerPart[i]);
    }

    if (decimalPart == '00' || decimalPart == '0') {
      return intBuffer.toString();
    }

    return intBuffer.toString() + decimalSeparator + decimalPart;
  }

  /// Positions currency symbol relative to amount
  String _positionSymbol(
    String amount,
    String symbol,
    bool symbolOnLeft,
    bool spaceBeforeSymbol,
  ) {
    if (symbolOnLeft) {
      return spaceBeforeSymbol ? '$symbol $amount' : '$symbol$amount';
    } else {
      return spaceBeforeSymbol ? '$amount $symbol' : '$amount$symbol';
    }
  }
}

