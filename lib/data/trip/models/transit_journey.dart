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

  /// Calculate layover duration between two legs
  Duration? getLayoverDuration(int fromLegIndex) {
    if (fromLegIndex < 0 || fromLegIndex >= legs.length - 1) {
      return null;
    }
    final currentArrival = legs[fromLegIndex].arrivalDateTime;
    final nextDeparture = legs[fromLegIndex + 1].departureDateTime;
    if (currentArrival == null || nextDeparture == null) {
      return null;
    }
    return nextDeparture.difference(currentArrival);
  }
}
