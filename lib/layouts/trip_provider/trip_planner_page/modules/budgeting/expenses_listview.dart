import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/blocs/trip_management/states.dart';
import 'package:wandrr/contracts/budgeting_module.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/data_states.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/lodging.dart';
import 'package:wandrr/contracts/transit.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_repository.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/trip_entity_list_elements.dart';
import 'package:wandrr/platform_elements/button.dart';

import 'expense_list_item_components/closed_expense.dart';
import 'expense_list_item_components/opened_expense.dart';

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
    return TripEntityListView<ExpenseModelFacade>.customHeaderTileButton(
      additionalListBuildWhenCondition: _additionalBuildWhenCondition,
      emptyListMessage: AppLocalizations.of(context)!.noExpensesCreated,
      headerTileLabel: AppLocalizations.of(context)!.expenses,
      uiElementsCreator: expenseUiElementsCreator,
      headerTileButton: _createSortOptionsDropDown(),
      onUiElementPressed: _onExpenseUiElementPressed,
      additionalListItemBuildWhenCondition: _shouldBuildExpenseListItem,
      onUpdatePressed: _onUpdatePressed,
      canDelete: (uiElement) {
        return uiElement is! UiElementWithMetadata;
      },
      openedListElementCreator: (UiElement<ExpenseModelFacade> uiElement,
              ValueNotifier<bool> validityNotifier) =>
          OpenedExpenseListItem(
        expenseUiElement: uiElement,
        categoryNames: _categoryNames,
        validityNotifier: validityNotifier,
      ),
      closedListElementCreator: (UiElement<ExpenseModelFacade> uiElement) {
        if (uiElement is UiElementWithMetadata) {
          uiElement.element.title =
              (uiElement as UiElementWithMetadata).metadata.toString();
        }
        return ClosedExpenseListItem(
            expenseModelFacade: uiElement.element,
            categoryNames: _categoryNames);
      },
      uiElementsSorter: (List<UiElement<ExpenseModelFacade>> uiElements) {
        var budgetingModuleFacade =
            RepositoryProvider.of<TripRepositoryModelFacade>(context)
                .activeTrip!
                .budgetingModuleFacade;
        return budgetingModuleFacade.sortExpenseElements(
            uiElements, _selectedSortOption);
      },
    );
  }

  void _onUpdatePressed(UiElement<ExpenseModelFacade> expenseUiElement) {
    var tripManagementBloc = BlocProvider.of<TripManagementBloc>(context);
    if (expenseUiElement.dataState == DataState.NewUiEntry) {
      tripManagementBloc.add(UpdateTripEntity<ExpenseModelFacade>.create(
          tripEntity: expenseUiElement.element));
    } else {
      if (expenseUiElement
          is UiElementWithMetadata<ExpenseModelFacade, TransitModelFacade>) {
        var linkedExpenseUiElement = expenseUiElement as UiElementWithMetadata;
        tripManagementBloc.add(UpdateLinkedExpense<TransitModelFacade>.update(
            link: linkedExpenseUiElement.metadata,
            expense: linkedExpenseUiElement.element));
      } else if (expenseUiElement
          is UiElementWithMetadata<ExpenseModelFacade, LodgingModelFacade>) {
        var linkedExpenseUiElement = expenseUiElement as UiElementWithMetadata;
        tripManagementBloc.add(UpdateLinkedExpense<TransitModelFacade>.update(
            link: linkedExpenseUiElement.metadata,
            expense: linkedExpenseUiElement.element));
      } else {
        tripManagementBloc.add(UpdateTripEntity<ExpenseModelFacade>.update(
            tripEntity: expenseUiElement.element));
      }
    }
  }

  bool _isLinkedExpenseChanged<T extends TripEntity>(
      TripManagementState currentState,
      UiElement<ExpenseModelFacade> expenseUiElement) {
    if (currentState is UpdatedLinkedExpense<T>) {
      var operationPerformed = currentState.dataState;
      if (expenseUiElement is UiElementWithMetadata<ExpenseModelFacade, T>) {
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
      UiElement<ExpenseModelFacade> expenseUiElement) {
    if (currentState.isTripEntity<T>() &&
        (currentState as UpdatedTripEntity).dataState == DataState.Update) {
      if (expenseUiElement is UiElementWithMetadata<ExpenseModelFacade, T>) {
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
      UiElement<ExpenseModelFacade> expenseUiElement) {
    if (_isLinkedExpenseChanged<TransitModelFacade>(
        currentState, expenseUiElement)) {
      return true;
    } else if (_isLinkedExpenseChanged<LodgingModelFacade>(
        currentState, expenseUiElement)) {
      return true;
    } else if (_isLinkedTripEntityChanged<TransitModelFacade>(
        currentState, expenseUiElement)) {
      return true;
    } else if (_isLinkedTripEntityChanged<LodgingModelFacade>(
        currentState, expenseUiElement)) {
      return true;
    }
    return false;
  }

  void _onExpenseUiElementPressed(
      BuildContext context, UiElement<ExpenseModelFacade> expenseUiElement) {
    var tripManagementBloc = BlocProvider.of<TripManagementBloc>(context);
    if (expenseUiElement
        is UiElementWithMetadata<ExpenseModelFacade, TransitModelFacade>) {
      var expenseUiElementWithMetadata =
          expenseUiElement as UiElementWithMetadata;
      tripManagementBloc.add(UpdateLinkedExpense<TransitModelFacade>.select(
          link: expenseUiElementWithMetadata.metadata,
          expense: expenseUiElement.element));
    } else if (expenseUiElement
        is UiElementWithMetadata<ExpenseModelFacade, LodgingModelFacade>) {
      var expenseUiElementWithMetadata =
          expenseUiElement as UiElementWithMetadata;
      tripManagementBloc.add(UpdateLinkedExpense<LodgingModelFacade>.select(
          link: expenseUiElementWithMetadata.metadata,
          expense: expenseUiElement.element));
    } else {
      tripManagementBloc.add(UpdateTripEntity<ExpenseModelFacade>.select(
          tripEntity: expenseUiElement.element));
    }
  }

  bool _additionalBuildWhenCondition(previousState, currentState) {
    if (currentState.isTripEntity<TransitModelFacade>()) {
      var transitUpdatedState = currentState as UpdatedTripEntity;
      if (transitUpdatedState.dataState == DataState.Create ||
          transitUpdatedState.dataState == DataState.Delete) {
        return true;
      }
    } else if (currentState.isTripEntity<LodgingModelFacade>()) {
      var lodgingUpdatedState = currentState as UpdatedTripEntity;
      if (lodgingUpdatedState.dataState == DataState.Create ||
          lodgingUpdatedState.dataState == DataState.Delete) {
        return true;
      }
    }
    return false;
  }

  DropdownButton<ExpenseSortOption> _createSortOptionsDropDown() {
    return DropdownButton<ExpenseSortOption>(
      items: _availableSortOptions.keys
          .map((sortOption) => DropdownMenuItem(
                value: sortOption,
                child: Text(_availableSortOptions[sortOption]!),
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

  List<UiElement<ExpenseModelFacade>> expenseUiElementsCreator(
      TripDataModelFacade tripDataModelFacade) {
    var expenseUiElements = <UiElement<ExpenseModelFacade>>[];
    expenseUiElements.addAll(tripDataModelFacade.expenses.map((element) =>
        UiElement<ExpenseModelFacade>(
            element: element, dataState: DataState.None)));
    expenseUiElements.addAll(tripDataModelFacade.transits.map((element) =>
        UiElementWithMetadata<ExpenseModelFacade, TransitModelFacade>(
            element: element.expense,
            dataState: DataState.None,
            metadata: element)));
    expenseUiElements.addAll(tripDataModelFacade.lodgings.map((element) =>
        UiElementWithMetadata<ExpenseModelFacade, LodgingModelFacade>(
            element: element.expense,
            dataState: DataState.None,
            metadata: element)));
    return expenseUiElements;
  }

  void _initializeUIComponentNames(BuildContext context) {
    _categoryNames = {
      ExpenseCategory.Flights: AppLocalizations.of(context)!.flights,
      ExpenseCategory.Lodging: AppLocalizations.of(context)!.lodging,
      ExpenseCategory.CarRental: AppLocalizations.of(context)!.carRental,
      ExpenseCategory.PublicTransit:
          AppLocalizations.of(context)!.publicTransit,
      ExpenseCategory.Food: AppLocalizations.of(context)!.food,
      ExpenseCategory.Drinks: AppLocalizations.of(context)!.drinks,
      ExpenseCategory.Sightseeing: AppLocalizations.of(context)!.sightseeing,
      ExpenseCategory.Activities: AppLocalizations.of(context)!.activities,
      ExpenseCategory.Shopping: AppLocalizations.of(context)!.shopping,
      ExpenseCategory.Fuel: AppLocalizations.of(context)!.fuel,
      ExpenseCategory.Groceries: AppLocalizations.of(context)!.groceries,
      ExpenseCategory.Other: AppLocalizations.of(context)!.other
    };
    _availableSortOptions = {
      ExpenseSortOption.OldToNew: AppLocalizations.of(context)!.oldToNew,
      ExpenseSortOption.NewToOld: AppLocalizations.of(context)!.newToOld,
      ExpenseSortOption.LowToHighCost:
          AppLocalizations.of(context)!.lowToHighCost,
      ExpenseSortOption.HighToLowCost:
          AppLocalizations.of(context)!.highToLowCost,
      ExpenseSortOption.Category: AppLocalizations.of(context)!.category
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
      child: PlatformButtonElements.createTextButtonWithIcon(
          text: AppLocalizations.of(context)!.category,
          iconData: iconsForCategories[widget.category]!,
          onPressed: _showCategoryPickerWindow),
    );
  }
}
