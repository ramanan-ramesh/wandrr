import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';
import 'package:wandrr/repositories/trip_management.dart';

import 'expense_list_item_components/closed_expense.dart';
import 'expense_list_item_components/opened_expense.dart';

enum _SortOption { Category, LowToHighCost, HighToLowCost, OldToNew, NewToOld }

class ExpensesListView extends StatefulWidget {
  bool isCollapsed;
  ExpensesListView({super.key, required this.isCollapsed});

  @override
  State<ExpensesListView> createState() => _ExpensesListViewState();
}

class _ExpensesListViewState extends State<ExpensesListView>
    with SingleTickerProviderStateMixin {
  static late Map<_SortOption, String> _availableSortOptions;
  late AutoScrollController _expenseListScrollController;
  static late Map<ExpenseCategory, String> _categoryNames;
  _SortOption _selectedSortOption = _SortOption.OldToNew;
  List _allExpenses = [];

  late var _animationController;

  @override
  void initState() {
    super.initState();
    _expenseListScrollController = AutoScrollController(
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: Axis.vertical);
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));
  }

  @override
  Widget build(BuildContext context) {
    _initializeUIComponentNames(context);
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildExpenseList,
      builder: (BuildContext context, TripManagementState state) {
        print("ExpensesList-builder-${state}");
        _updateExpensesOnBuild(context, state);
        var contributors = RepositoryProvider.of<TripManagement>(context)
            .activeTrip!
            .tripMetaData
            .contributors;
        var currentUserName =
            RepositoryProvider.of<PlatformDataRepository>(context)
                .appLevelData
                .activeUser!
                .userName;
        return SliverList.separated(
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return _buildExpensesListHeader(context);
            } else if (index == 1 && _allExpenses.isEmpty) {
              return _createEmptyMessagePane(context);
            } else if (index > 0) {
              return _ExpenseListItem(
                categoryNames: _categoryNames,
                tapCallBack: () {},
                expenseListItem: _allExpenses.elementAt(index - 1),
                currentUserName: currentUserName,
                contributors: contributors,
              );
            }
          },
          separatorBuilder: (BuildContext context, int index) {
            if (_allExpenses.isNotEmpty) {
              return Divider();
            } else {
              return SizedBox.shrink();
            }
          },
          itemCount: widget.isCollapsed
              ? 1
              : (_allExpenses.isEmpty ? 2 : _allExpenses.length + 1),
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Container _createEmptyMessagePane(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.transparent,
      child: Center(
        child: PlatformTextElements.createSubHeader(
            context: context,
            text: AppLocalizations.of(context)!.noTransitsCreated),
      ),
    );
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
      _SortOption.OldToNew: AppLocalizations.of(context)!.oldToNew,
      _SortOption.NewToOld: AppLocalizations.of(context)!.newToOld,
      _SortOption.LowToHighCost: AppLocalizations.of(context)!.lowToHighCost,
      _SortOption.HighToLowCost: AppLocalizations.of(context)!.highToLowCost,
      _SortOption.Category: AppLocalizations.of(context)!.category
    };
  }

  bool _shouldBuildExpenseList(previousState, currentState) {
    if (currentState is ExpenseUpdated) {
      //TODO: Should handle update done on any property that is affected by SortOption(ex: update done to dateTime field of any expense, must potentially rebuild the list, if selected sort option is DateTime)
      return currentState.operation == DataState.Deleted ||
          currentState.operation == DataState.Created;
    } else if (currentState is TransitUpdated &&
        currentState.isOperationSuccess) {
      if (currentState.operation == DataState.Deleted ||
          currentState.operation == DataState.Created) {
        if (currentState.transitUpdator.dataState !=
            DataState.CreateNewUIEntry) {
          return true;
        }
      }
    } else if (currentState is LodgingUpdated &&
        currentState.isOperationSuccess) {
      if (currentState.operation == DataState.Deleted ||
          currentState.operation == DataState.Created) {
        if (currentState.lodgingUpdator.dataState !=
            DataState.CreateNewUIEntry) {
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildExpensesListHeader(BuildContext context) {
    return Material(
      child: ListTile(
        leading: AnimatedIcon(
            icon: widget.isCollapsed
                ? AnimatedIcons.view_list
                : AnimatedIcons.menu_arrow,
            progress: _animationController),
        title: Text(
          AppLocalizations.of(context)!.expenses,
          style: TextStyle(color: Colors.white),
        ),
        onTap: () {
          setState(() {
            widget.isCollapsed = !widget.isCollapsed;
          });
        },
        trailing: DropdownMenu<_SortOption>(
          initialSelection: _selectedSortOption,
          label: Text(
            '${AppLocalizations.of(context)!.sortBy}: ',
            style: TextStyle(color: Colors.white),
          ),
          dropdownMenuEntries: _availableSortOptions.keys
              .map((sortOption) => DropdownMenuEntry<_SortOption>(
                    value: sortOption,
                    label: _availableSortOptions[sortOption]!,
                  ))
              .toList(),
          onSelected: (selectedSortOption) {
            if (selectedSortOption != null) {
              setState(() {
                _selectedSortOption = selectedSortOption;
              });
            }
          },
        ),
      ),
    );
  }

  void _updateExpensesOnBuild(BuildContext context, TripManagementState state) {
    var activeTrip = RepositoryProvider.of<TripManagement>(context).activeTrip!;

    _allExpenses.removeWhere((element) =>
        _getExpenseUpdator(element).dataState != DataState.CreateNewUIEntry);

    _allExpenses.addAll(activeTrip.expenses
        .map((element) => ExpenseUpdator.fromExpense(expense: element)));
    _allExpenses.addAll(activeTrip.lodgings
        .map((element) => LodgingUpdator.fromLodging(lodging: element)));
    _allExpenses.addAll(activeTrip.transits
        .map((element) => TransitUpdator.fromTransit(transit: element)));

    if (state is ExpenseUpdated && state.operation == DataState.Created) {
      if (state.expenseUpdator.dataState == DataState.CreateNewUIEntry &&
          !_allExpenses.any((element) =>
              _getExpenseUpdator(element).dataState ==
              DataState.CreateNewUIEntry)) {
        _allExpenses.add(state.expenseUpdator);
      } else if (state.expenseUpdator.dataState == DataState.Created) {
        _allExpenses.removeWhere((element) =>
            _getExpenseUpdator(element).dataState ==
                DataState.CreateNewUIEntry ||
            _getExpenseUpdator(element).dataState ==
                DataState.RequestedCreation);
      }
    } else if (state is ExpenseUpdated &&
        state.operation == DataState.Deleted) {
      if (state.expenseUpdator.dataState == DataState.CreateNewUIEntry) {
        _allExpenses.removeWhere((element) =>
            _getExpenseUpdator(element).dataState ==
            DataState.CreateNewUIEntry);
      }
    }
    _sortExpenses();
  }

  ExpenseUpdator _getExpenseUpdator(dynamic expenseListItem) {
    if (expenseListItem is TransitUpdator) {
      return expenseListItem.expenseUpdator!;
    } else if (expenseListItem is LodgingUpdator) {
      return expenseListItem.expenseUpdator!;
    } else {
      return expenseListItem;
    }
  }

  void _sortExpenses() {
    var newUiEntries = _allExpenses
        .where((element) =>
            _getExpenseUpdator(element).dataState == DataState.CreateNewUIEntry)
        .toList();
    _allExpenses.removeWhere((element) =>
        _getExpenseUpdator(element).dataState == DataState.CreateNewUIEntry);
    switch (_selectedSortOption) {
      case _SortOption.OldToNew:
        {
          _sortOnDateTime();
          break;
        }
      case _SortOption.NewToOld:
        {
          _sortOnDateTime(isAscendingOrder: false);
          break;
        }
      case _SortOption.Category:
        {
          _allExpenses.sort((a, b) => _getExpenseUpdator(a)
              .category!
              .name
              .compareTo(_getExpenseUpdator(b).category!.name));
          break;
        }
      case _SortOption.LowToHighCost:
        {
          _sortOnCost();
          break;
        }
      case _SortOption.HighToLowCost:
        {
          _sortOnCost(isAscendingOrder: false);
          break;
        }
    }
    _allExpenses.addAll(newUiEntries);
  }

  void _sortOnDateTime({bool isAscendingOrder = true}) {
    List expensesWithDateTime = [];
    List expensesWithoutDateTime = [];
    for (var expense in _allExpenses) {
      var expenseUpdator = _getExpenseUpdator(expense);
      if (expenseUpdator.dateTime != null) {
        expensesWithDateTime.add(expense);
      } else {
        expensesWithoutDateTime.add(expense);
      }
    }
    var expenseUpdators = List.from(expensesWithDateTime);
    if (isAscendingOrder) {
      expenseUpdators.sort((a, b) => _getExpenseUpdator(a)
          .dateTime!
          .compareTo(_getExpenseUpdator(b).dateTime!));
    } else {
      expenseUpdators.sort((a, b) => _getExpenseUpdator(b)
          .dateTime!
          .compareTo(_getExpenseUpdator(a).dateTime!));
    }
    expenseUpdators.addAll(expensesWithoutDateTime);
    _allExpenses = List.from(expenseUpdators);
  }

  //TODO: This will not work because we can't sort based on cost alone. Need to consider currency as well
  void _sortOnCost({bool isAscendingOrder = true}) {
    if (isAscendingOrder) {
      _allExpenses.sort((a, b) => _getExpenseUpdator(a)
          .totalExpense!
          .amount
          .compareTo(_getExpenseUpdator(b).totalExpense!.amount));
    } else {
      _allExpenses.sort((a, b) => _getExpenseUpdator(b)
          .totalExpense!
          .amount
          .compareTo(_getExpenseUpdator(a).totalExpense!.amount));
    }
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

class _ExpenseListItem extends StatelessWidget {
  dynamic expenseListItem;
  final List<String> contributors;
  final String currentUserName;
  final VoidCallback tapCallBack;
  final Map<ExpenseCategory, String> categoryNames;

  ExpenseUpdator _getExpenseUpdator(dynamic expenseListItem) {
    if (expenseListItem is TransitUpdator) {
      return expenseListItem.expenseUpdator!;
    } else if (expenseListItem is LodgingUpdator) {
      return expenseListItem.expenseUpdator!;
    } else {
      return expenseListItem;
    }
  }

  _ExpenseListItem(
      {super.key,
      required this.categoryNames,
      required this.tapCallBack,
      required this.expenseListItem,
      required this.currentUserName,
      required this.contributors});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildExpenseListItem,
      builder: (context, state) {
        print("ExpenseListItem-builder-${state}");
        ExpenseUpdator expenseUpdator = _getExpenseUpdator(expenseListItem);
        var shouldOpenForEditing =
            expenseUpdator.dataState == DataState.Selected ||
                expenseUpdator.dataState == DataState.CreateNewUIEntry;
        return Material(
          child: AnimatedSize(
            curve: shouldOpenForEditing ? Curves.easeInOut : Curves.easeOut,
            duration: Duration(milliseconds: 700),
            reverseDuration: Duration(milliseconds: 700),
            child: InkWell(
              onTap: shouldOpenForEditing
                  ? null
                  : () {
                      tapCallBack();
                      var tripManagementBloc =
                          BlocProvider.of<TripManagementBloc>(context);
                      tripManagementBloc.add(UpdateExpense.select(
                          expenseUpdator: _getExpenseUpdator(expenseListItem)));
                    },
              child: shouldOpenForEditing
                  ? _createOpenedListItem()
                  : ClosedExpenseListItem(
                      categoryNames: categoryNames,
                      expenseUpdator: _getExpenseUpdator(expenseListItem)),
            ),
          ),
        );
      },
      listener: (context, state) {},
    );
  }

  TripManagementEvent _createTransitUpdateEvent(ExpenseUpdator expenseUpdator) {
    (expenseListItem as TransitUpdator).expenseUpdator = expenseUpdator;
    return UpdateTransit.update(
        transitUpdator: expenseListItem, isLinkedExpense: true);
  }

  TripManagementEvent _createLodgingUpdateEvent(ExpenseUpdator expenseUpdator) {
    (expenseListItem as LodgingUpdator).expenseUpdator = expenseUpdator;
    return UpdateLodging.update(
        lodgingUpdator: expenseListItem, isLinkedExpense: true);
  }

  TripManagementEvent _createExpenseUpdateEvent(ExpenseUpdator expenseUpdator) {
    return UpdateExpense.update(expenseUpdator: expenseUpdator);
  }

  Widget _createOpenedListItem() {
    if (expenseListItem is TransitUpdator) {
      return OpenedExpenseListItem(
        initialExpenseUpdator: expenseListItem.expenseUpdator!,
        categoryNames: categoryNames,
        isLinkedExpense: true,
        updateEventCreator: _createTransitUpdateEvent,
      );
    } else if (expenseListItem is LodgingUpdator) {
      return OpenedExpenseListItem(
          initialExpenseUpdator: expenseListItem.expenseUpdator!,
          categoryNames: categoryNames,
          isLinkedExpense: true,
          updateEventCreator: _createLodgingUpdateEvent);
    }
    return OpenedExpenseListItem(
      initialExpenseUpdator: expenseListItem,
      isLinkedExpense: false,
      categoryNames: categoryNames,
      updateEventCreator: _createExpenseUpdateEvent,
    );
  }

  bool _shouldBuildExpenseListItem(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState is ExpenseUpdated) {
      var operationToPerform = currentState.operation;
      if (operationToPerform == DataState.Selected) {
        var updatedExpenseId = currentState.expenseUpdator.id;
        var expenseUpdator = _getExpenseUpdator(expenseListItem);
        if (updatedExpenseId == expenseUpdator.id) {
          return true;
        } else {
          if (expenseUpdator.dataState == DataState.Selected) {
            expenseUpdator.dataState = DataState.None;
            return true;
          }
        }
      } else if (operationToPerform == DataState.Updated) {
        if (_getExpenseUpdator(expenseListItem).id ==
            currentState.expenseUpdator.id) {
          expenseListItem.operation = DataState.Updated;
          return true;
        }
      }
    } else if (currentState is LodgingUpdated &&
        currentState.lodgingUpdator.dataState == DataState.Updated) {
      var doesIdMatch = expenseListItem is LodgingUpdator &&
          expenseListItem.id == currentState.lodgingUpdator.id;
      if (doesIdMatch) {
        expenseListItem = currentState.lodgingUpdator;
        return true;
      }
      return expenseListItem is LodgingUpdator &&
          expenseListItem.id == currentState.lodgingUpdator.id;
    } else if (currentState is TransitUpdated &&
        currentState.transitUpdator.dataState == DataState.Updated) {
      var doesIdMatch = expenseListItem is TransitUpdator &&
          expenseListItem.id == currentState.transitUpdator.id;
      if (doesIdMatch) {
        expenseListItem = currentState.transitUpdator;
        return true;
      }
    }
    return false;
  }
}

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
    return Container(
      child: CompositedTransformTarget(
        link: _layerLink,
        child: PlatformButtonElements.createTextButtonWithIcon(
            text: AppLocalizations.of(context)!.category,
            iconData: iconsForCategories[widget.category]!,
            context: context,
            onPressed: _showCategoryPickerWindow),
      ),
    );
  }
}
