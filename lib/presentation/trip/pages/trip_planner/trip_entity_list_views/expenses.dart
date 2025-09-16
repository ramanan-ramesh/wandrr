import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/ui_element.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/constants.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/editable_list_items/expense.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/readonly_list_items/expense.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'trip_entity_list_view.dart';

class ExpenseListViewNew extends StatefulWidget {
  const ExpenseListViewNew({super.key});

  @override
  State<ExpenseListViewNew> createState() => _ExpenseListViewNewState();
}

class _ExpenseListViewNewState extends State<ExpenseListViewNew> {
  var _selectedSortOption = ExpenseSortOption.oldToNew;
  static late Map<ExpenseCategory, String> _categoryNames;
  static late Map<ExpenseSortOption, String> _availableSortOptions;

  @override
  Widget build(BuildContext context) {
    _initializeUIComponentNames(context);
    return TripEntityListView<ExpenseFacade>.customHeaderTileButton(
      section: NavigationSections.budgeting,
      additionalListBuildWhenCondition: _additionalBuildWhenCondition,
      emptyListMessage: context.localizations.noExpensesCreated,
      headerTileLabel: context.localizations.expenses,
      uiElementsCreator: expenseUiElementsCreator,
      headerTileButton: _createSortOptionsDropDown(),
      onUiElementPressed: _onExpenseUiElementPressed,
      additionalListItemBuildWhenCondition: _shouldBuildExpenseListItem,
      onUpdatePressed: _onUpdatePressed,
      canDelete: (uiElement) {
        return uiElement is! UiElementWithMetadata;
      },
      openedListElementCreator: (UiElement<ExpenseFacade> uiElement,
              ValueNotifier<bool> validityNotifier) =>
          EditableExpenseListItem(
        expenseUiElement: uiElement,
        categoryNames: _categoryNames,
        validityNotifier: validityNotifier,
      ),
      closedListElementCreator: (UiElement<ExpenseFacade> uiElement) {
        if (uiElement is UiElementWithMetadata) {
          uiElement.element.title =
              (uiElement as UiElementWithMetadata).metadata.toString();
        }
        return ReadonlyExpenseListItem(
            expenseModelFacade: uiElement.element,
            categoryNames: _categoryNames);
      },
      uiElementsSorter: (List<UiElement<ExpenseFacade>> uiElements) {
        var budgetingModuleFacade = context.activeTrip.budgetingModule;
        return budgetingModuleFacade.sortExpenseElements(
            uiElements, _selectedSortOption);
      },
      errorMessageCreator: (expenseUiElement) {
        var expense = expenseUiElement.element;
        if (expense.title.length <= 3) {
          return context.localizations.expenseTitleMustBeAtleast3Characters;
        }
        return null;
      },
    );
  }

  void _onUpdatePressed(UiElement<ExpenseFacade> expenseUiElement) {
    TripManagementEvent eventToAdd;
    if (expenseUiElement.dataState == DataState.newUiEntry) {
      eventToAdd = UpdateTripEntity<ExpenseFacade>.create(
          tripEntity: expenseUiElement.element);
    } else {
      if (expenseUiElement
          is UiElementWithMetadata<ExpenseFacade, TransitFacade>) {
        var linkedExpenseUiElement = expenseUiElement as UiElementWithMetadata;
        eventToAdd = UpdateLinkedExpense<TransitFacade>.update(
            link: linkedExpenseUiElement.metadata,
            expense: linkedExpenseUiElement.element);
      } else if (expenseUiElement
          is UiElementWithMetadata<ExpenseFacade, LodgingFacade>) {
        var linkedExpenseUiElement = expenseUiElement as UiElementWithMetadata;
        eventToAdd = UpdateLinkedExpense<LodgingFacade>.update(
            link: linkedExpenseUiElement.metadata,
            expense: linkedExpenseUiElement.element);
      } else {
        eventToAdd = UpdateTripEntity<ExpenseFacade>.update(
            tripEntity: expenseUiElement.element);
      }
    }
    context.addTripManagementEvent(eventToAdd);
  }

  bool _isLinkedExpenseChanged<T extends TripEntity>(
      TripManagementState currentState,
      UiElement<ExpenseFacade> expenseUiElement) {
    if (currentState is UpdatedLinkedExpense<T>) {
      var operationPerformed = currentState.dataState;
      if (expenseUiElement is UiElementWithMetadata<ExpenseFacade, T>) {
        var updatedId = currentState.link.id;
        if (operationPerformed == DataState.select) {
          if (updatedId == expenseUiElement.metadata.id) {
            if (expenseUiElement.dataState == DataState.none) {
              expenseUiElement.dataState = DataState.select;
              return true;
            } else if (expenseUiElement.dataState == DataState.select) {
              expenseUiElement.dataState = DataState.none;
              return true;
            }
          } else {
            if (expenseUiElement.dataState == DataState.select) {
              expenseUiElement.dataState = DataState.none;
              return true;
            }
          }
        }
      } else {
        if (currentState.dataState == DataState.select) {
          expenseUiElement.dataState = DataState.none;
          return true;
        }
      }
    }
    return false;
  }

  bool _isLinkedTripEntityChanged<T extends TripEntity>(
      TripManagementState currentState,
      UiElement<ExpenseFacade> expenseUiElement) {
    if (currentState.isTripEntityUpdated<T>() &&
        (currentState as UpdatedTripEntity).dataState == DataState.update) {
      if (expenseUiElement is UiElementWithMetadata<ExpenseFacade, T>) {
        var updatedTripEntity =
            currentState.tripEntityModificationData.modifiedCollectionItem;
        var updatedId = updatedTripEntity.id;
        if (expenseUiElement.metadata.id == updatedId) {
          expenseUiElement.metadata = updatedTripEntity;
          expenseUiElement.element = updatedTripEntity.expense;
          expenseUiElement.dataState = DataState.none;
          return true;
        }
      }
    }
    return false;
  }

  bool _shouldBuildExpenseListItem(
      TripManagementState previousState,
      TripManagementState currentState,
      UiElement<ExpenseFacade> expenseUiElement) {
    if (_isLinkedExpenseChanged<TransitFacade>(
        currentState, expenseUiElement)) {
      return true;
    } else if (_isLinkedExpenseChanged<LodgingFacade>(
        currentState, expenseUiElement)) {
      return true;
    } else if (_isLinkedTripEntityChanged<TransitFacade>(
        currentState, expenseUiElement)) {
      return true;
    } else if (_isLinkedTripEntityChanged<LodgingFacade>(
        currentState, expenseUiElement)) {
      return true;
    }
    return false;
  }

  void _onExpenseUiElementPressed(
      BuildContext context, UiElement<ExpenseFacade> expenseUiElement) {
    TripManagementEvent eventToAdd;
    if (expenseUiElement
        is UiElementWithMetadata<ExpenseFacade, TransitFacade>) {
      var expenseUiElementWithMetadata =
          expenseUiElement as UiElementWithMetadata;
      eventToAdd = UpdateLinkedExpense<TransitFacade>.select(
          link: expenseUiElementWithMetadata.metadata,
          expense: expenseUiElement.element);
    } else if (expenseUiElement
        is UiElementWithMetadata<ExpenseFacade, LodgingFacade>) {
      var expenseUiElementWithMetadata =
          expenseUiElement as UiElementWithMetadata;
      eventToAdd = UpdateLinkedExpense<LodgingFacade>.select(
          link: expenseUiElementWithMetadata.metadata,
          expense: expenseUiElement.element);
    } else {
      eventToAdd = UpdateTripEntity<ExpenseFacade>.select(
          tripEntity: expenseUiElement.element);
    }
    context.addTripManagementEvent(eventToAdd);
  }

  bool _additionalBuildWhenCondition(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<TransitFacade>()) {
      var transitUpdatedState = currentState as UpdatedTripEntity;
      if (transitUpdatedState.dataState == DataState.create ||
          transitUpdatedState.dataState == DataState.delete) {
        return true;
      }
    } else if (currentState.isTripEntityUpdated<LodgingFacade>()) {
      var lodgingUpdatedState = currentState as UpdatedTripEntity;
      if (lodgingUpdatedState.dataState == DataState.create ||
          lodgingUpdatedState.dataState == DataState.delete) {
        return true;
      }
    }
    return false;
  }

  Widget _createSortOptionsDropDown() {
    return DropdownButton<ExpenseSortOption>(
      items: _availableSortOptions.keys
          .map((sortOption) => DropdownMenuItem(
                value: sortOption,
                child:
                    Wrap(children: [Text(_availableSortOptions[sortOption]!)]),
              ))
          .toList(),
      value: _selectedSortOption,
      onChanged: (ExpenseSortOption? value) {
        if (value != null && value != _selectedSortOption) {
          _selectedSortOption = value;
          setState(() {});
        }
      },
    );
  }

  List<UiElement<ExpenseFacade>> expenseUiElementsCreator(
      TripDataFacade tripDataModelFacade) {
    var expenseUiElements = <UiElement<ExpenseFacade>>[];
    expenseUiElements.addAll(tripDataModelFacade.expenses.map((element) =>
        UiElement<ExpenseFacade>(element: element, dataState: DataState.none)));
    expenseUiElements.addAll(tripDataModelFacade.transits.map((element) =>
        UiElementWithMetadata<ExpenseFacade, TransitFacade>(
            element: element.expense,
            dataState: DataState.none,
            metadata: element)));
    expenseUiElements.addAll(tripDataModelFacade.lodgings.map((element) =>
        UiElementWithMetadata<ExpenseFacade, LodgingFacade>(
            element: element.expense,
            dataState: DataState.none,
            metadata: element)));
    return expenseUiElements;
  }

  void _initializeUIComponentNames(BuildContext context) {
    _categoryNames = {
      ExpenseCategory.flights: context.localizations.flights,
      ExpenseCategory.lodging: context.localizations.lodging,
      ExpenseCategory.carRental: context.localizations.carRental,
      ExpenseCategory.publicTransit: context.localizations.publicTransit,
      ExpenseCategory.food: context.localizations.food,
      ExpenseCategory.drinks: context.localizations.drinks,
      ExpenseCategory.sightseeing: context.localizations.sightseeing,
      ExpenseCategory.activities: context.localizations.activities,
      ExpenseCategory.shopping: context.localizations.shopping,
      ExpenseCategory.fuel: context.localizations.fuel,
      ExpenseCategory.groceries: context.localizations.groceries,
      ExpenseCategory.other: context.localizations.other
    };
    _availableSortOptions = {
      ExpenseSortOption.oldToNew: context.localizations.oldToNew,
      ExpenseSortOption.newToOld: context.localizations.newToOld,
      ExpenseSortOption.lowToHighCost: context.localizations.lowToHighCost,
      ExpenseSortOption.highToLowCost: context.localizations.highToLowCost,
      ExpenseSortOption.category: context.localizations.category
    };
  }
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
  ExpenseCategory.other: Icons.feed_rounded
};
