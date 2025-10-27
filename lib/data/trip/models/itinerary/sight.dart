import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

class SightFacade extends Equatable
    implements ExpenseLinkedTripEntity<SightFacade> {
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
          tripId: tripId,
          defaultCurrency: defaultCurrency,
          allTripContributors: contributors,
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
    return name.isNotEmpty &&
        name.length >= 3 &&
        (location != null || visitTime != null);
  }

  @override
  List<Object?> get props =>
      [tripId, id, name, location, visitTime, expense, description, day];
}
