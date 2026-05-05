import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/services/transit_journey_service.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_journey.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';

/// Service for managing multi-leg journeys.
/// Handles grouping, validation, querying operations, and expense calculations.
abstract class TransitJourneyServiceFacade {
  /// Get a specific journey by ID
  TransitJourneyFacade? getJourney(String journeyId);

  /// Returns all legs for a journey, or a single-element list with [fallback]
  /// if [journeyId] is null or the journey is not found.
  List<TransitFacade> getJourneyLegs(String? journeyId, TransitFacade fallback);

  /// If the provided list of legs has only one leg remaining, removes the journey ID from it.
  /// Returns `true` if it cleaned up a lone leg, `false` otherwise.
  bool cleanupJourneyIdIfLoneLeg(List<TransitFacade> legs);

  /// Validates all legs of a journey against per-leg rules and cross-leg sequence
  /// constraints.
  ///
  /// Returns an empty list when the journey is valid.
  /// - [JourneyValidationError.legHasErrors]: at least one leg fails its own
  ///   [TransitFacade.validate()] check.
  /// - [JourneyValidationError.sequenceViolation]: a leg's departure time is
  ///   before the previous leg's arrival time.
  List<JourneyValidationError> validateJourney(List<TransitFacade> legs);

  /// Calculates total expense for given legs in the target currency.
  /// Returns a Stream that emits the converted total as each leg's expense is converted.
  Stream<double> getTotalExpenseStream({
    required List<TransitFacade> legs,
    required String targetCurrency,
  });

  factory TransitJourneyServiceFacade(
    ModelCollectionFacade<TransitFacade> transits, {
    ApiService<(Money, String), double?>? currencyConverter,
  }) {
    return TransitJourneyService(transits,
        currencyConverter: currencyConverter);
  }
}
