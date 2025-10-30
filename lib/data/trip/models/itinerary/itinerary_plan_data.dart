import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/plan_data/check_list.dart';
import 'package:wandrr/data/trip/models/plan_data/note.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Itinerary-specific plan data with sights, notes, and checklists
class ItineraryPlanData extends Equatable
    implements TripEntity<ItineraryPlanData> {
  final String tripId;

  @override
  String? id;

  /// The date this itinerary plan is for
  final DateTime day;

  /// List of sights/attractions to visit
  List<SightFacade> sights;

  /// Notes for the day
  List<NoteFacade> notes;

  /// Checklists for the day
  List<CheckListFacade> checkLists;

  ItineraryPlanData({
    required this.tripId,
    required this.day,
    required this.sights,
    required this.notes,
    required this.checkLists,
    this.id,
  });

  ItineraryPlanData.newEntry({
    required this.tripId,
    required this.day,
  })  : sights = [],
        notes = [],
        checkLists = [];

  @override
  ItineraryPlanData clone() => ItineraryPlanData(
        tripId: tripId,
        id: id,
        day: day,
        sights: List.from(sights.map((sight) => sight.clone())),
        notes: List.from(notes.map((note) => note.clone())),
        checkLists: List.from(checkLists.map((checkList) => checkList.clone())),
      );

  @override
  bool validate() {
    return getValidationResult() == ItineraryPlanDataValidationResult.valid;
  }

  ItineraryPlanDataValidationResult getValidationResult() {
    // At least one of: sights, notes, or checklists must be present
    if (sights.isEmpty && notes.isEmpty && checkLists.isEmpty) {
      return ItineraryPlanDataValidationResult.noContent;
    }

    // Validate sights
    if (sights.isNotEmpty) {
      if (sights.any((sight) => !sight.validate())) {
        return ItineraryPlanDataValidationResult.sightInvalid;
      }
    }

    // Validate notes
    if (notes.isNotEmpty) {
      if (notes.any((note) => note.note.isEmpty)) {
        return ItineraryPlanDataValidationResult.noteEmpty;
      }
    }

    // Validate checklists
    if (checkLists.isNotEmpty) {
      if (checkLists.any((checkList) =>
          checkList.title == null || checkList.title!.length < 3)) {
        return ItineraryPlanDataValidationResult.checkListTitleNotValid;
      }
      if (checkLists.any((checkList) =>
          checkList.items.isEmpty ||
          checkList.items
                  .where((checkListItem) => !checkListItem.item.isEmpty)
                  .length >=
              1)) {
        return ItineraryPlanDataValidationResult.checkListItemEmpty;
      }
    }

    return ItineraryPlanDataValidationResult.valid;
  }

  @override
  List<Object?> get props => [tripId, id, day, sights, notes, checkLists];
}

enum ItineraryPlanDataValidationResult {
  valid,
  noContent,
  sightInvalid,
  noteEmpty,
  checkListTitleNotValid,
  checkListItemEmpty,
}
