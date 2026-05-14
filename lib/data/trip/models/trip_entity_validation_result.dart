/// Common validation errors for all trip entities.
/// Each entity type implements its own specific enum.

enum TransitValidationError {
  missingDepartureLocation,
  missingArrivalLocation,
  missingDepartureTime,
  missingArrivalTime,
  invalidTimeSequence, // Arrival before departure
  invalidFlightOperator,
  expenseInvalid,
}

/// Validation errors for multi-leg journeys.
/// Combines per-leg individual errors and cross-leg sequence errors.
enum JourneyValidationError {
  /// At least one leg has its own validation errors (see TransitValidationResult).
  legHasErrors,

  /// A leg departs before the previous leg's arrival (cross-leg sequence violation).
  sequenceViolation,
}

enum LodgingValidationError {
  missingLocation,
  missingCheckinTime,
  missingCheckoutTime,
  invalidTimeSequence, // Checkout before checkin
  expenseInvalid,
}

enum ItineraryPlanDataValidationError {
  sightInvalid,
  sightsVisitTimesOverlap,
  noteEmpty,
  checkListTitleNotValid,
  checkListItemEmpty,
}

enum SightValidationError {
  missingName,
  missingLocation,
  missingTime,
  expenseInvalid,
}

enum CheckListValidationError {
  missingTitle,
  itemsEmpty,
  itemEmpty,
}

enum TripMetadataValidationError {
  missingTitle,
  missingStartDate,
  missingEndDate,
  invalidDateRange,
}

enum ExpenseValidationError {
  invalidAmount,
  invalidCurrency,
  invalidSplit,
}

enum ItineraryValidationError {
  planDataInvalid,
  duplicateLodging,
}
