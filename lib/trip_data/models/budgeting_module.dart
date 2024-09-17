import 'package:wandrr/api_services/models/currency_converter.dart';
import 'package:wandrr/app_data/models/model_collection_facade.dart';
import 'package:wandrr/app_data/models/repository_pattern.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/trip_data/implementations/budgeting_module.dart';

import 'debt_data.dart';
import 'expense.dart';
import 'expense_sort_options.dart';
import 'lodging.dart';
import 'transit.dart';
import 'trip_metadata.dart';

abstract class BudgetingModuleFacade {
  Future<List<DebtData>> retrieveDebtDataList();

  Future<Map<ExpenseCategory, double>> retrieveTotalExpensePerCategory();

  Future<Map<DateTime?, double>> retrieveTotalExpensePerDay();

  Future<void> sortExpenseElements(
      List<UiElement<ExpenseFacade>> expenseUiElements,
      ExpenseSortOption expenseSortOption);

  Future<void> tryBalanceExpensesOnContributorsChanged(
      List<String> contributors);
}

abstract class BudgetingModuleEventHandler extends BudgetingModuleFacade
    implements Dispose {
  Future recalculateTotalExpenditure(
      TripMetadataFacade newTripMetadata,
      Iterable<TransitFacade> deletedTransits,
      Iterable<LodgingFacade> deletedLodgings);

  static BudgetingModuleEventHandler createInstance(
      ModelCollectionFacade<TransitFacade> transitModelCollection,
      ModelCollectionFacade<LodgingFacade> lodgingModelCollection,
      ModelCollectionFacade<ExpenseFacade> expenseModelCollection,
      CurrencyConverterService currencyConverter,
      RepositoryPattern<TripMetadataFacade> tripMetadata) {
    return BudgetingModule(transitModelCollection, lodgingModelCollection,
        expenseModelCollection, currencyConverter, tripMetadata);
  }
}
