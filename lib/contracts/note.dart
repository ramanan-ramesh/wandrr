import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/firestore_helpers.dart';

import 'collection_names.dart';

abstract class NoteFacade {
  String get id;
  String get note;
}

class Note with EquatableMixin implements NoteFacade {
  @override
  final String id;

  static const _noteField = 'note';
  String _note;
  @override
  String get note => _note;

  static FutureOr<NoteFacade?> createFromUserInput(
      {required NoteUpdator noteUpdator}) async {
    var notesCollection = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(noteUpdator.tripId)
        .collection(FirestoreCollections.planDataListCollection)
        .doc(noteUpdator.planDataId!)
        .collection(FirestoreCollections.notesCollection);
    Note? tempNoteObject = Note.create(id: '', note: noteUpdator.note!);
    await notesCollection.add(tempNoteObject.toJson()).then((noteDocument) =>
        tempNoteObject =
            Note.create(id: noteDocument.id, note: noteUpdator.note!));
    return tempNoteObject;
  }

  Future<bool> update({required NoteUpdator noteUpdator}) async {
    var noteDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(noteUpdator.tripId)
        .collection(FirestoreCollections.planDataListCollection)
        .doc(noteUpdator.planDataId!)
        .collection(FirestoreCollections.notesCollection)
        .doc(noteUpdator.id!);

    Map<String, dynamic> json = {};
    FirestoreHelpers.updateJson(_note, noteUpdator.note, _noteField, json);

    return await FirestoreHelpers.tryUpdateDocumentField(
        documentReference: noteDocumentReference,
        json: json,
        onSuccess: () {
          _note = noteUpdator.note!;
        });
  }

  Map<String, dynamic> toJson() => {_noteField: _note};

  static Note fromDocumentSnapshot(
      {required QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot}) {
    return Note.create(
        id: documentSnapshot.id, note: documentSnapshot[_noteField]);
  }

  Note.create({required this.id, required String note}) : _note = note;

  @override
  List<Object?> get props => [id, _note];
}
