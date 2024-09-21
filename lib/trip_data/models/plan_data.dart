import 'package:equatable/equatable.dart';
import 'package:wandrr/trip_data/models/trip_entity.dart';

import 'check_list.dart';
import 'location/location.dart';
import 'note.dart';

class PlanDataFacade extends Equatable implements TripEntity {
  String tripId;

  @override
  String? id;

  String? title;

  List<LocationFacade> places;

  List<NoteFacade> notes;

  List<CheckListFacade> checkLists;

  PlanDataFacade.newUiEntry(
      {required this.id, required this.tripId, this.title})
      : places = [],
        notes = [],
        checkLists = [];

  PlanDataFacade(
      {required this.tripId,
      this.id,
      this.title,
      required this.places,
      required this.notes,
      required this.checkLists});

  PlanDataFacade clone() {
    return PlanDataFacade(
        tripId: tripId,
        id: id,
        title: title,
        places: List.from(places.map((place) => place.clone())),
        notes: List.from(notes.map((note) => note.clone())),
        checkLists:
            List.from(checkLists.map((checkList) => checkList.clone())));
  }

  bool isValid(bool isTitleRequired) {
    var isAnyNoteEmpty = notes.any((noteFacade) => noteFacade.note.isEmpty);
    var isAnyCheckListEmpty = false;
    for (var checkList in checkLists) {
      if (checkList.items.isEmpty ||
          checkList.items.any((checkListItem) => checkListItem.item.isEmpty)) {
        isAnyCheckListEmpty = true;
      }
    }
    var isTitleEmpty = title?.isEmpty ?? true;

    var areThereAnyNotesOrCheckListsOrPlaces =
        notes.isNotEmpty || checkLists.isNotEmpty || places.isNotEmpty;
    return !isAnyNoteEmpty &&
        (isTitleRequired ? !isTitleEmpty : true) &&
        !isAnyCheckListEmpty &&
        areThereAnyNotesOrCheckListsOrPlaces;
  }

  @override
  List<Object?> get props => [tripId, id, title, places, notes, checkLists];
}
