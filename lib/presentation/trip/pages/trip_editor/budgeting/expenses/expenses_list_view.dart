import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
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
  var _selectedSortOption = ExpenseSortOption.oldToNew;
  static late Map<ExpenseCategory, String> _categoryNames;
  static late Map<ExpenseSortOption, String> _availableSortOptions;
  var _expenses = <ExpenseLinkedTripEntity>[];

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
    if (_expenses.isEmpty) {
      return _createEmptyMessagePane(context);
    } else {
      return FutureBuilder<Iterable<ExpenseLinkedTripEntity>>(
        future: context.activeTrip.budgetingModule
            .sortExpenses(_expenses, _selectedSortOption),
        builder: (BuildContext context,
            AsyncSnapshot<Iterable<ExpenseLinkedTripEntity>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            _expenses = snapshot.data!.toList();
            return _createSliverList();
          }
          return Center(child: CircularProgressIndicator());
        },
      );
    }
  }

  Widget _createSliverList() {
    return ListView.builder(
      itemCount: _expenses.length,
      itemBuilder: (BuildContext context, int index) {
        var uiElement = _expenses.elementAt(index);
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
              child: _ExpenseListItem(
                  expenseLinkedTripEntity: uiElement,
                  categoryNames: _categoryNames),
            ),
          ),
        );
      },
    );
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
    _expenses = expenseUiElements.toList();
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

class _ExpenseListItem extends StatelessWidget {
  ExpenseLinkedTripEntity expenseLinkedTripEntity;
  final Map<ExpenseCategory, String> categoryNames;

  _ExpenseListItem(
      {super.key,
      required this.expenseLinkedTripEntity,
      required this.categoryNames});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildListElement,
      builder: (BuildContext context, TripManagementState state) {
        return ReadonlyExpenseListItem(
            expenseModelFacade: expenseLinkedTripEntity.expense,
            categoryNames: categoryNames);
      },
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
          (expenseLinkedTripEntity.expense.id == updatedTripElementId ||
              expenseLinkedTripEntity.id == updatedTripElementId)) {
        expenseLinkedTripEntity = modifiedTransitCollectionItem;
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
