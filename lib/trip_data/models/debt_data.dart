import 'money.dart';

class DebtData {
  String owedBy, owedTo;
  Money money;

  DebtData({required this.owedBy, required this.owedTo, required this.money});
}
