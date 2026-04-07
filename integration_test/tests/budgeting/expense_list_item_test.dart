import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/readonly_expense.dart';

import '../../helpers/test_helpers.dart';
import 'helpers.dart';

// Test: Expense list view item displays correct data
Future<void> runExpenseListItemTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  // Navigate to TripEditorPage
  await TestHelpers.navigateToTripEditorPage(tester);

  await tryNavigateToBudgetingPage(tester);

  final allExpensesFromTripRepo =
      await getSortedExpensesFromRepository(tester, ExpenseSortOption.newToOld);

  final budgetingModule =
      TestHelpers.getTripRepository(tester).activeTrip!.budgetingModule;
  await TestHelpers.evaluateWidgetsByScrollingWithPredicate<
      ReadonlyExpenseListItem>(
    tester: tester,
    scrollableFinder: find.descendant(
      of: find.byType(ExpenseListView),
      matching: find.byType(ListView),
    ),
    widgetFinder: find.byType(ReadonlyExpenseListItem),
    getUniqueId: (widget) => widget.expenseBearingTripEntity is SightFacade
        ? '${(widget.expenseBearingTripEntity as SightFacade).day.itineraryDateFormat}_${widget.expenseBearingTripEntity.id}'
        : widget.expenseBearingTripEntity.id!,
    expectedCount: allExpensesFromTripRepo.length,
    predicate: (ReadonlyExpenseListItem widget) async {
      return await _evaluateExpenseListItem(widget, tester, budgetingModule);
    },
  );
}

Future<String?> _evaluateExpenseListItem(
    ReadonlyExpenseListItem expenseListItem,
    WidgetTester tester,
    BudgetingModuleFacade budgetingModule) async {
  final expense = expenseListItem.expenseBearingTripEntity;
  ExpenseCategory expectedCategory = expense.category;
  var expenseListItemFinder = find.byWidget(expenseListItem);
  String expectedTitle = expense.title;
  if (expense is StandaloneExpense) {
    final isDeleteButtonFound = find
            .descendant(
                of: expenseListItemFinder,
                matching: find.byIcon(Icons.delete_outline))
            .evaluate()
            .length ==
        1;
    if (!isDeleteButtonFound) {
      return 'Delete button should be present';
    }
  } else {
    expectedTitle = expense.toString();
    if (expense is TransitFacade) {
      expectedCategory = getExpenseCategoryForTransit(expense.transitOption);
    } else if (expense is LodgingFacade) {
      expectedCategory = ExpenseCategory.lodging;
    } else if (expense is SightFacade) {
      expectedCategory = ExpenseCategory.sightseeing;
    }
  }
  final isTitleFound = find
          .descendant(
              of: expenseListItemFinder, matching: find.text(expectedTitle))
          .evaluate()
          .length ==
      1;
  if (!isTitleFound) {
    return 'Title should be $expectedTitle';
  }
  final isCategoryWidgetFound = find
          .descendant(
              of: expenseListItemFinder,
              matching: find.byIcon(iconsForCategories[expectedCategory]!))
          .evaluate()
          .length ==
      1;
  if (!isCategoryWidgetFound) {
    return 'Category icon should be present for $expectedCategory';
  }
  final totalExpenseAmount =
      expense.expense.paidBy.values.fold(0.0, (p, e) => p + e);
  final formattedAmount = await budgetingModule.formatCurrency(
      Money(amount: totalExpenseAmount, currency: expense.expense.currency));
  final isTotalAmountFound = find
          .descendant(
              of: expenseListItemFinder, matching: find.text(formattedAmount))
          .evaluate()
          .length ==
      1;
  if (!isTotalAmountFound) {
    return 'Total expense amount should be present as $formattedAmount';
  }
  return null;
}

const Map<ExpenseCategory, IconData> iconsForCategories = {
  ExpenseCategory.flights: Icons.flight_rounded,
  ExpenseCategory.lodging: Icons.hotel_rounded,
  ExpenseCategory.carRental: Icons.car_rental_outlined,
  ExpenseCategory.publicTransit: Icons.emoji_transportation_rounded,
  ExpenseCategory.food: Icons.fastfood_rounded,
  ExpenseCategory.drinks: Icons.local_drink_rounded,
  ExpenseCategory.sightseeing: Icons.attractions_rounded,
  ExpenseCategory.activities: Icons.confirmation_num_rounded,
  ExpenseCategory.shopping: Icons.shopping_bag_rounded,
  ExpenseCategory.fuel: Icons.local_gas_station_rounded,
  ExpenseCategory.groceries: Icons.local_grocery_store_rounded,
  ExpenseCategory.other: Icons.feed_rounded,
  ExpenseCategory.taxi: Icons.local_taxi_rounded,
};

ExpenseCategory getExpenseCategoryForTransit(TransitOption transitOptions) {
  switch (transitOptions) {
    case TransitOption.publicTransport:
    case TransitOption.train:
    case TransitOption.cruise:
    case TransitOption.ferry:
    case TransitOption.bus:
      {
        return ExpenseCategory.publicTransit;
      }
    case TransitOption.rentedVehicle:
      {
        return ExpenseCategory.carRental;
      }
    case TransitOption.flight:
      {
        return ExpenseCategory.flights;
      }
    case TransitOption.taxi:
      {
        return ExpenseCategory.taxi;
      }
    default:
      {
        return ExpenseCategory.publicTransit;
      }
  }
}
