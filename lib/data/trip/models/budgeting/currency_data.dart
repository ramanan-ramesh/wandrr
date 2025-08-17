class CurrencyData {
  static const String _codeField = 'code';
  static const String _nameField = 'name';
  static const String _symbolField = 'symbol';
  static const String _flagField = 'flag';

  final String code;
  final String name;
  final String symbol;
  final String? flag;

  CurrencyData({
    required this.code,
    required this.name,
    required this.symbol,
    this.flag,
  });

  factory CurrencyData.fromJson(Map<String, dynamic> json) => CurrencyData(
        code: json[_codeField],
        name: json[_nameField],
        symbol: json[_symbolField],
        flag: json[_flagField],
      );

  Map<String, dynamic> toMap() => {
        _codeField: code,
        _nameField: name,
        _symbolField: symbol,
        if (flag != null) _flagField: flag,
      };
}
