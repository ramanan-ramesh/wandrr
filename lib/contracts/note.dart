import 'package:equatable/equatable.dart';

class NoteFacade extends Equatable {
  String tripId;

  String note;

  NoteFacade({
    required this.note,
    required this.tripId,
  });

  NoteFacade.newUiEntry({
    required this.note,
    required this.tripId,
  });

  void copyWith(NoteFacade noteModelFacade) {
    note = noteModelFacade.note;
  }

  NoteFacade clone() {
    return NoteFacade(note: note, tripId: tripId);
  }

  @override
  List<Object?> get props => [tripId, note];
}
