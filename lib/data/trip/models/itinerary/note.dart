import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

// ignore: must_be_immutable
class NoteFacade extends Equatable implements TripEntity<NoteFacade> {
  final String tripId;

  @override
  String? id;

  String note;

  NoteFacade({
    required this.note,
    required this.tripId,
    this.id,
  });

  NoteFacade.newUiEntry({
    required this.note,
    required this.tripId,
    this.id,
  });

  @override
  NoteFacade clone() => NoteFacade(note: note, tripId: tripId);

  @override
  List<Object?> get props => [tripId, note];

  @override
  bool validate() {
    return note.isNotEmpty;
  }
}
