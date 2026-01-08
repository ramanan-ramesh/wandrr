import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';

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
    _collectTransitExpenses(
      transits,
      currentUserName,
      transitsToExclude,
      expensesToConsider,
    );

    // Collect lodging expenses
    _collectLodgingExpenses(
      lodgings,
      currentUserName,
      lodgingsToExclude,
      expensesToConsider,
    );

    // Collect standalone expenses
    _collectStandaloneExpenses(
      expenses,
      currentUserName,
      expensesToConsider,
    );

    // Collect sight expenses from itineraries
    _collectSightExpenses(
      itineraries,
      currentUserName,
      expensesToConsider,
    );

    return _sumExpenses(expensesToConsider, defaultCurrency);
  }

  void _collectTransitExpenses(
    ModelCollectionFacade<TransitFacade> transits,
    String currentUserName,
    Iterable<TransitFacade> transitsToExclude,
    List<ExpenseFacade> expensesToConsider,
  ) {
    for (final transit in transits.collectionItems) {
      if (!transitsToExclude.any((e) => e.id == transit.id)) {
        if (transit.expense.splitBy.contains(currentUserName)) {
          expensesToConsider.add(transit.expense);
        }
      }
    }
  }

  void _collectLodgingExpenses(
    ModelCollectionFacade<LodgingFacade> lodgings,
    String currentUserName,
    Iterable<LodgingFacade> lodgingsToExclude,
    List<ExpenseFacade> expensesToConsider,
  ) {
    for (final lodging in lodgings.collectionItems) {
      if (!lodgingsToExclude.any((e) => e.id == lodging.id)) {
        if (lodging.expense.splitBy.contains(currentUserName)) {
          expensesToConsider.add(lodging.expense);
        }
      }
    }
  }

  void _collectStandaloneExpenses(
    ModelCollectionFacade<StandaloneExpense> expenses,
    String currentUserName,
    List<ExpenseFacade> expensesToConsider,
  ) {
    for (final expense in expenses.collectionItems) {
      if (expense.expense.splitBy.contains(currentUserName)) {
        expensesToConsider.add(expense.expense);
      }
    }
  }

  void _collectSightExpenses(
    ItineraryFacadeCollectionEventHandler itineraries,
    String currentUserName,
    List<ExpenseFacade> expensesToConsider,
  ) {
    for (final itinerary in itineraries) {
      for (final sight in itinerary.planData.sights) {
        if (sight.expense.splitBy.contains(currentUserName)) {
          expensesToConsider.add(sight.expense);
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
