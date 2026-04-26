import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';

/// Itinerary-specific plan data with sights, notes, and checklists
class ItineraryPlanData extends Equatable
    implements TripEntity<ItineraryPlanDataValidationResult> {
  final String tripId;

  @override
  String? id;

  /// The date this itinerary plan is for
  DateTime day;

  /// List of sights/attractions to visit
  List<SightFacade> sights;

  /// Notes for the day
  List<String> notes;

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
        notes: List.from(notes),
        checkLists: List.from(checkLists.map((checkList) => checkList.clone())),
      );

  @override
  bool validate() {
    final errors = getValidationErrors();
    return errors.isEmpty ||
        errors.contains(ItineraryPlanDataValidationResult.noContent);
  }

  @override
  Iterable<ItineraryPlanDataValidationResult> getValidationErrors() {
    // At least one of: sights, notes, or checklists must be present
    if (sights.isEmpty && notes.isEmpty && checkLists.isEmpty) {
      return [ItineraryPlanDataValidationResult.noContent];
    }

    final errors = <ItineraryPlanDataValidationResult>[];

    // Validate sights
    if (sights.isNotEmpty) {
      if (sights.any((sight) => !sight.validate())) {
        errors.add(ItineraryPlanDataValidationResult.sightInvalid);
      }
    }

    // Validate notes
    if (notes.isNotEmpty) {
      if (notes.any((note) => note.isEmpty)) {
        errors.add(ItineraryPlanDataValidationResult.noteEmpty);
      }
    }

    // Validate checklists
    if (checkLists.isNotEmpty) {
      if (checkLists.any((checkList) =>
          checkList.title == null || checkList.title!.length < 3)) {
        errors.add(ItineraryPlanDataValidationResult.checkListTitleNotValid);
      }
      if (checkLists.any((checkList) =>
          checkList.items.isEmpty ||
          checkList.items
              .where((checkListItem) => checkListItem.item.isEmpty)
              .isNotEmpty)) {
        errors.add(ItineraryPlanDataValidationResult.checkListItemEmpty);
      }
    }

    return errors;
  }

  @override
  List<Object?> get props => [tripId, id, day, sights, notes, checkLists];
}

