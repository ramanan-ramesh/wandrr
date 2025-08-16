import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/models/plan_data/note.dart';

class NoteModelImplementation extends NoteFacade
    implements LeafRepositoryItem<NoteFacade> {
  static const _noteField = 'note';

  @override
  NoteFacade get facade => clone();

  @override
  String? id;

  @override
  DocumentReference<Object?> get documentReference =>
      throw UnimplementedError();

  NoteModelImplementation.fromModelFacade({
    required NoteFacade noteModelFacade,
  }) : super(note: noteModelFacade.note, tripId: noteModelFacade.tripId);

  static NoteModelImplementation fromDocumentSnapshot(
      {required DocumentSnapshot documentSnapshot, required String tripId}) {
    return NoteModelImplementation._(
        note: documentSnapshot[_noteField], tripId: tripId);
  }

  @override
  Map<String, dynamic> toJson() => {_noteField: note};

  @override
  Future<bool> tryUpdate(NoteFacade toUpdate) async {
    return true;
  }

  NoteModelImplementation._({
    required super.note,
    required super.tripId,
  });
}
