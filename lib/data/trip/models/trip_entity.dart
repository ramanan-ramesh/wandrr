import 'budgeting/expense.dart';

abstract class TripEntity<T> {
  String? get id;

  T clone();

  bool validate();
}

abstract class ExpenseLinkedTripEntity<T> implements TripEntity<T> {
  ExpenseFacade expense;

  ExpenseLinkedTripEntity(this.expense);
}
