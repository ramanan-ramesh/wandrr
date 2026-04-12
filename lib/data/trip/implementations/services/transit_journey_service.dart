import 'dart:async';

import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/services/transit_journey_service.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_journey.dart';

class TransitJourneyService implements TransitJourneyServiceFacade {
  final ModelCollectionFacade<TransitFacade> _legCollection;
  final ApiService<(Money, String), double?>? _currencyConverter;

  TransitJourneyService(
    this._legCollection, {
    ApiService<(Money, String), double?>? currencyConverter,
  }) : _currencyConverter = currencyConverter;

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

  List<TransitFacade> _getLegsForJourney(String journeyId) =>
      _legCollection.collectionItems
          .where((leg) => leg.journeyId == journeyId)
          .toList();

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
}
