import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'money.dart';

class ExpenseFacade implements TripEntity {
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
      this.description,
      this.id,
      required this.totalExpense,
      required this.category,
      required this.paidBy,
      required this.splitBy,
      this.location,
      this.dateTime});

  ExpenseFacade.newUiEntry(
      {required this.tripId,
      required List<String> allTripContributors,
      required String currentUserName,
      required String defaultCurrency})
      : title = '',
        totalExpense = Money(currency: defaultCurrency, amount: 0),
        category = ExpenseCategory.Other,
        paidBy = Map.fromIterables(
            allTripContributors, List.filled(allTripContributors.length, 0)),
        splitBy = allTripContributors.toList();

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

  ExpenseFacade clone() {
    return ExpenseFacade(
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
  }

  bool isValid() {
    return paidBy.isNotEmpty && splitBy.isNotEmpty;
  }
}

//added new entries, so maintain the place where logos are added corresponding to each category
enum ExpenseCategory {
  Other,
  Flights,
  Lodging,
  CarRental,
  PublicTransit,
  Food,
  Drinks,
  Sightseeing,
  Activities,
  Shopping,
  Fuel,
  Groceries,
  Taxi
}
