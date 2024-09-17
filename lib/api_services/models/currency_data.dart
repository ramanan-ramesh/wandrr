class CurrencyData {
  final String code;
  final String name;
  final String symbol;
  final String? flag;
  final int decimalDigits;
  final int number;
  final String namePlural;
  final String thousandsSeparator;
  final String decimalSeparator;
  final bool spaceBetweenAmountAndSymbol;
  final bool symbolOnLeft;

  CurrencyData({
    required this.code,
    required this.name,
    required this.symbol,
    this.flag,
    required this.decimalDigits,
    required this.number,
    required this.namePlural,
    required this.thousandsSeparator,
    required this.decimalSeparator,
    required this.spaceBetweenAmountAndSymbol,
    required this.symbolOnLeft,
  });

  factory CurrencyData.fromJson(Map<String, dynamic> json) {
    return CurrencyData(
      code: json['code'],
      name: json['name'],
      symbol: json['symbol'],
      flag: json['flag'],
      decimalDigits: json['decimal_digits'],
      number: json['number'],
      namePlural: json['name_plural'],
      thousandsSeparator: json['thousands_separator'],
      decimalSeparator: json['decimal_separator'],
      spaceBetweenAmountAndSymbol: json['space_between_amount_and_symbol'],
      symbolOnLeft: json['symbol_on_left'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'flag': flag,
      'decimal_digits': decimalDigits,
      'number': number,
      'name_plural': namePlural,
      'thousands_separator': thousandsSeparator,
      'decimal_separator': decimalSeparator,
      'space_between_amount_and_symbol': spaceBetweenAmountAndSymbol,
      'symbol_on_left': symbolOnLeft,
    };
  }
}
