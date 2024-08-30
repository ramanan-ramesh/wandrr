import 'package:equatable/equatable.dart';

class NoteModelFacade extends Equatable {
  String tripId;

  String note;

  NoteModelFacade({
    required this.note,
    required this.tripId,
  });

  NoteModelFacade.newUiEntry({
    required this.note,
    required this.tripId,
  });

  void copyWith(NoteModelFacade noteModelFacade) {
    note = noteModelFacade.note;
  }

  NoteModelFacade clone() {
    return NoteModelFacade(note: note, tripId: tripId);
  }

  @override
  List<Object?> get props => [tripId, note];
}
