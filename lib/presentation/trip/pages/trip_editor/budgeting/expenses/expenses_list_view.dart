import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_sort_options.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/readonly_expense.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class ExpenseListView extends StatefulWidget {
  const ExpenseListView({super.key});

  @override
  State<ExpenseListView> createState() => _ExpenseListViewState();
}

class _ExpenseListViewState extends State<ExpenseListView> {
  var _selectedSortOption = ExpenseSortOption.newToOld;
  var _costSortAscending = true;
  var _dateSortNewestFirst = true;
  static late Map<ExpenseCategory, String> _categoryNames;
  var _expenses = <ExpenseLinkedTripEntity>[];
  Future<Iterable<ExpenseLinkedTripEntity>>? _sortingFuture;
  int _animationToken = 0;

  @override
  Widget build(BuildContext context) {
    _initializeUIComponentNames(context);
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildList,
      builder: (BuildContext context, TripManagementState state) {
        _updateListElementsOnBuild(context, state);
        return _createListViewingArea(context);
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _createListViewingArea(BuildContext context) {
    final sortDropdown = _createSortDropdown(context);

    if (_expenses.isEmpty) {
      return _createEmptyListMessage(sortDropdown, context);
    }

    _sortingFuture ??= context.activeTrip.budgetingModule
        .sortExpenses(_expenses, _selectedSortOption);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: sortDropdown,
        ),
        Expanded(
          child: FutureBuilder<Iterable<ExpenseLinkedTripEntity>>(
            future: _sortingFuture,
            builder: (BuildContext context,
                AsyncSnapshot<Iterable<ExpenseLinkedTripEntity>> snapshot) {
              Widget child;
              String childKey;
              if (snapshot.connectionState != ConnectionState.done ||
                  !snapshot.hasData) {
                child = _buildLoadingAnimation(context);
                childKey = 'loading-$_animationToken';
              } else {
                _expenses = snapshot.data!.toList();
                child = _createSliverList();
                childKey = 'list-${_selectedSortOption.name}-$_animationToken';
              }
              return _createAnimatedList(childKey, child);
            },
          ),
        ),
      ],
    );
  }

  Widget _createAnimatedList(String childKey, Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (widget, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.06),
            end: Offset.zero,
          ).animate(animation),
          child: widget,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(childKey),
        child: child,
      ),
    );
  }

  Column _createEmptyListMessage(Widget sortDropdown, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: sortDropdown,
        ),
        Center(
          child: Container(
            height: 200,
            color: Colors.transparent,
            child: Center(
              child: PlatformTextElements.createSubHeader(
                  context: context,
                  text: context.localizations.noExpensesCreated,
                  textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    );
  }

  Widget _createSortDropdown(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ToggleButtons(
          isSelected: [
            _selectedSortOption == ExpenseSortOption.lowToHighCost ||
                _selectedSortOption == ExpenseSortOption.highToLowCost,
            _selectedSortOption == ExpenseSortOption.category,
            _selectedSortOption == ExpenseSortOption.oldToNew ||
                _selectedSortOption == ExpenseSortOption.newToOld,
          ],
          onPressed: _onToggleSortOption,
          constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
          children: [
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: Row(
                children: [
                  Icon(Icons.attach_money_rounded),
                  const SizedBox(width: 4),
                  Icon(
                    _costSortAscending
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Icon(Icons.category_outlined),
            ),
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded),
                  const SizedBox(width: 4),
                  Icon(
                    _dateSortNewestFirst
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onToggleSortOption(int index) {
    ExpenseSortOption newSortOption;
    if (index == 0) {
      final isCostActive =
          _selectedSortOption == ExpenseSortOption.lowToHighCost ||
              _selectedSortOption == ExpenseSortOption.highToLowCost;
      if (isCostActive) {
        newSortOption = _selectedSortOption == ExpenseSortOption.lowToHighCost
            ? ExpenseSortOption.highToLowCost
            : ExpenseSortOption.lowToHighCost;
        _costSortAscending = !_costSortAscending;
      } else {
        newSortOption = _costSortAscending
            ? ExpenseSortOption.lowToHighCost
            : ExpenseSortOption.highToLowCost;
      }
    } else if (index == 1) {
      newSortOption = ExpenseSortOption.category;
    } else {
      final isDateActive = _selectedSortOption == ExpenseSortOption.oldToNew ||
          _selectedSortOption == ExpenseSortOption.newToOld;
      if (isDateActive) {
        newSortOption = _selectedSortOption == ExpenseSortOption.oldToNew
            ? ExpenseSortOption.newToOld
            : ExpenseSortOption.oldToNew;
        _dateSortNewestFirst = !_dateSortNewestFirst;
      } else {
        newSortOption = _dateSortNewestFirst
            ? ExpenseSortOption.newToOld
            : ExpenseSortOption.oldToNew;
      }
    }

    if (newSortOption != _selectedSortOption) {
      setState(() {
        _selectedSortOption = newSortOption;
        _animationToken++;
        _sortingFuture = context.activeTrip.budgetingModule
            .sortExpenses(_expenses, _selectedSortOption);
      });
    }
  }

  Widget _buildLoadingAnimation(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.localizations.loading,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }

  Widget _createSliverList() {
    return ListView.builder(
      itemCount: _expenses.length,
      itemBuilder: (BuildContext context, int index) {
        var uiElement = _expenses.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 4.0),
          child: _ExpenseListItem(
              initialExpenseLinkedTripEntity: uiElement,
              categoryNames: _categoryNames),
        );
      },
    );
  }

  bool _shouldBuildList(
      TripManagementState previousState, TripManagementState currentState) {
    //TODO: The list should rebuild for updates to Trip Start/End dates
    if (currentState.isTripEntityUpdated<ExpenseLinkedTripEntity>()) {
      var updatedTripEntityState = currentState as UpdatedTripEntity;
      if (updatedTripEntityState.dataState == DataState.delete ||
          updatedTripEntityState.dataState == DataState.create) {
        return true;
      }
    }
    return false;
  }

  void _updateListElementsOnBuild(
      BuildContext context, TripManagementState state) {
    var activeTrip = context.activeTrip;
    _expenses.clear();
    var expenseUiElements = <ExpenseLinkedTripEntity>[];
    expenseUiElements.addAll(activeTrip.expenseCollection.collectionItems);
    expenseUiElements.addAll(activeTrip.transitCollection.collectionItems);
    expenseUiElements.addAll(activeTrip.lodgingCollection.collectionItems);
    for (var itineraryPlanData in activeTrip.itineraryCollection) {
      for (var sight in itineraryPlanData.planData.sights) {
        var totalExpense = sight.expense.totalExpense.amount;
        if (totalExpense > 0) {
          expenseUiElements.add(sight.expense);
        }
      }
    }
    _expenses = expenseUiElements.toList();
    _animationToken++;
    _sortingFuture = context.activeTrip.budgetingModule
        .sortExpenses(_expenses, _selectedSortOption);
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
  }
}

class _ExpenseListItem extends StatefulWidget {
  final ExpenseLinkedTripEntity initialExpenseLinkedTripEntity;
  final Map<ExpenseCategory, String> categoryNames;

  const _ExpenseListItem({
    required this.initialExpenseLinkedTripEntity,
    required this.categoryNames,
  });

  @override
  State<_ExpenseListItem> createState() => _ExpenseListItemState();
}

class _ExpenseListItemState extends State<_ExpenseListItem> {
  late ExpenseLinkedTripEntity _expenseLinkedTripEntity;

  @override
  void initState() {
    super.initState();
    _expenseLinkedTripEntity = widget.initialExpenseLinkedTripEntity;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.addTripManagementEvent(
          SelectExpenseLinkedTripEntity(tripEntity: _expenseLinkedTripEntity)),
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
            border: Border.all(width: 2.2),
          ),
          child: BlocBuilder<TripManagementBloc, TripManagementState>(
            buildWhen: _shouldBuildListElement,
            builder: (BuildContext context, TripManagementState state) {
              return ReadonlyExpenseListItem(
                categoryNames: widget.categoryNames,
                expenseLinkedTripEntity: _expenseLinkedTripEntity,
              );
            },
          ),
        ),
      ),
    );
  }

  bool _shouldBuildListElement(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<ExpenseLinkedTripEntity>()) {
      var transitUpdatedState = currentState as UpdatedTripEntity;
      ExpenseLinkedTripEntity modifiedTransitCollectionItem =
          transitUpdatedState.tripEntityModificationData.modifiedCollectionItem;
      var updatedTripElementId = modifiedTransitCollectionItem.id;
      var operationPerformed = transitUpdatedState.dataState;
      if (operationPerformed == DataState.update &&
          (_expenseLinkedTripEntity.expense.id == updatedTripElementId ||
              _expenseLinkedTripEntity.id == updatedTripElementId)) {
        setState(() {
          _expenseLinkedTripEntity = modifiedTransitCollectionItem;
        });
        return true;
      }
    }
    return false;
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
