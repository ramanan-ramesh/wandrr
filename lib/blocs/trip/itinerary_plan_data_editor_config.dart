enum PlanDataType { sight, note, checklist }

abstract class ItineraryPlanDataEditorConfig {
  PlanDataType get planDataType;
}

class CreateNewItineraryPlanDataComponentConfig
    implements ItineraryPlanDataEditorConfig {
  @override
  final PlanDataType planDataType;

  /// The date for which the new itinerary item should be created,
  /// corresponding to the day currently displayed in the itinerary viewer.
  final DateTime date;

  const CreateNewItineraryPlanDataComponentConfig({
    required this.planDataType,
    required this.date,
  });
}

class UpdateItineraryPlanDataComponentConfig
    implements ItineraryPlanDataEditorConfig {
  @override
  final PlanDataType planDataType;
  final int index;

  const UpdateItineraryPlanDataComponentConfig({
    required this.planDataType,
    required this.index,
  });
}
