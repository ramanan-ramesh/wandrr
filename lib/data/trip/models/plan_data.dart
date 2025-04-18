import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'check_list.dart';
import 'location/location.dart';
import 'note.dart';

class PlanDataFacade extends Equatable implements TripEntity {
  final String tripId;

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

  PlanDataValidationResult getValidationResult(bool isTitleRequired) {
    if (isTitleRequired) {
      if (title == null || title!.isEmpty) {
        return PlanDataValidationResult.titleEmpty;
      }
    }
    if (notes.isEmpty && checkLists.isEmpty && places.isEmpty) {
      return PlanDataValidationResult.noNotesOrCheckListsOrPlaces;
    }
    if (notes.isNotEmpty) {
      if (notes.any((noteFacade) => noteFacade.note.isEmpty)) {
        return PlanDataValidationResult.noteEmpty;
      }
    }
    if (checkLists.isNotEmpty) {
      if (checkLists.any((checkList) =>
          checkList.title == null || checkList.title!.length < 3)) {
        return PlanDataValidationResult.checkListTitleNotValid;
      }
      if (checkLists.any((checkList) =>
          checkList.items.isEmpty ||
          checkList.items.any((checkListItem) => checkListItem.item.isEmpty))) {
        return PlanDataValidationResult.checkListItemEmpty;
      }
    }
    return PlanDataValidationResult.valid;
  }

  @override
  List<Object?> get props => [tripId, id, title, places, notes, checkLists];
}

enum PlanDataValidationResult {
  valid,
  titleEmpty,
  noteEmpty,
  checkListTitleNotValid,
  checkListItemEmpty,
  noNotesOrCheckListsOrPlaces
}
