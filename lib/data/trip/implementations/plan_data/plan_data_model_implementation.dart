import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wandrr/data/app/models/dispose.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/firestore_helpers.dart';
import 'package:wandrr/data/trip/implementations/location.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/plan_data/check_list.dart';
import 'package:wandrr/data/trip/models/plan_data/note.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';

import 'check_list.dart';

class PlanDataModelImplementation extends PlanDataFacade
    implements LeafRepositoryItem<PlanDataFacade>, Dispose {
  static const _titleField = 'title';

  final String _collectionName;

  @override
  List<LocationFacade> get places =>
      List.from(_places.map((place) => place.clone()));
  List<LocationModelImplementation> _places;
  static const _placesField = 'places';

  @override
  List<NoteFacade> get notes => List.from(_notes.map((note) => note.clone()));
  List<NoteFacade> _notes;
  static const _notesField = 'notes';

  @override
  List<CheckListFacade> get checkLists => List<CheckListFacade>.from(
      _checkLists.map((checkList) => checkList.clone()));
  List<CheckListModelImplementation> _checkLists;
  static const _checkListsField = 'checkLists';

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripCollectionName)
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
  Future<bool> tryUpdate(PlanDataFacade toUpdate) async {
    var json = <String, dynamic>{};
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
        documentReference: documentReference,
        json: json,
        onSuccess: () {
          var planData = toUpdate.clone();
          title = planData.title;
          _notes = toUpdate.notes.map((e) => e.clone()).toList();
          _checkLists = toUpdate.checkLists
              .map((e) => CheckListModelImplementation.fromModelFacade(
                  checkListModelFacade: e))
              .toList();
          _places = toUpdate.places
              .map((e) => LocationModelImplementation.fromModelFacade(
                  locationModelFacade: e,
                  collectionName: _collectionName,
                  parentId: id))
              .toList();
        });
  }

  @override
  PlanDataFacade get facade => clone();

  @override
  Future dispose() async {}

  static PlanDataModelImplementation fromModelFacade(
      {required PlanDataFacade planDataFacade,
      String collectionName = FirestoreCollections.planDataCollectionName}) {
    var planDataId = planDataFacade.id;
    var places = List<LocationModelImplementation>.from(planDataFacade.places
        .map((place) => LocationModelImplementation.fromModelFacade(
            locationModelFacade: place,
            collectionName: collectionName,
            parentId: planDataFacade.id)));
    var notes =
        List<NoteFacade>.from(planDataFacade.notes.map((note) => note.clone()));
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

  static PlanDataModelImplementation fromDocumentSnapshot(
      {required String tripId,
      required DocumentSnapshot documentSnapshot,
      String collectionName = FirestoreCollections.planDataCollectionName}) {
    var documentData = documentSnapshot.data() as Map<String, dynamic>? ?? {};
    var title = documentData[_titleField];

    var checkLists = <CheckListModelImplementation>[];
    var notes = <NoteFacade>[];
    var places = <LocationModelImplementation>[];
    for (final checkListDocumentData in List<Map<String, dynamic>>.from(
        documentData[_checkListsField] ?? [])) {
      var checkList = CheckListModelImplementation.fromDocumentData(
          documentData: checkListDocumentData, tripId: tripId);
      checkLists.add(checkList);
    }

    for (final noteDocumentData
        in List<String>.from(documentData[_notesField] ?? [])) {
      var note = NoteFacade(note: noteDocumentData, tripId: tripId);
      notes.add(note);
    }

    for (final placesDocumentData
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
      String collectionName = FirestoreCollections.planDataCollectionName})
      : this(
            id: id,
            tripId: tripId,
            collectionName: collectionName,
            checkLists: [],
            places: [],
            notes: []);

  PlanDataModelImplementation(
      {required String tripId,
      required String collectionName,
      required List<CheckListModelImplementation> checkLists,
      required List<NoteFacade> notes,
      required List<LocationModelImplementation> places,
      String? id,
      String? title})
      : _checkLists = checkLists,
        _notes = notes,
        _places = places,
        _collectionName = collectionName,
        super.newUiEntry(id: id, tripId: tripId, title: title);
}
