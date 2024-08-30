import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/contracts/note.dart';
import 'package:wandrr/contracts/repository_pattern.dart';

class NoteModelImplementation extends NoteModelFacade
    implements RepositoryPattern<NoteModelFacade> {
  static const _noteField = 'note';

  @override
  NoteModelFacade get facade => this;

  @override
  String? id;

  @override
  DocumentReference<Object?> get documentReference =>
      throw UnimplementedError();

  NoteModelImplementation.fromModelFacade({
    required NoteModelFacade noteModelFacade,
  }) : super(note: noteModelFacade.note, tripId: noteModelFacade.tripId);

  static NoteModelImplementation fromDocumentSnapshot(
      {required DocumentSnapshot documentSnapshot, required String tripId}) {
    return NoteModelImplementation._(
        note: documentSnapshot[_noteField], tripId: tripId);
  }

  @override
  Map<String, dynamic> toJson() => {_noteField: note};

  @override
  Future<bool> tryUpdate(NoteModelFacade toUpdate) async {
    return true;
  }

  NoteModelImplementation._({
    required super.note,
    required super.tripId,
  });
}
