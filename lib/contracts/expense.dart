import 'package:equatable/equatable.dart';
import 'package:wandrr/contracts/location.dart';

import 'trip_data.dart';

class CurrencyWithValue extends Equatable {
  String currency;
  double amount;

  CurrencyWithValue({required this.currency, required this.amount});

  static CurrencyWithValue fromDocumentData(String documentData) {
    var splittedStrings = documentData.split(' ');
    return CurrencyWithValue(
        currency: splittedStrings.elementAt(1),
        amount: double.parse(splittedStrings.first));
  }

  @override
  String toString() {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  @override
  List<Object?> get props => [currency, amount];
}

//#ui access sorted
class ExpenseModelFacade implements TripEntity {
  String tripId;

  String title;

  String? description;

  @override
  String? id;

  CurrencyWithValue totalExpense;

  ExpenseCategory category;

  Map<String, double> paidBy;

  List<String> splitBy;

  LocationModelFacade? location;

  DateTime? dateTime;

  ExpenseModelFacade(
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

  ExpenseModelFacade.newUiEntry(
      {required this.tripId,
      required List<String> allTripContributors,
      required String currentUserName,
      required String defaultCurrency})
      : title = '',
        totalExpense = CurrencyWithValue(currency: defaultCurrency, amount: 0),
        category = ExpenseCategory.Other,
        paidBy = Map.fromIterables(
            allTripContributors, List.filled(allTripContributors.length, 0)),
        splitBy = [currentUserName];

  void copyWith(ExpenseModelFacade expenseModelFacade) {
    tripId = expenseModelFacade.tripId;
    title = expenseModelFacade.title;
    description = expenseModelFacade.description;
    id = expenseModelFacade.id;
    totalExpense = expenseModelFacade.totalExpense;
    category = expenseModelFacade.category;
    paidBy = expenseModelFacade.paidBy;
    splitBy = expenseModelFacade.splitBy;
    location = expenseModelFacade.location;
    dateTime = expenseModelFacade.dateTime;
  }

  ExpenseModelFacade clone() {
    return ExpenseModelFacade(
        tripId: tripId,
        title: title,
        description: description,
        id: id,
        totalExpense: totalExpense,
        category: category,
        paidBy: paidBy,
        splitBy: splitBy,
        location: location?.clone(),
        dateTime: dateTime);
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
