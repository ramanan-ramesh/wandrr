class CurrencyData {
  static const String _codeField = 'code';
  static const String _nameField = 'name';
  static const String _symbolField = 'symbol';
  static const String _thousandSeparatorField = 'thousands_separator';
  static const String _decimalSeparatorField = 'decimal_separator';
  static const String _symbolOnLeftField = 'symbol_on_left';
  static const String _spaceBetweenAmountAndSymbolField =
      'space_between_amount_and_symbol';

  final String code;
  final String name;
  final String symbol;
  final String thousandsSeparator;
  final String decimalSeparator;
  final bool symbolOnLeft;
  final bool spaceBetweenAmountAndSymbol;

  CurrencyData({
    required this.code,
    required this.name,
    required this.symbol,
    required this.thousandsSeparator,
    required this.decimalSeparator,
    required this.symbolOnLeft,
    required this.spaceBetweenAmountAndSymbol,
  });

  factory CurrencyData.fromJson(Map<String, dynamic> json) => CurrencyData(
        code: json[_codeField],
        name: json[_nameField],
        symbol: json[_symbolField],
        thousandsSeparator: json[_thousandSeparatorField],
        decimalSeparator: json[_decimalSeparatorField],
        symbolOnLeft: bool.parse(json[_symbolOnLeftField].toString()),
        spaceBetweenAmountAndSymbol:
            bool.parse(json[_spaceBetweenAmountAndSymbolField].toString()),
      );

  Map<String, dynamic> toMap() => {
        _codeField: code,
        _nameField: name,
        _symbolField: symbol,
        _thousandSeparatorField: thousandsSeparator,
        _decimalSeparatorField: decimalSeparator,
        _symbolOnLeftField: symbolOnLeft.toString(),
        _spaceBetweenAmountAndSymbolField:
            spaceBetweenAmountAndSymbol.toString(),
      };
}
