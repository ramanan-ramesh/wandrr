import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/firestore_helpers.dart';
import 'package:wandrr/data/trip/implementations/location.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/plan_data/check_list.dart';
import 'package:wandrr/data/trip/models/plan_data/note.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';

import 'check_list.dart';

// ignore: must_be_immutable
class PlanDataModelImplementation extends PlanDataFacade
    implements LeafRepositoryItem<PlanDataFacade> {
  static const _titleField = 'title';
  final String _collectionName;

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
        .map(CheckListModelImplementation.fromModelFacade));
    return PlanDataModelImplementation._(
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
    var documentData = documentSnapshot.data() as Map<String, dynamic>;
    var title = documentData[_titleField];

    var checkLists = <CheckListModelImplementation>[];
    var notes = <NoteFacade>[];
    var places = <LocationModelImplementation>[];
    for (final checkListDocumentData in List<Map<String, dynamic>>.from(
        documentData.containsKey(_checkListsField)
            ? documentData[_checkListsField]
            : [])) {
      var checkList = CheckListModelImplementation.fromDocumentData(
          documentData: checkListDocumentData, tripId: tripId);
      checkLists.add(checkList);
    }

    for (final noteDocumentData in List<String>.from(
        documentData.containsKey(_notesField)
            ? documentData[_notesField]
            : [])) {
      var note = NoteFacade(note: noteDocumentData, tripId: tripId);
      notes.add(note);
    }

    for (final placesDocumentData in List<Map<String, dynamic>>.from(
        documentData.containsKey(_placesField)
            ? documentData[_placesField]
            : [])) {
      var place = LocationModelImplementation.fromJson(
          json: placesDocumentData, tripId: tripId);
      places.add(place);
    }

    return PlanDataModelImplementation._(
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
      : this._(
            id: id,
            tripId: tripId,
            collectionName: collectionName,
            checkLists: [],
            places: [],
            notes: []);

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
  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    if (title != null && title!.isNotEmpty) {
      json[_titleField] = title;
    }
    if (_notes.isNotEmpty) {
      var validNotes = _notes.where((note) => note.note.isNotEmpty).toList();
      if (validNotes.isNotEmpty) {
        json[_notesField] =
            List<String>.from(validNotes.map((note) => note.note));
      }
    }
    if (_checkLists.isNotEmpty) {
      var validChecklists = <CheckListModelImplementation>[];
      for (var checkListImplementation in _checkLists) {
        var checkList = checkListImplementation.facade;
        var isTitleValid =
            checkList.title != null && checkList.title!.isNotEmpty;
        var areItemsValid = checkList.items.isNotEmpty;
        if (isTitleValid && areItemsValid) {
          validChecklists.add(checkListImplementation);
        }
      }
      if (validChecklists.isNotEmpty) {
        json[_checkListsField] = List<Map<String, dynamic>>.from(
            validChecklists.map((checkList) => checkList.toJson()));
      }
    }
    if (_places.isNotEmpty) {
      json[_placesField] = List<Map<String, dynamic>>.from(
          _places.map((place) => place.toJson()));
    }
    return json;
  }

  @override
  Future<bool> tryUpdate(PlanDataFacade toUpdate) async {
    var json = <String, dynamic>{};
    var shouldUpdate = false;
    if (title != toUpdate.title) {
      shouldUpdate = true;
      json[_titleField] = toUpdate.title;
    }
    if (!listEquals(checkLists, toUpdate.checkLists)) {
      json[_checkListsField] = List<Map<String, dynamic>>.from(
          toUpdate.checkLists.map((checkList) =>
              CheckListModelImplementation.fromModelFacade(checkList)
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
              .map(CheckListModelImplementation.fromModelFacade)
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

  PlanDataModelImplementation._(
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
        super(
            id: id,
            tripId: tripId,
            title: title,
            places: places,
            notes: notes,
            checkLists: checkLists,
            isForItinerary: collectionName ==
                FirestoreCollections.itineraryDataCollectionName);
}
