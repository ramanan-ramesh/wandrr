import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

import '../budgeting/expense_category.dart';

class SightFacade extends Equatable
    implements ExpenseBearingTripEntity<SightFacade> {
  final String tripId;

  @override
  String? id;

  @override
  ExpenseFacade expense;

  final DateTime day;
  String name;

  LocationFacade? location;
  DateTime? visitTime;
  String? description;

  @override
  ExpenseCategory get category => ExpenseCategory.sightseeing;

  @override
  set category(ExpenseCategory value) {}

  @override
  String get title => toString();

  @override
  set title(String value) {}

  SightFacade({
    required this.tripId,
    required this.name,
    required this.day,
    required this.expense,
    this.id,
    this.location,
    this.visitTime,
    this.description,
  });

  SightFacade.newEntry(
      {required this.tripId,
      required this.day,
      required String defaultCurrency,
      required Iterable<String> contributors})
      : name = '',
        id = '',
        expense = ExpenseFacade.newUiEntry(
          defaultCurrency: defaultCurrency,
          allTripContributors: contributors,
          category: ExpenseCategory.sightseeing,
        );

  @override
  SightFacade clone() => SightFacade(
        tripId: tripId,
        id: id,
        name: name,
        location: location?.clone(),
        visitTime: visitTime?.copyWith(),
        expense: expense.clone(),
        description: description,
        day: day,
      );

  @override
  bool validate() {
    return name.isNotEmpty && name.length >= 3;
  }

  @override
  String toString() {
    var sightDescription = name;
    if (visitTime != null) {
      sightDescription += ' on ${visitTime!.dayDateMonthFormat}';
    }
    return sightDescription;
  }

  @override
  List<Object?> get props =>
      [tripId, id, name, location, visitTime, expense, description, day];
}
