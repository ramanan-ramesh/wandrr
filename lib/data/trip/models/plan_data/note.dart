import 'package:equatable/equatable.dart';

class NoteFacade extends Equatable {
  final String tripId;

  String note;

  NoteFacade({
    required this.note,
    required this.tripId,
  });

  NoteFacade.newUiEntry({
    required this.note,
    required this.tripId,
  });

  NoteFacade clone() {
    return NoteFacade(note: note, tripId: tripId);
  }

  @override
  List<Object?> get props => [tripId, note];
}
