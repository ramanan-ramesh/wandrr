import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_journey.dart';

/// Service for managing multi-leg journeys.
/// Handles grouping, validation, and querying operations.
abstract class TransitJourneyServiceFacade {
  /// Get all standalone legs (no journeyId)
  List<TransitFacade> get standaloneLegs;

  /// Get all grouped journeys
  List<TransitJourneyFacade> get journeys;

  /// Get a specific journey by ID
  TransitJourneyFacade? getJourney(String journeyId);

  /// Get all legs for a journey
  List<TransitFacade> getLegsForJourney(String journeyId);

  /// Check if a leg is part of a journey
  bool isLegPartOfJourney(TransitFacade leg);

  /// Get the journey that contains a specific leg
  TransitJourneyFacade? getJourneyForLeg(TransitFacade leg);
}

class TransitJourneyService implements TransitJourneyServiceFacade {
  final ModelCollectionFacade<TransitFacade> _legCollection;

  TransitJourneyService(this._legCollection);

  @override
  List<TransitFacade> get standaloneLegs => _legCollection.collectionItems
      .where((leg) => leg.journeyId == null)
      .toList();

  @override
  List<TransitJourneyFacade> get journeys {
    final grouped = <String, List<TransitFacade>>{};

    for (final leg in _legCollection.collectionItems) {
      if (leg.journeyId != null) {
        grouped.putIfAbsent(leg.journeyId!, () => []).add(leg);
      }
    }

    return grouped.entries
        .map((e) => TransitJourneyFacade(
              journeyId: e.key,
              tripId: e.value.first.tripId,
              unsortedLegs: e.value,
            ))
        .toList();
  }

  @override
  TransitJourneyFacade? getJourney(String journeyId) {
    final legs = getLegsForJourney(journeyId);
    if (legs.isEmpty) return null;
    return TransitJourneyFacade(
      journeyId: journeyId,
      tripId: legs.first.tripId,
      unsortedLegs: legs,
    );
  }

  @override
  List<TransitFacade> getLegsForJourney(String journeyId) =>
      _legCollection.collectionItems
          .where((leg) => leg.journeyId == journeyId)
          .toList();

  @override
  bool isLegPartOfJourney(TransitFacade leg) => leg.journeyId != null;

  @override
  TransitJourneyFacade? getJourneyForLeg(TransitFacade leg) {
    if (leg.journeyId == null) return null;
    return getJourney(leg.journeyId!);
  }
}
