import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wandrr/data/trip/models/core/model_types.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';

part 'itinerary_plan_data.freezed.dart';

/// Itinerary-specific plan data with sights, notes, and checklists.
@freezed
class ItineraryPlanData
    with _$ItineraryPlanData
    implements TripEntity<ItineraryPlanData> {
  const ItineraryPlanData._();

  const factory ItineraryPlanData({
    required String tripId,
    required DateTime day,
    String? id,
    @Default([]) List<Sight> sights,
    @Default([]) List<String> notes,
    @Default([]) List<CheckList> checkLists,
  }) = _ItineraryPlanData;

  /// Creates a new empty itinerary plan
  factory ItineraryPlanData.newEntry({
    required String tripId,
    required DateTime day,
  }) =>
      ItineraryPlanData(
        tripId: tripId,
        day: day,
      );

  @override
  ItineraryPlanData clone() => copyWith(
        sights: sights.map((s) => s.clone()).toList(),
        notes: List.from(notes),
        checkLists: checkLists.map((c) => c.copyWith()).toList(),
      );

  @override
  bool validate() {
    final result = getValidationResult();
    return result == ItineraryPlanDataValidationResult.valid ||
        result == ItineraryPlanDataValidationResult.noContent;
  }

  ItineraryPlanDataValidationResult getValidationResult() {
    // At least one of: sights, notes, or checklists must be present
    if (sights.isEmpty && notes.isEmpty && checkLists.isEmpty) {
      return ItineraryPlanDataValidationResult.noContent;
    }

    // Validate sights
    if (sights.isNotEmpty && sights.any((sight) => !sight.validate())) {
      return ItineraryPlanDataValidationResult.sightInvalid;
    }

    // Validate notes
    if (notes.isNotEmpty && notes.any((note) => note.isEmpty)) {
      return ItineraryPlanDataValidationResult.noteEmpty;
    }

    // Validate checklists
    if (checkLists.isNotEmpty) {
      if (checkLists.any((c) => !c.isValid)) {
        return ItineraryPlanDataValidationResult.checkListTitleNotValid;
      }
    }

    return ItineraryPlanDataValidationResult.valid;
  }
}

enum ItineraryPlanDataValidationResult {
  valid,
  noContent,
  sightInvalid,
  noteEmpty,
  checkListTitleNotValid,
  checkListItemEmpty,
}

// Legacy alias for backward compatibility
typedef ItineraryPlanDataFacade = ItineraryPlanData;
