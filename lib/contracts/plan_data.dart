import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/firestore_helpers.dart';

import 'check_list.dart';
import 'collection_names.dart';
import 'location.dart';
import 'note.dart';

abstract class PlanDataFacade extends Equatable {
  String get id;

  String? get title;

  UnmodifiableListView<LocationFacade> get places;

  UnmodifiableListView<NoteFacade> get notes;

  UnmodifiableListView<CheckListFacade> get checkLists;
}

abstract class PlanDataModifier {
  Future<bool> updatePlanDataList({required PlanDataUpdator planDataUpdator});
  Future<bool> updateItineraryData(
      {required PlanDataUpdator planDataUpdator, required DateTime day});
}

class PlanData with EquatableMixin implements PlanDataFacade, PlanDataModifier {
  @override
  UnmodifiableListView<CheckListFacade> get checkLists =>
      UnmodifiableListView(_checkLists);
  List<CheckList> _checkLists;

  @override
  UnmodifiableListView<NoteFacade> get notes => UnmodifiableListView(_notes);
  List<Note> _notes;

  List<LocationFacade> _places;
  static const _placesField = 'places';

  @override
  UnmodifiableListView<LocationFacade> get places =>
      UnmodifiableListView(_places);

  @override
  String? get title => _title;
  static const _titleField = 'title';
  String? _title;

  @override
  final String id;

  final bool isPlanDataList;

  final String tripId;

  PlanData.empty({required this.tripId, required this.isPlanDataList})
      : _checkLists = [],
        _notes = [],
        _places = [],
        id = '';

  static Future<PlanData?> createFromUserInput(
      {required PlanDataUpdator planDataUpdator}) async {
    PlanData? createdPlanData;

    var areThereAnyNotes = planDataUpdator.noteUpdators != null &&
        planDataUpdator.noteUpdators!.isNotEmpty;
    var areThereAnyPlaces = planDataUpdator.locationListUpdator != null &&
        planDataUpdator.locationListUpdator!.places != null &&
        planDataUpdator.locationListUpdator!.places!.isNotEmpty;
    var areThereAnyCheckLists = planDataUpdator.checkListUpdators != null &&
        planDataUpdator.checkListUpdators!.isNotEmpty;

    if (!areThereAnyNotes && !areThereAnyCheckLists && !areThereAnyPlaces) {
      return createdPlanData;
    }

    Map<String, dynamic> json = {};

    FirestoreHelpers.updateJson(null, planDataUpdator.title, _titleField, json);

    var planDataListCollectionReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(planDataUpdator.tripId)
        .collection(FirestoreCollections.planDataListCollection);

    var planDataDocument = await planDataListCollectionReference
        .add({_titleField: planDataUpdator.title});
    createdPlanData = PlanData._create(
        isPlanDataList: true,
        places: [],
        notes: [],
        checkLists: [],
        id: planDataDocument.id,
        tripId: planDataUpdator.tripId);

    List<NoteFacade> notes = [];
    if (areThereAnyNotes) {
      for (var noteUpdator in planDataUpdator.noteUpdators!) {
        noteUpdator.planDataId = createdPlanData.id;
        var note = await Note.createFromUserInput(noteUpdator: noteUpdator);
        if (note != null) {
          notes.add(note);
        }
      }
    }

    List<CheckListFacade> checkLists = [];
    if (areThereAnyCheckLists) {
      for (var checkListUpdator in planDataUpdator.checkListUpdators!) {
        checkListUpdator.planDataId = createdPlanData.id;
        var checkList = await CheckList.createFromUserInput(
            checkListUpdator: checkListUpdator);
        checkLists.add(checkList!);
      }
    }

    List<LocationFacade> places =
        planDataUpdator.locationListUpdator?.places ?? [];
    if (areThereAnyPlaces) {
      var places = List<Map<String, dynamic>>.generate(
          planDataUpdator.locationListUpdator!.places!.length,
          (index) => (planDataUpdator.locationListUpdator!.places!
                  .elementAt(index) as Location)
              .toJson());
      FirestoreHelpers.updateJson(null, places, _placesField, json);
      await planDataDocument.set(json, SetOptions(merge: true));
    }

    return PlanData._create(
        isPlanDataList: true,
        places: places,
        notes: notes,
        checkLists: checkLists,
        id: planDataDocument.id,
        tripId: planDataUpdator.tripId);
  }

  static Future<PlanData> fromDocumentSnapshot(
      {required String tripId,
      required QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot,
      required bool isPlanDataList}) async {
    var documentSnapshotValue = documentSnapshot.data();
    List<Map<String, dynamic>>? placesValue =
        documentSnapshotValue[_placesField];
    List<LocationFacade> places = [];
    if (placesValue != null) {
      for (var place in placesValue) {
        places.add(Location.fromDocument(place));
      }
    }

    var notesCollection = await documentSnapshot.reference
        .collection(FirestoreCollections.notesCollection)
        .get();
    List<NoteFacade> notes = [];
    for (var noteDocument in notesCollection.docs) {
      notes.add(Note.fromDocumentSnapshot(documentSnapshot: noteDocument));
    }

    var checkListsCollection = await documentSnapshot.reference
        .collection(FirestoreCollections.checkListsCollection)
        .get();
    List<CheckList> checkLists = [];
    for (var checkListDocument in checkListsCollection.docs) {
      checkLists.add(
          CheckList.fromDocumentSnapshot(documentSnapshot: checkListDocument));
    }

    return PlanData._create(
        isPlanDataList: isPlanDataList,
        places: places,
        notes: notes,
        checkLists: checkLists,
        id: documentSnapshot.id,
        tripId: tripId);
  }

  @override
  Future<bool> updatePlanDataList(
      {required PlanDataUpdator planDataUpdator}) async {
    if (planDataUpdator.id == null) {
      return false;
    }

    var planDataListDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(planDataUpdator.tripId)
        .collection(FirestoreCollections.planDataListCollection)
        .doc(planDataUpdator.id!);

    return await _tryUpdatePlanData(
        planDataUpdator, planDataListDocumentReference);
  }

  @override
  Future<bool> updateItineraryData(
      {required PlanDataUpdator planDataUpdator, required DateTime day}) async {
    var planDataListDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(planDataUpdator.tripId)
        .collection(FirestoreCollections.itineraryDataCollection)
        .doc('${day.day} ${day.month}${day.year}');
    return await _tryUpdatePlanData(
        planDataUpdator, planDataListDocumentReference);
  }

  Future<bool> _tryUpdatePlanData(PlanDataUpdator planDataUpdator,
      DocumentReference<Map<String, dynamic>> documentReference) async {
    Map<String, dynamic> json = {};
    var didUpdate = false;
    FirestoreHelpers.updateJson(
        _title, planDataUpdator.title, _titleField, json);
    FirestoreHelpers.updateJson(_places,
        planDataUpdator.locationListUpdator?.places, _placesField, json);

    await FirestoreHelpers.tryUpdateDocumentField(
            documentReference: documentReference, json: json)
        .then((value) async {
      var notesCollectionReference =
          documentReference.collection(FirestoreCollections.notesCollection);
      var notesToUpdate = planDataUpdator.noteUpdators ?? [];
      for (var noteToUpdate
          in notesToUpdate.where((element) => element.id != null)) {
        var note =
            _notes.firstWhere((element) => element.id == noteToUpdate.id!);
        await note.update(noteUpdator: noteToUpdate);
      }
      for (var noteToRemove in _notes.where((note) => !notesToUpdate.any(
          (noteToUpdate) =>
              noteToUpdate.id != null && noteToUpdate.id! == note.id))) {
        await notesCollectionReference.doc(noteToRemove.id).delete();
      }
      for (var noteToAdd
          in notesToUpdate.where((element) => element.id == null)) {
        var noteCreated =
            await Note.createFromUserInput(noteUpdator: noteToAdd);
        if (noteCreated != null) {
          _notes.add(noteCreated as Note);
        }
      }

      var checkListCollectionReference = documentReference
          .collection(FirestoreCollections.checkListsCollection);
      var checkListsToUpdate = planDataUpdator.checkListUpdators ?? [];
      for (var checkListToUpdate
          in checkListsToUpdate.where((element) => element.id != null)) {
        var checkList = _checkLists
            .firstWhere((element) => element.id == checkListToUpdate.id!);
        await checkList.update(checkListUpdator: checkListToUpdate);
      }
      for (var checkListToRemove in _checkLists.where((checkList) =>
          !checkListsToUpdate.any((checkListToUpdate) =>
              checkListToUpdate.id != null &&
              checkListToUpdate.id! == checkList.id))) {
        await checkListCollectionReference.doc(checkListToRemove.id).delete();
      }
      for (var checkListToAdd
          in checkListsToUpdate.where((element) => element.id == null)) {
        var checkListCreated = await CheckList.createFromUserInput(
            checkListUpdator: checkListToAdd);
        if (checkListCreated != null) {
          _checkLists.add(checkListCreated as CheckList);
        }
      }
      didUpdate = true;
      _title = planDataUpdator.title;
      _places = planDataUpdator.locationListUpdator?.places ?? [];
    }).onError((error, stackTrace) {
      didUpdate = false;
    });
    return didUpdate;
  }

  @override
  bool? get stringify => false;

  PlanData._create(
      {required List<LocationFacade> places,
      required List<NoteFacade> notes,
      required List<CheckListFacade> checkLists,
      required this.id,
      required this.tripId,
      required this.isPlanDataList,
      String? title})
      : _checkLists = List.generate(checkLists.length,
            (index) => checkLists.elementAt(index) as CheckList),
        _places = places,
        _notes = List.generate(
            notes.length, (index) => notes.elementAt(index) as Note),
        _title = title;

  @override
  List<Object?> get props => [_title, _places, _notes, _checkLists, id];
}
