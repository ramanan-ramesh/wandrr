// Defines item kinds and editor configuration for itinerary plan data editing.

enum PlanDataType { sight, note, checklist }

abstract class ItineraryPlanDataEditorConfig {
  PlanDataType get planDataType;
}

class CreateNewItineraryPlanDataComponentConfig
    implements ItineraryPlanDataEditorConfig {
  @override
  final PlanDataType planDataType;

  const CreateNewItineraryPlanDataComponentConfig({
    required this.planDataType,
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
