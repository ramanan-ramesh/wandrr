import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';

import '../budgeting/expense_category.dart';

class SightFacade extends Equatable
    implements ExpenseBearingTripEntity<SightValidationError> {
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
        day: DateTime(day.year, day.month, day.day),
      );

  @override
  Iterable<SightValidationError> getValidationErrors() {
    final errors = <SightValidationError>[];
    if (name.isEmpty || name.length < 3) {
      errors.add(SightValidationError.missingName);
    }
    // Location and time are optional for sights, but we can validate expense
    if (!expense.isValid) {
      errors.add(SightValidationError.expenseInvalid);
    }
    return errors;
  }

  @override
  String toString() {
    var sightDescription = name;
    if (visitTime != null) {
      sightDescription += ' on ${visitTime!.dayDateMonthFormat}';
    }
    return sightDescription;
  }

  // Normalise nullable-but-semantically-empty string fields so that null and
  // "" compare equal (e.g. id = "" for new entries vs null from Firestore).
  static String? _n(String? s) => (s == null || s.isEmpty) ? null : s;

  @override
  List<Object?> get props => [
        tripId,
        _n(id),
        name,
        location,
        visitTime,
        expense,
        _n(description),
        day
      ];
}
