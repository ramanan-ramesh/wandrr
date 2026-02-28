import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/services/transit_journey_service.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_journey.dart';

/// Service for managing multi-leg journeys.
/// Handles grouping, validation, querying operations, and expense calculations.
abstract class TransitJourneyServiceFacade {
  /// Get all grouped journeys
  List<TransitJourneyFacade> get journeys;

  /// Get a specific journey by ID
  TransitJourneyFacade? getJourney(String journeyId);

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
