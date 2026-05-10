import 'dart:async';

import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/services/transit_journey_service.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_journey.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';

class TransitJourneyService implements TransitJourneyServiceFacade {
  final ModelCollectionFacade<TransitFacade> _legCollection;
  final ApiService<(Money, String), double?>? _currencyConverter;

  TransitJourneyService(
    this._legCollection, {
    ApiService<(Money, String), double?>? currencyConverter,
  }) : _currencyConverter = currencyConverter;

  @override
  TransitJourneyFacade? getJourney(String journeyId) {
    final legs = _getLegsForJourney(journeyId);
    if (legs.isEmpty) {
      return null;
    }
    return TransitJourneyFacade(
      journeyId: journeyId,
      tripId: legs.first.tripId,
      unsortedLegs: legs,
    );
  }

  @override
  Iterable<TransitFacade> getJourneyLegs(
      String? journeyId, TransitFacade fallback) {
    if (journeyId == null) {
      return [fallback];
    }
    final legs = _getLegsForJourney(journeyId);
    return legs.isEmpty ? [fallback] : legs;
  }

  @override
  bool cleanupJourneyIdIfLoneLeg(List<TransitFacade> legs) {
    if (legs.length == 1) {
      legs.first.journeyId = null;
      return true;
    }
    return false;
  }

  @override
  List<JourneyValidationError> validateJourney(List<TransitFacade> legs) {
    final errors = <JourneyValidationError>{};

    // Per-leg individual validation.
    if (legs.any((leg) => leg.getValidationErrors().isNotEmpty)) {
      errors.add(JourneyValidationError.legHasErrors);
    }

    // Cross-leg sequence: sort by departure time, then check each consecutive pair.
    if (legs.length > 1) {
      final sorted = List<TransitFacade>.from(legs)
        ..sort((a, b) => (a.departureDateTime ?? DateTime(0))
            .compareTo(b.departureDateTime ?? DateTime(0)));

      for (var i = 1; i < sorted.length; i++) {
        final prevArrival = sorted[i - 1].arrivalDateTime;
        final currDeparture = sorted[i].departureDateTime;
        if (prevArrival != null &&
            currDeparture != null &&
            currDeparture.isBefore(prevArrival)) {
          errors.add(JourneyValidationError.sequenceViolation);
          break;
        }
      }
    }

    return errors.toList();
  }

  @override
  Stream<double> getTotalExpenseStream({
    required List<TransitFacade> legs,
    required String targetCurrency,
  }) async* {
    if (legs.isEmpty) {
      yield 0.0;
      return;
    }

    var runningTotal = 0.0;

    for (final leg in legs) {
      final expense = leg.expense;
      final amount = expense.totalExpense.amount;

      if (amount == 0) {
        continue;
      }

      if (expense.currency == targetCurrency) {
        runningTotal += amount;
        yield runningTotal;
      } else if (_currencyConverter != null) {
        final converted = await _currencyConverter!.queryData(
          (Money(amount: amount, currency: expense.currency), targetCurrency),
        );
        if (converted != null) {
          runningTotal += converted;
          yield runningTotal;
        }
      }
    }
  }

  List<TransitFacade> _getLegsForJourney(String journeyId) =>
      _legCollection.items.where((leg) => leg.journeyId == journeyId).toList();
}
