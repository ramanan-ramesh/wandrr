import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wandrr/contracts/check_list.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/firestore_helpers.dart';
import 'package:wandrr/contracts/location.dart';
import 'package:wandrr/contracts/note.dart';
import 'package:wandrr/contracts/plan_data.dart';
import 'package:wandrr/contracts/repository_pattern.dart';

import 'check_list.dart';
import 'location.dart';

class PlanDataModelImplementation extends PlanDataModelFacade
    implements RepositoryPattern<PlanDataModelFacade>, Dispose {
  static const _titleField = 'title';

  final String _collectionName;

  @override
  List<LocationModelFacade> get places =>
      List.from(_places.map((place) => place.clone()));
  List<LocationModelImplementation> _places;
  static const _placesField = 'places';

  @override
  List<NoteModelFacade> get notes =>
      List.from(_notes.map((note) => note.clone()));
  List<NoteModelFacade> _notes;
  static const _notesField = 'notes';

  @override
  List<CheckListModelFacade> get checkLists => List<CheckListModelFacade>.from(
      _checkLists.map((checkList) => checkList.clone()));
  List<CheckListModelImplementation> _checkLists;
  static const _checkListsField = 'checkLists';

  @override
  set notes(List<NoteModelFacade> value) {
    _notes = List.from(value.map((note) => note.clone()));
  }

  @override
  set checkLists(List<CheckListModelFacade> value) {
    _checkLists = List.from(value.map((checkList) =>
        CheckListModelImplementation.fromModelFacade(
            checkListModelFacade: checkList.clone())));
  }

  @override
  set places(List<LocationModelFacade> placesToSet) {
    _places = List.from(placesToSet.map((place) =>
        LocationModelImplementation.fromModelFacade(
            locationModelFacade: place,
            collectionName: _collectionName,
            parentId: id)));
  }

  static PlanDataModelImplementation fromModelFacade(
      {required PlanDataModelFacade planDataFacade,
      String collectionName = FirestoreCollections.planDataListCollection}) {
    var planDataId = planDataFacade.id;
    var places = List<LocationModelImplementation>.from(planDataFacade.places
        .map((place) => LocationModelImplementation.fromModelFacade(
            locationModelFacade: place,
            collectionName: collectionName,
            parentId: planDataFacade.id)));
    var notes = List<NoteModelFacade>.from(
        planDataFacade.notes.map((note) => note.clone()));
    var checkLists = List<CheckListModelImplementation>.from(planDataFacade
        .checkLists
        .map((checkList) => CheckListModelImplementation.fromModelFacade(
            checkListModelFacade: checkList)));
    return PlanDataModelImplementation(
        id: planDataId,
        tripId: planDataFacade.tripId,
        title: planDataFacade.title,
        collectionName: collectionName,
        checkLists: checkLists,
        places: places,
        notes: notes);
  }

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripsCollection)
      .doc(tripId)
      .collection(_collectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() => {
        _titleField: title,
        _notesField: List<String>.from(_notes.map((note) => note.note)),
        _checkListsField: List<Map<String, dynamic>>.from(
            _checkLists.map((checkList) => checkList.toJson())),
        _placesField: List<Map<String, dynamic>>.from(
            _places.map((place) => place.toJson()))
      };

  @override
  Future<bool> tryUpdate(PlanDataModelFacade toUpdate) async {
    Map<String, dynamic> json = {};
    var shouldUpdate = false;
    if (title != toUpdate.title) {
      shouldUpdate = true;
      json[_titleField] = toUpdate.title;
    }
    if (!listEquals(checkLists, toUpdate.checkLists)) {
      json[_checkListsField] = List<Map<String, dynamic>>.from(toUpdate
          .checkLists
          .map((checkList) => CheckListModelImplementation.fromModelFacade(
                  checkListModelFacade: checkList)
              .toJson()));
      shouldUpdate = true;
    }

    if (!listEquals(places, toUpdate.places)) {
      json[_placesField] = List<Map<String, dynamic>>.from(toUpdate.places.map(
          (place) => LocationModelImplementation.fromModelFacade(
                  locationModelFacade: place)
              .toJson()));
      shouldUpdate = true;
    }
    if (!listEquals(_notes, toUpdate.notes)) {
      json[_notesField] =
          List<String>.from(toUpdate.notes.map((note) => note.note));
      shouldUpdate = true;
    }

    if (!shouldUpdate) {
      return false;
    }

    return await FirestoreHelpers.tryUpdateDocumentField(
        documentReference: documentReference, json: json);
  }

  static PlanDataModelImplementation fromDocumentSnapshot(
      {required String tripId,
      required DocumentSnapshot documentSnapshot,
      String collectionName = FirestoreCollections.planDataListCollection}) {
    var documentData = documentSnapshot.data() as Map<String, dynamic>? ?? {};
    var title = documentData[_titleField];

    var checkLists = <CheckListModelImplementation>[];
    var notes = <NoteModelFacade>[];
    var places = <LocationModelImplementation>[];
    for (var checkListDocumentData in List<Map<String, dynamic>>.from(
        documentData[_checkListsField] ?? [])) {
      var checkList = CheckListModelImplementation.fromDocumentData(
          documentData: checkListDocumentData, tripId: tripId);
      checkLists.add(checkList);
    }

    for (var noteDocumentData
        in List<String>.from(documentData[_notesField] ?? [])) {
      var note = NoteModelFacade(note: noteDocumentData, tripId: tripId);
      notes.add(note);
    }

    for (var placesDocumentData
        in List<Map<String, dynamic>>.from(documentData[_placesField] ?? [])) {
      var place = LocationModelImplementation.fromJson(
          json: placesDocumentData, tripId: tripId);
      places.add(place);
    }

    return PlanDataModelImplementation(
        id: documentSnapshot.id,
        tripId: tripId,
        title: title,
        collectionName: collectionName,
        checkLists: checkLists,
        places: places,
        notes: notes);
  }

  PlanDataModelImplementation.empty(
      {required String tripId,
      required String id,
      String collectionName = FirestoreCollections.planDataListCollection})
      : this(
            id: id,
            tripId: tripId,
            collectionName: collectionName,
            checkLists: [],
            places: [],
            notes: []);

  @override
  PlanDataModelFacade get facade => clone();

  @override
  Future dispose() async {}

  PlanDataModelImplementation(
      {String? id,
      required String tripId,
      String? title,
      required String collectionName,
      required List<CheckListModelImplementation> checkLists,
      required List<NoteModelFacade> notes,
      required List<LocationModelImplementation> places})
      : _checkLists = checkLists,
        _notes = notes,
        _places = places,
        _collectionName = collectionName,
        super.newUiEntry(id: id, tripId: tripId, title: title);
}
