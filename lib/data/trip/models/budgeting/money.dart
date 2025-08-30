import 'package:equatable/equatable.dart';

class Money extends Equatable {
  final String currency;
  final double amount;

  const Money({required this.currency, required this.amount});

  static Money fromDocumentData(String documentData) {
    var splittedStrings = documentData.split(' ');
    return Money(
        currency: splittedStrings.elementAt(1),
        amount: double.parse(splittedStrings.first));
  }

  @override
  String toString() => '${amount.toStringAsFixed(2)} $currency';

  @override
  List<Object?> get props => [currency, amount];
}
