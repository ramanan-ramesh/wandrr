import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'expense_category.dart';
import 'money.dart';

/// Data holder for expense details. This used to be the main class; we
/// moved properties here into `ExpenseFacade` and created `Expense` as the
/// trip-entity wrapper.
class ExpenseFacade extends Equatable {
  String? description;
  String currency;

  Money get totalExpense {
    double total = 0;
    paidBy.forEach((key, value) {
      total += value;
    });
    return Money(amount: total, currency: currency);
  }

  Map<String, double> paidBy;
  List<String> splitBy;
  DateTime? dateTime;

  ExpenseFacade(
      {required this.currency,
      required this.paidBy,
      required this.splitBy,
      this.description,
      this.dateTime});

  ExpenseFacade.newUiEntry(
      {required Iterable<String> allTripContributors,
      required String defaultCurrency,
      ExpenseCategory? category})
      : currency = defaultCurrency,
        paidBy = Map.fromIterables(
            allTripContributors, List.filled(allTripContributors.length, 0)),
        splitBy = allTripContributors.toList();

  ExpenseFacade clone() => ExpenseFacade(
      description: description,
      currency: currency,
      paidBy: Map.from(paidBy),
      splitBy: List.from(splitBy),
      dateTime: dateTime == null
          ? null
          : DateTime(dateTime!.year, dateTime!.month, dateTime!.day));

  void copyWith(ExpenseFacade expenseModelFacade) {
    description = expenseModelFacade.description;
    currency = expenseModelFacade.currency;
    paidBy = Map.from(expenseModelFacade.paidBy);
    splitBy = List.from(expenseModelFacade.splitBy);
    dateTime = expenseModelFacade.dateTime == null
        ? null
        : DateTime(
            expenseModelFacade.dateTime!.year,
            expenseModelFacade.dateTime!.month,
            expenseModelFacade.dateTime!.day);
  }

  bool validate() {
    return paidBy.isNotEmpty && splitBy.isNotEmpty;
  }

  @override
  List<Object?> get props => [description, currency, paidBy, splitBy, dateTime];
}

/// Interface for trip entities that carry an attached expense (facade).
abstract class ExpenseBearingTripEntity<T> implements TripEntity<T> {
  /// The facade data for the expense attached to this trip entity
  ExpenseFacade expense;

  String title;

  ExpenseCategory category;

  ExpenseBearingTripEntity(
      {required this.expense,
      this.category = ExpenseCategory.other,
      this.title = ''});
}

class StandaloneExpense extends Equatable
    implements ExpenseBearingTripEntity<StandaloneExpense> {
  String tripId;

  @override
  ExpenseFacade expense;

  @override
  String? id;

  @override
  String title;

  @override
  ExpenseCategory category;

  StandaloneExpense(
      {required this.tripId,
      required this.expense,
      this.category = ExpenseCategory.other,
      this.id,
      this.title = ''});

  @override
  StandaloneExpense clone() {
    return StandaloneExpense(tripId: tripId, expense: expense.clone(), id: id);
  }

  @override
  List<Object?> get props => [expense, id];

  @override
  bool validate() {
    return expense.validate();
  }
}
