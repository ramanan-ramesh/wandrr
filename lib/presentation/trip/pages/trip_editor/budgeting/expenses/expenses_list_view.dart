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
  // State
  ExpenseSortOption _selectedSortOption = ExpenseSortOption.newToOld;
  bool _costSortAscending = true;
  bool _dateSortNewestFirst = true;
  static late Map<ExpenseCategory, String> _categoryNames;
  List<ExpenseLinkedTripEntity> _expenses = <ExpenseLinkedTripEntity>[];
  Future<Iterable<ExpenseLinkedTripEntity>>? _sortingFuture;
  int _animationToken = 0;

  // UI constants
  static const Duration _kAnimationDuration = Duration(milliseconds: 350);
  static const double _kSortRowVerticalPadding = 12.0;
  static const double _kSortRowHorizontalPadding = 16.0;
  static const double _kEmptyListHeight = 200.0;
  static const double _kListItemBorderRadius = 23.0;
  static const double _kListItemVerticalPadding = 7.0;
  static const double _kListItemHorizontalPadding = 4.0;
  static const double _kToggleMinHeight = 40.0;
  static const double _kToggleMinWidth = 48.0;
  static const double _kIconSpacing = 4.0;
  static const double _kLoadingIndicatorSize = 68.0;

  @override
  Widget build(BuildContext context) {
    _initializeCategoryNames();
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldRebuildList,
      builder: (context, state) {
        _refreshExpenses();
        return _buildListArea();
      },
      listener: (context, state) {},
    );
  }

  Widget _buildListArea() {
    final sortDropdown = _buildSortToggleRow();

    if (_expenses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _kSortRowHorizontalPadding,
              _kSortRowVerticalPadding,
              _kSortRowHorizontalPadding,
              0,
            ),
            child: sortDropdown,
          ),
          Center(
            child: SizedBox(
              height: _kEmptyListHeight,
              child: Center(
                child: PlatformTextElements.createSubHeader(
                  context: context,
                  text: context.localizations.noExpensesCreated,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

    _sortingFuture ??= context.activeTrip.budgetingModule
        .sortExpenses(_expenses, _selectedSortOption);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _kSortRowHorizontalPadding,
            _kSortRowVerticalPadding,
            _kSortRowHorizontalPadding,
            4,
          ),
          child: sortDropdown,
        ),
        Expanded(
          child: FutureBuilder<Iterable<ExpenseLinkedTripEntity>>(
            future: _sortingFuture,
            builder: (context, snapshot) {
              final isDone = snapshot.connectionState == ConnectionState.done;
              final hasData = snapshot.hasData && snapshot.data != null;
              final child = (!isDone || !hasData)
                  ? _buildLoading()
                  : _buildExpenseList(snapshot.data!.toList());
              final childKey = (!isDone || !hasData)
                  ? 'loading-$_animationToken'
                  : 'list-${_selectedSortOption.name}-$_animationToken';
              return _animatedSwitcher(childKey, child);
            },
          ),
        ),
      ],
    );
  }

  Widget _animatedSwitcher(String keyString, Widget child) {
    return AnimatedSwitcher(
      duration: _kAnimationDuration,
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
      child: KeyedSubtree(key: ValueKey(keyString), child: child),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _kLoadingIndicatorSize,
            height: _kLoadingIndicatorSize,
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

  Widget _buildExpenseList(List<ExpenseLinkedTripEntity> sortedExpenses) {
    _expenses = sortedExpenses;
    return ListView.builder(
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final item = _expenses[index];
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: _kListItemVerticalPadding,
            horizontal: _kListItemHorizontalPadding,
          ),
          child: _ExpenseListItem(
            initialExpenseLinkedTripEntity: item,
            categoryNames: _categoryNames,
          ),
        );
      },
    );
  }

  Widget _buildSortToggleRow() {
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
          constraints: const BoxConstraints(
            minHeight: _kToggleMinHeight,
            minWidth: _kToggleMinWidth,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: Row(
                children: [
                  const Icon(Icons.attach_money_rounded),
                  const SizedBox(width: _kIconSpacing),
                  Icon(
                    _costSortAscending
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Icon(Icons.category_outlined),
            ),
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded),
                  const SizedBox(width: _kIconSpacing),
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
      final costActive =
          _selectedSortOption == ExpenseSortOption.lowToHighCost ||
              _selectedSortOption == ExpenseSortOption.highToLowCost;
      if (costActive) {
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
      final dateActive = _selectedSortOption == ExpenseSortOption.oldToNew ||
          _selectedSortOption == ExpenseSortOption.newToOld;
      if (dateActive) {
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

  bool _shouldRebuildList(
    TripManagementState previousState,
    TripManagementState currentState,
  ) {
    if (currentState.isTripEntityUpdated<ExpenseLinkedTripEntity>()) {
      final updatedState = currentState as UpdatedTripEntity;
      if (updatedState.dataState == DataState.delete ||
          updatedState.dataState == DataState.create) {
        return true;
      }
    }
    return false;
  }

  void _refreshExpenses() {
    final activeTrip = context.activeTrip;
    final list = <ExpenseLinkedTripEntity>[];
    list.addAll(activeTrip.expenseCollection.collectionItems);
    list.addAll(activeTrip.transitCollection.collectionItems);
    list.addAll(activeTrip.lodgingCollection.collectionItems);
    for (final itineraryPlanData in activeTrip.itineraryCollection) {
      for (final sight in itineraryPlanData.planData.sights) {
        if (sight.expense.totalExpense.amount > 0) {
          list.add(sight.expense);
        }
      }
    }
    _expenses = list;
    _animationToken++;
    _sortingFuture = context.activeTrip.budgetingModule
        .sortExpenses(_expenses, _selectedSortOption);
  }

  void _initializeCategoryNames() {
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
      ExpenseCategory.other: context.localizations.other,
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
        SelectExpenseLinkedTripEntity(tripEntity: _expenseLinkedTripEntity),
      ),
      child: Material(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: context.isLightTheme ? 0.96 : 0.98),
        elevation: 5,
        borderRadius:
            BorderRadius.circular(_ExpenseListViewState._kListItemBorderRadius),
        shadowColor: AppColors.neutral900.withValues(alpha: 0.10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
                _ExpenseListViewState._kListItemBorderRadius),
            border: Border.all(width: 2.2),
          ),
          child: BlocBuilder<TripManagementBloc, TripManagementState>(
            buildWhen: _shouldRebuildItem,
            builder: (context, state) {
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

  bool _shouldRebuildItem(
    TripManagementState previousState,
    TripManagementState currentState,
  ) {
    if (currentState.isTripEntityUpdated<ExpenseLinkedTripEntity>()) {
      final updatedState = currentState as UpdatedTripEntity;
      final modifiedItem =
          updatedState.tripEntityModificationData.modifiedCollectionItem;
      final updatedId = modifiedItem.id;
      final operation = updatedState.dataState;
      final matches = _expenseLinkedTripEntity.expense.id == updatedId ||
          _expenseLinkedTripEntity.id == updatedId;
      if (operation == DataState.update && matches) {
        setState(() => _expenseLinkedTripEntity = modifiedItem);
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
  ExpenseCategory.other: Icons.feed_rounded,
};
