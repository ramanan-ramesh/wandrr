import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/ui_element.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/readonly_expense.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/trip_entity_list_element.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'editable_expense.dart';

class ExpenseListViewNew extends StatefulWidget {
  const ExpenseListViewNew({super.key});

  @override
  State<ExpenseListViewNew> createState() => _ExpenseListViewNewState();
}

class _ExpenseListViewNewState extends State<ExpenseListViewNew> {
  var _selectedSortOption = ExpenseSortOption.oldToNew;
  static late Map<ExpenseCategory, String> _categoryNames;
  static late Map<ExpenseSortOption, String> _availableSortOptions;
  var _uiElements = <UiElement<ExpenseFacade>>[];
  final _listVisibilityNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _listVisibilityNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initializeUIComponentNames(context);
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildList,
      builder: (BuildContext context, TripManagementState state) {
        _updateListElementsOnBuild(context, state);
        return SliverMainAxisGroup(
          slivers: [
            SliverAppBar(
              flexibleSpace: _createHeaderTile(context),
              pinned: true,
            ),
            ValueListenableBuilder(
              valueListenable: _listVisibilityNotifier,
              builder: (context, value, child) {
                return _createListViewingArea(context);
              },
            ),
          ],
        );
      },
      listener: (BuildContext context, TripManagementState state) {
        if (state.isTripEntityUpdated<ExpenseFacade>() &&
            (state as UpdatedTripEntity).dataState == DataState.newUiEntry) {
          _listVisibilityNotifier.value = true;
        }
      },
    );
  }

  Widget _createHeaderTile(BuildContext context) {
    return Material(
      child: ListTile(
        //TODO: Fix this for tamil, the trailing widget consumes entire space in case of expenses
        leading: ValueListenableBuilder(
            valueListenable: _listVisibilityNotifier,
            builder: (context, value, child) {
              return Icon(
                value ? Icons.list_rounded : Icons.menu_open_rounded,
              );
            }),
        title: Text(
          context.localizations.expenses,
        ),
        onTap: () => _toggleListVisibility,
        selected: true,
        trailing: Container(
          constraints: const BoxConstraints(
            maxWidth: 200,
          ),
          child: FittedBox(
            child: _createSortOptionsDropDown(),
          ),
        ),
      ),
    );
  }

  void _toggleListVisibility() {
    _listVisibilityNotifier.value = !_listVisibilityNotifier.value;
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

  Widget _createListViewingArea(BuildContext context) {
    if (_listVisibilityNotifier.value) {
      if (_uiElements.isEmpty) {
        return SliverToBoxAdapter(child: _createEmptyMessagePane(context));
      } else {
        return FutureBuilder<Iterable<UiElement<ExpenseFacade>>>(
          future:
              _uiElementsSorterWrapper(_createUiElementsSorter, _uiElements),
          builder: (BuildContext context,
              AsyncSnapshot<Iterable<UiElement<ExpenseFacade>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              _uiElements = snapshot.data!.toList();
              return _createSliverList();
            }
            return SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()));
          },
        );
      }
    } else {
      return SliverToBoxAdapter(child: const SizedBox.shrink());
    }
  }

  FutureOr<Iterable<UiElement<ExpenseFacade>>> _createUiElementsSorter(
      List<UiElement<ExpenseFacade>> uiElements) {
    var budgetingModuleFacade = context.activeTrip.budgetingModule;
    return budgetingModuleFacade.sortExpenseElements(
        uiElements, _selectedSortOption);
  }

  Future<Iterable<UiElement<ExpenseFacade>>> _uiElementsSorterWrapper(
      FutureOr<Iterable<UiElement<ExpenseFacade>>> Function(
              List<UiElement<ExpenseFacade>>)
          func,
      List<UiElement<ExpenseFacade>> uiElements) async {
    return Future.value(func(uiElements));
  }

  Widget _createSliverList() {
    return SliverList.builder(
      itemCount: _uiElements.length,
      itemBuilder: (BuildContext context, int index) {
        var uiElement = _uiElements.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 4.0),
          child: Material(
            color: context.isLightTheme
                ? Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.96)
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.98),
            elevation: 5,
            borderRadius: BorderRadius.circular(23),
            shadowColor: AppColors.neutral900.withValues(alpha: 0.10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  width: 2.2,
                ),
              ),
              child: TripEntityListElement<ExpenseFacade>(
                uiElement: uiElement,
                onPressed: _onExpenseUiElementPressed,
                canDelete: (uiElement) {
                  return uiElement is! UiElementWithMetadata;
                },
                additionalListItemBuildWhenCondition:
                    _shouldBuildExpenseListItem,
                onUpdatePressed: _onUpdatePressed,
                openedListElementCreator: (UiElement<ExpenseFacade> uiElement,
                        ValueNotifier<bool> validityNotifier) =>
                    EditableExpenseListItem(
                  expenseUiElement: uiElement,
                  categoryNames: _categoryNames,
                  validityNotifier: validityNotifier,
                ),
                closedElementCreator: (UiElement<ExpenseFacade> uiElement) {
                  if (uiElement is UiElementWithMetadata) {
                    uiElement.element.title =
                        (uiElement as UiElementWithMetadata)
                            .metadata
                            .toString();
                  }
                  return ReadonlyExpenseListItem(
                      expenseModelFacade: uiElement.element,
                      categoryNames: _categoryNames);
                },
                errorMessageCreator: (expenseUiElement) {
                  var expense = expenseUiElement.element;
                  if (expense.title.length <= 3) {
                    return context
                        .localizations.expenseTitleMustBeAtleast3Characters;
                  }
                  return null;
                },
              ),
            ),
          ),
        );
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

  Widget _createEmptyMessagePane(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.transparent,
      child: Center(
        child: PlatformTextElements.createSubHeader(
            context: context,
            text: context.localizations.noExpensesCreated,
            textAlign: TextAlign.center),
      ),
    );
  }

  bool _shouldBuildList(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<ExpenseFacade>()) {
      var updatedTripEntityState = currentState as UpdatedTripEntity;
      if (updatedTripEntityState.dataState == DataState.delete ||
          updatedTripEntityState.dataState == DataState.create ||
          updatedTripEntityState.dataState == DataState.newUiEntry) {
        return true;
      }
    } else if (currentState.isTripEntityUpdated<TransitFacade>()) {
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

  void _updateListElementsOnBuild(
      BuildContext context, TripManagementState state) {
    var activeTrip = context.activeTrip;

    _uiElements.removeWhere((x) => x.dataState != DataState.newUiEntry);

    if (state.isTripEntityUpdated<ExpenseFacade>()) {
      var updatedTripEntityState = state as UpdatedTripEntity;
      var updatedTripEntityDataState = updatedTripEntityState.dataState;
      if (updatedTripEntityState
          .tripEntityModificationData.isFromExplicitAction) {
        switch (updatedTripEntityDataState) {
          case DataState.create:
            {
              _uiElements.removeWhere(
                  (element) => element.dataState == DataState.newUiEntry);
              break;
            }
          case DataState.delete:
            {
              if (updatedTripEntityState
                      .tripEntityModificationData.modifiedCollectionItem.id ==
                  null) {
                _uiElements.removeWhere(
                    (element) => element.dataState == DataState.newUiEntry);
              }
              break;
            }
          case DataState.newUiEntry:
            {
              if (!_uiElements.any(
                  (element) => element.dataState == DataState.newUiEntry)) {
                _uiElements.add(UiElement(
                    element: updatedTripEntityState
                        .tripEntityModificationData.modifiedCollectionItem,
                    dataState: DataState.newUiEntry));
              }
              break;
            }
          default:
            {
              break;
            }
        }
      }
    }
    _uiElements.addAll(expenseUiElementsCreator(activeTrip));
  }

  List<UiElement<ExpenseFacade>> expenseUiElementsCreator(
      TripDataFacade tripDataModelFacade) {
    var expenseUiElements = <UiElement<ExpenseFacade>>[];
    expenseUiElements.addAll(tripDataModelFacade
        .expenseCollection.collectionItems
        .map((element) => UiElement<ExpenseFacade>(
            element: element, dataState: DataState.none)));
    expenseUiElements.addAll(tripDataModelFacade
        .transitCollection.collectionItems
        .map((element) => UiElementWithMetadata<ExpenseFacade, TransitFacade>(
            element: element.expense,
            dataState: DataState.none,
            metadata: element)));
    expenseUiElements.addAll(tripDataModelFacade
        .lodgingCollection.collectionItems
        .map((element) => UiElementWithMetadata<ExpenseFacade, LodgingFacade>(
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
