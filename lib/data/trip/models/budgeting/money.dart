import 'package:freezed_annotation/freezed_annotation.dart';

part 'money.freezed.dart';

@freezed
class Money with _$Money {
  const factory Money({
    required String currency,
    required double amount,
  }) = _Money;

  /// Parse from Firestore string format "amount currency"
  static Money fromDocumentData(String documentData) {
    var splittedStrings = documentData.split(' ');
    return Money(
      currency: splittedStrings.elementAt(1),
      amount: double.parse(splittedStrings.first),
    );
  }

  /// Override toString to display as "amount currency"
  @override
  String toString() => '${amount.toStringAsFixed(2)} $currency';
}
