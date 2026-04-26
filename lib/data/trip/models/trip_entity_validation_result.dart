/// Common validation results for all trip entities.
/// Each entity type implements its own specific enum.

enum TransitValidationResult {
  valid,
  missingDepartureLocation,
  missingArrivalLocation,
  missingDepartureTime,
  missingArrivalTime,
  invalidTimeSequence, // Arrival before departure
  invalidFlightOperator,
  expenseInvalid,
}

/// Validation results for multi-leg journeys.
/// Combines per-leg individual errors and cross-leg sequence errors.
enum JourneyValidationResult {
  /// At least one leg has its own validation errors (see TransitValidationResult).
  legHasErrors,

  /// A leg departs before the previous leg's arrival (cross-leg sequence violation).
  sequenceViolation,
}

enum LodgingValidationResult {
  valid,
  missingLocation,
  missingCheckinTime,
  missingCheckoutTime,
  invalidTimeSequence, // Checkout before checkin
  expenseInvalid,
}

enum ItineraryPlanDataValidationResult {
  valid,
  noContent,
  sightInvalid,
  noteEmpty,
  checkListTitleNotValid,
  checkListItemEmpty,
}

enum SightValidationResult {
  valid,
  missingName,
  missingLocation,
  missingTime,
  expenseInvalid,
}

enum CheckListValidationResult {
  valid,
  missingTitle,
  itemsEmpty,
  itemEmpty,
}

enum TripMetadataValidationResult {
  valid,
  missingTitle,
  missingStartDate,
  missingEndDate,
  invalidDateRange,
}

enum ExpenseValidationResult {
  valid,
  invalidAmount,
  invalidCurrency,
  invalidSplit,
}

enum ItineraryValidationResult {
  valid,
  planDataInvalid,
  duplicateLodging,
}
