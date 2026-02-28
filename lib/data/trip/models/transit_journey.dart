import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/transit.dart';

/// Read-only representation of a multi-leg journey.
/// Created by grouping TransitFacade items by journeyId.
/// Not stored in DB - purely for UI/business logic.
class TransitJourneyFacade {
  final String journeyId;
  final String tripId;

  /// Legs sorted by departureDateTime (ascending)
  final List<TransitFacade> legs;

  TransitJourneyFacade({
    required this.journeyId,
    required this.tripId,
    required List<TransitFacade> unsortedLegs,
  }) : legs = List.from(unsortedLegs)
          ..sort((a, b) => (a.departureDateTime ?? DateTime(0))
              .compareTo(b.departureDateTime ?? DateTime(0)));

  // Convenience getters
  TransitFacade get firstLeg => legs.first;

  TransitFacade get lastLeg => legs.last;

  LocationFacade? get departureLocation => firstLeg.departureLocation;

  DateTime? get departureDateTime => firstLeg.departureDateTime;

  LocationFacade? get arrivalLocation => lastLeg.arrivalLocation;

  DateTime? get arrivalDateTime => lastLeg.arrivalDateTime;

  /// All intermediate stops (arrival locations except the last)
  List<LocationFacade?> get intermediateStops =>
      legs.take(legs.length - 1).map((l) => l.arrivalLocation).toList();

  /// Total expense amount across all legs (in the currency of the first leg)
  double get totalExpenseAmount => legs.fold(
        0.0,
        (sum, leg) => sum + leg.expense.totalExpense.amount,
      );

  /// Currency of the journey (uses first leg's currency)
  String get currency => legs.first.expense.currency;

  /// Validates all legs and their time sequence
  bool validate() {
    if (legs.isEmpty) return false;
    if (!legs.every((leg) => leg.validate())) return false;

    // Validate time sequence:
    // 1. Each leg's arrival must be at least 1 minute after its departure
    // 2. Each connecting leg's departure must be on or after the previous leg's arrival
    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];

      // Check arrival is at least 1 minute after departure
      if (leg.departureDateTime != null && leg.arrivalDateTime != null) {
        final minArrival =
            leg.departureDateTime!.add(const Duration(minutes: 1));
        if (leg.arrivalDateTime!.isBefore(minArrival)) return false;
      }

      // Check connecting leg's departure is on or after previous leg's arrival
      if (i > 0) {
        final prevArrival = legs[i - 1].arrivalDateTime;
        final currentDeparture = leg.departureDateTime;
        if (prevArrival != null && currentDeparture != null) {
          if (currentDeparture.isBefore(prevArrival)) return false;
        }
      }
    }
    return true;
  }

  /// Get validation errors for display
  List<JourneyValidationError> getValidationErrors() {
    final errors = <JourneyValidationError>[];

    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];

      if (!leg.validate()) {
        errors.add(LegInvalidError(legIndex: i));
      }

      // Check arrival is at least 1 minute after departure
      if (leg.departureDateTime != null && leg.arrivalDateTime != null) {
        final minArrival =
            leg.departureDateTime!.add(const Duration(minutes: 1));
        if (leg.arrivalDateTime!.isBefore(minArrival)) {
          errors.add(ArrivalBeforeDepartureError(legIndex: i));
        }
      }

      // Check connecting leg's departure is on or after previous leg's arrival
      if (i > 0) {
        final prevArrival = legs[i - 1].arrivalDateTime;
        final currentDeparture = leg.departureDateTime;
        if (prevArrival != null && currentDeparture != null) {
          if (currentDeparture.isBefore(prevArrival)) {
            errors.add(TimeSequenceError(
              fromLegIndex: i - 1,
              toLegIndex: i,
            ));
          }
        }
      }
    }

    return errors;
  }

  /// Calculate layover duration between two legs
  Duration? getLayoverDuration(int fromLegIndex) {
    if (fromLegIndex < 0 || fromLegIndex >= legs.length - 1) return null;
    final currentArrival = legs[fromLegIndex].arrivalDateTime;
    final nextDeparture = legs[fromLegIndex + 1].departureDateTime;
    if (currentArrival == null || nextDeparture == null) return null;
    return nextDeparture.difference(currentArrival);
  }
}

/// Validation error types for journey
sealed class JourneyValidationError {
  const JourneyValidationError();
}

class LegInvalidError extends JourneyValidationError {
  final int legIndex;

  const LegInvalidError({required this.legIndex});
}

/// Error when arrival time is not at least 1 minute after departure
class ArrivalBeforeDepartureError extends JourneyValidationError {
  final int legIndex;

  const ArrivalBeforeDepartureError({required this.legIndex});
}

/// Error when connecting leg's departure is before previous leg's arrival
class TimeSequenceError extends JourneyValidationError {
  final int fromLegIndex;
  final int toLegIndex;

  const TimeSequenceError({
    required this.fromLegIndex,
    required this.toLegIndex,
  });
}
