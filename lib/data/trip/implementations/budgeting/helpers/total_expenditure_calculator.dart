import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Calculates total expenditure from all expense sources
class TotalExpenditureCalculator {
  final ApiService<(Money, String), double?> currencyConverter;

  const TotalExpenditureCalculator(this.currencyConverter);

  /// Calculates total expenditure for a user
  Future<double> calculate({
    required ModelCollectionFacade<TransitFacade> transits,
    required ModelCollectionFacade<LodgingFacade> lodgings,
    required ModelCollectionFacade<StandaloneExpense> expenses,
    required ItineraryFacadeCollectionEventHandler itineraries,
    required String defaultCurrency,
    required String currentUserName,
    Iterable<TransitFacade> transitsToExclude = const [],
    Iterable<LodgingFacade> lodgingsToExclude = const [],
  }) async {
    final expensesToConsider = <ExpenseFacade>[];

    // Collect transit expenses
    expensesToConsider.addAll(_collectExpenses<TransitFacade>(
      transits.collectionItems,
      currentUserName,
      transitsToExclude,
    ));

    // Collect lodging expenses
    expensesToConsider.addAll(_collectExpenses<LodgingFacade>(
      lodgings.collectionItems,
      currentUserName,
      lodgingsToExclude,
    ));

    // Collect standalone expenses
    expensesToConsider.addAll(_collectExpenses<StandaloneExpense>(
      expenses.collectionItems,
      currentUserName,
      [],
    ));

    // Collect sight expenses from itineraries
    expensesToConsider.addAll(_collectExpenses<SightFacade>(
      itineraries.expand((itinerary) => itinerary.planData.sights),
      currentUserName,
      [],
    ));

    return _sumExpenses(expensesToConsider, defaultCurrency);
  }

  Iterable<ExpenseFacade> _collectExpenses<T extends TripEntity>(
    Iterable<ExpenseBearingTripEntity<T>> expenseBearingTripEntities,
    String currentUserName,
    Iterable<ExpenseBearingTripEntity<T>> expenseBearingTripEntitiesToExclude,
  ) sync* {
    for (final expenseBearingTripEntity in expenseBearingTripEntities) {
      if (!expenseBearingTripEntitiesToExclude
          .any((e) => e.id == expenseBearingTripEntity.id)) {
        if (expenseBearingTripEntity.expense.splitBy
            .contains(currentUserName)) {
          yield expenseBearingTripEntity.expense;
        }
      }
    }
  }

  Future<double> _sumExpenses(
    List<ExpenseFacade> expenses,
    String defaultCurrency,
  ) async {
    var total = 0.0;

    for (final expense in expenses) {
      final convertedExpense = await currencyConverter
          .queryData((expense.totalExpense, defaultCurrency));
      if (convertedExpense != null) {
        total += convertedExpense;
      }
    }

    return total;
  }
}
