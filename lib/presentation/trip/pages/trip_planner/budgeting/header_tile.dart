import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/expense.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/widgets/card.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/expense_view_type.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/constants.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/trip_navigator.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/flip_card/flip_card.dart';

class BudgetingHeaderTile extends StatelessWidget {
  final ValueNotifier<ExpenseViewType> _expenseViewTypeNotifier;

  const BudgetingHeaderTile(
      {super.key,
      required ValueNotifier<ExpenseViewType> expenseViewTypeNotifier})
      : _expenseViewTypeNotifier = expenseViewTypeNotifier;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripManagementBloc, TripManagementState>(
      listener: (BuildContext context, TripManagementState state) {
        if (state is ProcessSectionNavigation &&
            state.section.toLowerCase() == NavigationSections.budgeting) {
          RepositoryProvider.of<TripNavigator>(context).jumpToList(context);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: _createHeader(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: FlipCard(
              fill: Fill.back,
              direction: Axis.horizontal,
              duration: const Duration(milliseconds: 750),
              autoFlipDuration:
                  context.isBigLayout ? null : const Duration(seconds: 0),
              front: _createOverviewTile(context),
              back: _createOverviewTile(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _createOverviewTile(BuildContext context) {
    return PlatformCard(
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildBudgetOverview(context),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildExpenseViewButton(
                            context,
                            ExpenseViewType.expenseList,
                            context.localizations.view_expenses,
                            Icons.list_rounded),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildExpenseViewButton(
                            context,
                            ExpenseViewType.budgetEditor,
                            context.localizations.edit_budget,
                            Icons.edit_rounded),
                        // ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildExpenseViewButton(
                            context,
                            ExpenseViewType.debtSummary,
                            context.localizations.debt_summary,
                            Icons.money_rounded),
                        // ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildExpenseViewButton(
                            context,
                            ExpenseViewType.breakdownViewer,
                            context.localizations.view_breakdown,
                            Icons.bar_chart_rounded),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _createHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FittedBox(
              child: PlatformTextElements.createHeader(
                  context: context, text: context.localizations.budgeting),
            ),
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildCreateExpenseButton(context),
          ),
        )
      ],
    );
  }

  Widget _buildExpenseViewButton(BuildContext context,
      ExpenseViewType expenseViewType, String buttonText, IconData icon) {
    return ValueListenableBuilder(
      valueListenable: _expenseViewTypeNotifier,
      builder: (BuildContext context, ExpenseViewType value, Widget? child) {
        var shouldEnableButton =
            _expenseViewTypeNotifier.value != expenseViewType;
        return TextButton.icon(
          onPressed: shouldEnableButton
              ? () {
                  _expenseViewTypeNotifier.value = expenseViewType;
                }
              : null,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color?>(
                !shouldEnableButton ? Colors.white12 : null),
          ),
          label: Text(
            buttonText,
          ),
          icon: Icon(icon),
        );
      },
    );
  }

  static double _calculateExpenseRatio(double amountSpent, double budget) {
    if (amountSpent == 0 || budget == 0) {
      return 1;
    }
    if (amountSpent < budget) {
      return amountSpent / budget;
    } else if (amountSpent > budget) {
      return budget / amountSpent;
    } else {
      return 1;
    }
  }

  Widget _buildBudgetOverview(BuildContext context) {
    var activeTrip = context.activeTrip;
    var budget = activeTrip.tripMetadata.budget;
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntityUpdated<TripMetadataFacade>()) {
          var updatedTripEntity = currentState as UpdatedTripEntity;
          if (updatedTripEntity.dataState == DataState.update) {
            var updatedTripMetadata = updatedTripEntity
                .tripEntityModificationData
                .modifiedCollectionItem as TripMetadataFacade;
            if (updatedTripMetadata.budget != budget) {
              budget = updatedTripMetadata.budget;
              return true;
            }
          }
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        return StreamBuilder(
          stream: activeTrip.budgetingModuleFacade.totalExpenditureStream,
          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
            var tripMetadata = activeTrip.tripMetadata;
            double currentTotalExpenditure;
            if (snapshot.data == null) {
              currentTotalExpenditure =
                  activeTrip.budgetingModuleFacade.totalExpenditure;
            } else {
              currentTotalExpenditure = snapshot.data!;
            }
            var totalExpense = snapshot.data ?? currentTotalExpenditure;
            var expenseRatio =
                _calculateExpenseRatio(totalExpense, budget.amount);
            var currencyInfo = context.supportedCurrencies.firstWhere(
                (element) => element.code == tripMetadata.budget.currency);
            var budgetText =
                '${context.localizations.budget}: ${budget.toString()}';
            var totalExpenseText =
                '${currencyInfo.symbol} ${totalExpense.toStringAsFixed(2)}';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: PlatformTextElements.createHeader(
                    context: context,
                    text: totalExpenseText,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    budgetText,
                  ),
                ),
                if (totalExpense > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: LinearProgressIndicator(
                      value: expenseRatio,
                      color: Colors.green,
                      backgroundColor:
                          totalExpense > budget.amount ? Colors.red : null,
                    ),
                  )
              ],
            );
          },
          initialData: activeTrip.budgetingModuleFacade.totalExpenditure,
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildCreateExpenseButton(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        var isEnabled = true;
        if (state.isTripEntityUpdated<ExpenseFacade>()) {
          var expenseUpdatedState = state as UpdatedTripEntity;
          var tripEntityModificationData =
              expenseUpdatedState.tripEntityModificationData;
          var modifiedCollectionItem = tripEntityModificationData
              .modifiedCollectionItem as ExpenseFacade;
          if (expenseUpdatedState.dataState == DataState.newUiEntry) {
            isEnabled = false;
          } else if (expenseUpdatedState.dataState == DataState.create &&
              tripEntityModificationData.isFromEvent) {
            isEnabled = true;
          } else if (expenseUpdatedState.dataState == DataState.delete &&
                  modifiedCollectionItem.id == null ||
              modifiedCollectionItem.id!.isEmpty) {
            isEnabled = true;
          }
        }
        return FloatingActionButton.extended(
          onPressed: !isEnabled
              ? null
              : () {
                  context.addTripManagementEvent(
                      UpdateTripEntity<ExpenseFacade>.createNewUiEntry());
                },
          label: Text(context.localizations.add_expense),
          icon: const Icon(Icons.add_circle),
        );
      },
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntityUpdated<ExpenseFacade>()) {
          var expenseUpdatedState = currentState as UpdatedTripEntity;
          if (expenseUpdatedState.dataState == DataState.create ||
              expenseUpdatedState.dataState == DataState.delete ||
              expenseUpdatedState.dataState == DataState.newUiEntry) {
            return true;
          }
        }
        return false;
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
