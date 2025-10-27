import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

class SightFacade extends Equatable implements TripEntity<SightFacade> {
  final String tripId;

  @override
  String? id;

  final DateTime day;
  String name;

  LocationFacade? location;
  DateTime? visitTime;
  ExpenseFacade? expense;
  String? description;

  SightFacade({
    required this.tripId,
    required this.name,
    required this.day,
    this.id,
    this.location,
    this.visitTime,
    this.expense,
    this.description,
  });

  SightFacade.newEntry({required this.tripId, required this.day})
      : name = '',
        id = '';

  @override
  SightFacade clone() => SightFacade(
        tripId: tripId,
        id: id,
        name: name,
        location: location?.clone(),
        visitTime: visitTime?.copyWith(),
        expense: expense?.clone(),
        description: description,
        day: day,
      );

  @override
  bool validate() {
    return name.isNotEmpty &&
        name.length >= 3 &&
        (location != null || visitTime != null || expense != null);
  }

  @override
  List<Object?> get props =>
      [tripId, id, name, location, visitTime, expense, description, day];
}
