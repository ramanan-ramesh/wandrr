import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/expense.dart';
import 'package:wandrr/data/trip/models/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/editable_trip_entity/expense.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/readonly_trip_entity/expense.dart';

import 'trip_entity_list_view.dart';

class ExpenseListViewNew extends StatefulWidget {
  ExpenseListViewNew({super.key});

  @override
  State<ExpenseListViewNew> createState() => _ExpenseListViewNewState();
}

class _ExpenseListViewNewState extends State<ExpenseListViewNew> {
  var _selectedSortOption = ExpenseSortOption.OldToNew;
  static late Map<ExpenseCategory, String> _categoryNames;
  static late Map<ExpenseSortOption, String> _availableSortOptions;

  @override
  Widget build(BuildContext context) {
    _initializeUIComponentNames(context);
    return TripEntityListView<ExpenseFacade>.customHeaderTileButton(
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
        var budgetingModuleFacade = context.activeTrip.budgetingModuleFacade;
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
    if (expenseUiElement.dataState == DataState.NewUiEntry) {
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
        if (operationPerformed == DataState.Select) {
          if (updatedId == expenseUiElement.metadata.id) {
            if (expenseUiElement.dataState == DataState.None) {
              expenseUiElement.dataState = DataState.Select;
              return true;
            } else if (expenseUiElement.dataState == DataState.Select) {
              expenseUiElement.dataState = DataState.None;
              return true;
            }
          } else {
            if (expenseUiElement.dataState == DataState.Select) {
              expenseUiElement.dataState = DataState.None;
              return true;
            }
          }
        }
      } else {
        if (currentState.dataState == DataState.Select) {
          expenseUiElement.dataState = DataState.None;
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
        (currentState as UpdatedTripEntity).dataState == DataState.Update) {
      if (expenseUiElement is UiElementWithMetadata<ExpenseFacade, T>) {
        var updatedTripEntity =
            currentState.tripEntityModificationData.modifiedCollectionItem;
        var updatedId = updatedTripEntity.id;
        if (expenseUiElement.metadata.id == updatedId) {
          expenseUiElement.metadata = updatedTripEntity;
          expenseUiElement.element = updatedTripEntity.expense;
          expenseUiElement.dataState = DataState.None;
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

  bool _additionalBuildWhenCondition(previousState, currentState) {
    if (currentState.isTripEntityUpdated<TransitFacade>()) {
      var transitUpdatedState = currentState as UpdatedTripEntity;
      if (transitUpdatedState.dataState == DataState.Create ||
          transitUpdatedState.dataState == DataState.Delete) {
        return true;
      }
    } else if (currentState.isTripEntityUpdated<LodgingFacade>()) {
      var lodgingUpdatedState = currentState as UpdatedTripEntity;
      if (lodgingUpdatedState.dataState == DataState.Create ||
          lodgingUpdatedState.dataState == DataState.Delete) {
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
        UiElement<ExpenseFacade>(element: element, dataState: DataState.None)));
    expenseUiElements.addAll(tripDataModelFacade.transits.map((element) =>
        UiElementWithMetadata<ExpenseFacade, TransitFacade>(
            element: element.expense,
            dataState: DataState.None,
            metadata: element)));
    expenseUiElements.addAll(tripDataModelFacade.lodgings.map((element) =>
        UiElementWithMetadata<ExpenseFacade, LodgingFacade>(
            element: element.expense,
            dataState: DataState.None,
            metadata: element)));
    return expenseUiElements;
  }

  void _initializeUIComponentNames(BuildContext context) {
    _categoryNames = {
      ExpenseCategory.Flights: context.localizations.flights,
      ExpenseCategory.Lodging: context.localizations.lodging,
      ExpenseCategory.CarRental: context.localizations.carRental,
      ExpenseCategory.PublicTransit: context.localizations.publicTransit,
      ExpenseCategory.Food: context.localizations.food,
      ExpenseCategory.Drinks: context.localizations.drinks,
      ExpenseCategory.Sightseeing: context.localizations.sightseeing,
      ExpenseCategory.Activities: context.localizations.activities,
      ExpenseCategory.Shopping: context.localizations.shopping,
      ExpenseCategory.Fuel: context.localizations.fuel,
      ExpenseCategory.Groceries: context.localizations.groceries,
      ExpenseCategory.Other: context.localizations.other
    };
    _availableSortOptions = {
      ExpenseSortOption.OldToNew: context.localizations.oldToNew,
      ExpenseSortOption.NewToOld: context.localizations.newToOld,
      ExpenseSortOption.LowToHighCost: context.localizations.lowToHighCost,
      ExpenseSortOption.HighToLowCost: context.localizations.highToLowCost,
      ExpenseSortOption.Category: context.localizations.category
    };
  }
}

const Map<ExpenseCategory, IconData> iconsForCategories = {
  ExpenseCategory.Flights: Icons.flight_rounded,
  ExpenseCategory.Lodging: Icons.hotel_rounded,
  ExpenseCategory.CarRental: Icons.car_rental_outlined,
  ExpenseCategory.PublicTransit: Icons.emoji_transportation_rounded,
  ExpenseCategory.Food: Icons.fastfood_rounded,
  ExpenseCategory.Drinks: Icons.local_drink_rounded,
  ExpenseCategory.Sightseeing: Icons.attractions_rounded,
  ExpenseCategory.Activities: Icons.confirmation_num_rounded,
  ExpenseCategory.Shopping: Icons.shopping_bag_rounded,
  ExpenseCategory.Fuel: Icons.local_gas_station_rounded,
  ExpenseCategory.Groceries: Icons.local_grocery_store_rounded,
  ExpenseCategory.Other: Icons.feed_rounded
};

class _CategoriesPicker extends StatefulWidget {
  final Function(ExpenseCategory expenseCategory)? callback;
  final Map<ExpenseCategory, String> categories;
  ExpenseCategory category;

  _CategoriesPicker(
      {Key? key,
      required this.callback,
      required this.category,
      required this.categories})
      : super(key: key);

  @override
  State<_CategoriesPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoriesPicker> {
  OverlayEntry? _overlayEntry;
  GlobalKey globalKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();

  Widget _createCategory(ExpenseCategory expenseCategory) {
    return InkWell(
      splashColor: Colors.white,
      onTap: () {
        setState(() {
          widget.category = expenseCategory;
          if (widget.callback != null) {
            widget.callback!(expenseCategory);
          }
          _showCategoryPickerWindow();
        });
      },
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Icon(
                iconsForCategories[expenseCategory],
                color: Colors.black,
              ),
            ),
            Text(
              widget.categories[expenseCategory]!,
              style: TextStyle(color: Colors.black),
            )
          ],
        ),
      ),
    );
  }

  OverlayEntry _createOverlay() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        bottom: offset.dy,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 5.0,
            child: Container(
              width: 200,
              color: Colors.white24,
              child: GridView.extent(
                shrinkWrap: true,
                maxCrossAxisExtent: 75,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                children: widget.categories.keys
                    .map((e) => _createCategory(e))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryPickerWindow() {
    if (_overlayEntry == null) {
      OverlayState? overlayState = Overlay.of(context);
      _overlayEntry = _createOverlay();
      overlayState.insert(_overlayEntry!);
    } else {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    //TODO: Track focus and then decide whether to overlay the date range picker
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextButton.icon(
        onPressed: _showCategoryPickerWindow,
        label: Text(context.localizations.category),
        icon: Icon(iconsForCategories[widget.category]!),
      ),
    );
  }
}
