import 'package:equatable/equatable.dart';
import 'package:wandrr/contracts/trip_data.dart';

import 'check_list.dart';
import 'location.dart';
import 'note.dart';

class PlanDataModelFacade extends Equatable implements TripEntity {
  String tripId;

  @override
  String? id;

  String? title;

  List<LocationModelFacade> places;

  List<NoteModelFacade> notes;

  List<CheckListModelFacade> checkLists;

  PlanDataModelFacade.newUiEntry(
      {required this.id, required this.tripId, this.title})
      : places = [],
        notes = [],
        checkLists = [];

  PlanDataModelFacade(
      {required this.tripId,
      this.id,
      this.title,
      required this.places,
      required this.notes,
      required this.checkLists});

  PlanDataModelFacade clone() {
    return PlanDataModelFacade(
        tripId: tripId,
        id: id,
        title: title,
        places: List.from(places.map((place) => place.clone())),
        notes: List.from(notes.map((note) => note.clone())),
        checkLists:
            List.from(checkLists.map((checkList) => checkList.clone())));
  }

  @override
  List<Object?> get props => [tripId, id, title, places, notes, checkLists];
}
