import 'money.dart';

class DebtData {
  final String owedBy, owedTo;
  final Money money;

  const DebtData(
      {required this.owedBy, required this.owedTo, required this.money});
}
