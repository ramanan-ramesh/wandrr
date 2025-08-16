class CurrencyData {
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

  factory CurrencyData.fromJson(Map<String, dynamic> json) {
    return CurrencyData(
      code: json['code'],
      name: json['name'],
      symbol: json['symbol'],
      flag: json['flag'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      if (flag != null) 'flag': flag,
    };
  }
}
