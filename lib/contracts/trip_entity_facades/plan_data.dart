import 'package:equatable/equatable.dart';
import 'package:wandrr/contracts/trip_entity.dart';

import '../check_list.dart';
import '../note.dart';
import 'location.dart';

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

  @override
  List<Object?> get props => [tripId, id, title, places, notes, checkLists];
}
