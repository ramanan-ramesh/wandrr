import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';

/// Itinerary-specific plan data with sights, notes, and checklists
class ItineraryPlanData extends Equatable
    implements TripEntity<ItineraryPlanDataValidationError> {
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
  Iterable<ItineraryPlanDataValidationError> getValidationErrors() {
    // An empty plan is valid — content will be added during editing.
    if (sights.isEmpty && notes.isEmpty && checkLists.isEmpty) {
      return const [];
    }

    final errors = <ItineraryPlanDataValidationError>[];

    if (sights.isNotEmpty &&
        sights.any((sight) => sight.getValidationErrors().isNotEmpty)) {
      errors.add(ItineraryPlanDataValidationError.sightInvalid);
    }

    // Two or more sights sharing the same visit time is a conflict.
    if (sights.length > 1) {
      final nonNullTimes =
          sights.map((s) => s.visitTime).whereType<DateTime>().toList();
      if (nonNullTimes.toSet().length < nonNullTimes.length) {
        errors.add(ItineraryPlanDataValidationError.sightsVisitTimesOverlap);
      }
    }

    if (notes.isNotEmpty && notes.any((note) => note.isEmpty)) {
      errors.add(ItineraryPlanDataValidationError.noteEmpty);
    }

    if (checkLists.isNotEmpty) {
      if (checkLists.any((checkList) =>
          checkList.title == null || checkList.title!.length < 3)) {
        errors.add(ItineraryPlanDataValidationError.checkListTitleNotValid);
      }
      if (checkLists.any((checkList) =>
          checkList.items.isEmpty ||
          checkList.items.any((item) => item.item.isEmpty))) {
        errors.add(ItineraryPlanDataValidationError.checkListItemEmpty);
      }
    }

    return errors;
  }

  @override
  List<Object?> get props => [tripId, id, day, sights, notes, checkLists];
}
