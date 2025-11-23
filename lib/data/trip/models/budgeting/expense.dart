import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'expense_category.dart';
import 'money.dart';

class ExpenseFacade extends Equatable
    implements ExpenseLinkedTripEntity<ExpenseFacade> {
  String tripId;

  String title;

  String? description;

  @override
  String? id;

  String currency;

  Money get totalExpense {
    double total = 0;
    paidBy.forEach((key, value) {
      total += value;
    });
    return Money(amount: total, currency: currency);
  }

  ExpenseCategory category;

  Map<String, double> paidBy;

  List<String> splitBy;

  DateTime? dateTime;

  ExpenseFacade(
      {required this.tripId,
      required this.title,
      required this.currency,
      required this.category,
      required this.paidBy,
      required this.splitBy,
      this.description,
      this.id,
      this.dateTime});

  ExpenseFacade.newUiEntry(
      {required this.tripId,
      required Iterable<String> allTripContributors,
      required String defaultCurrency})
      : title = '',
        currency = defaultCurrency,
        category = ExpenseCategory.other,
        paidBy = Map.fromIterables(
            allTripContributors, List.filled(allTripContributors.length, 0)),
        splitBy = allTripContributors.toList();

  @override
  ExpenseFacade clone() => ExpenseFacade(
      tripId: tripId,
      title: title,
      description: description,
      id: id,
      currency: currency,
      category: category,
      paidBy: paidBy,
      splitBy: splitBy,
      dateTime: dateTime != null
          ? DateTime(dateTime!.year, dateTime!.month, dateTime!.day)
          : null);

  void copyWith(ExpenseFacade expenseModelFacade) {
    tripId = expenseModelFacade.tripId;
    title = expenseModelFacade.title;
    description = expenseModelFacade.description;
    id = expenseModelFacade.id;
    currency = expenseModelFacade.currency;
    category = expenseModelFacade.category;
    paidBy = expenseModelFacade.paidBy;
    splitBy = expenseModelFacade.splitBy;
    dateTime = DateTime(expenseModelFacade.dateTime!.year,
        expenseModelFacade.dateTime!.month, expenseModelFacade.dateTime!.day);
  }

  //TODO: How to validate that title is not empty for pure expenses, and ensure that title for Transits/Stays/Sights are generated each time and not copied to DB/open to updation, and also passing validity API
  @override
  bool validate() {
    return paidBy.isNotEmpty && splitBy.isNotEmpty;
  }

  @override
  ExpenseFacade get expense => this;

  @override
  set expense(ExpenseFacade expense) {
    copyWith(expense);
  }

  @override
  List<Object?> get props => [
        tripId,
        title,
        description,
        id,
        currency,
        category,
        paidBy,
        splitBy,
        dateTime
      ];
}
