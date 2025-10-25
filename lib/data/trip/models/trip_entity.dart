import 'budgeting/expense.dart';

abstract class TripEntity<T> {
  String? get id;

  T clone();

  bool validate();
}

abstract class ExpenseLinkedTripEntity {
  ExpenseFacade get expense;
}
