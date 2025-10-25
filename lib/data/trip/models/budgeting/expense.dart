import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'expense_category.dart';
import 'money.dart';

class ExpenseFacade implements TripEntity<ExpenseFacade> {
  String tripId;

  String title;

  String? description;

  @override
  String? id;

  Money totalExpense;

  ExpenseCategory category;

  Map<String, double> paidBy;

  List<String> splitBy;

  LocationFacade? location;

  DateTime? dateTime;

  ExpenseFacade(
      {required this.tripId,
      required this.title,
      required this.totalExpense,
      required this.category,
      required this.paidBy,
      required this.splitBy,
      this.description,
      this.id,
      this.location,
      this.dateTime});

  ExpenseFacade.newUiEntry(
      {required this.tripId,
      required Iterable<String> allTripContributors,
      required String defaultCurrency})
      : title = '',
        totalExpense = Money(currency: defaultCurrency, amount: 0),
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
      totalExpense: totalExpense,
      category: category,
      paidBy: paidBy,
      splitBy: splitBy,
      location: location?.clone(),
      dateTime: dateTime != null
          ? DateTime(dateTime!.year, dateTime!.month, dateTime!.day)
          : null);

  void copyWith(ExpenseFacade expenseModelFacade) {
    tripId = expenseModelFacade.tripId;
    title = expenseModelFacade.title;
    description = expenseModelFacade.description;
    id = expenseModelFacade.id;
    totalExpense = expenseModelFacade.totalExpense;
    category = expenseModelFacade.category;
    paidBy = expenseModelFacade.paidBy;
    splitBy = expenseModelFacade.splitBy;
    location = expenseModelFacade.location;
    dateTime = DateTime(expenseModelFacade.dateTime!.year,
        expenseModelFacade.dateTime!.month, expenseModelFacade.dateTime!.day);
  }

  @override
  bool validate() => paidBy.isNotEmpty && splitBy.isNotEmpty;
}
