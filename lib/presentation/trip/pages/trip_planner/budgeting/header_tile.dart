import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/expense.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/expense_view_type.dart';

class BudgetingHeaderTile extends StatelessWidget {
  final ValueNotifier<ExpenseViewType> _expenseViewTypeNotifier;

  const BudgetingHeaderTile(
      {super.key,
      required ValueNotifier<ExpenseViewType> expenseViewTypeNotifier})
      : _expenseViewTypeNotifier = expenseViewTypeNotifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FittedBox(
                    child: PlatformTextElements.createHeader(
                        context: context,
                        text: context.localizations.budgeting),
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
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 5.0),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                  ExpenseViewType.ExpenseList,
                                  context.localizations.view_expenses,
                                  Icons.list_rounded),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildExpenseViewButton(
                                  context,
                                  ExpenseViewType.BudgetEditor,
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
                                  ExpenseViewType.DebtSummary,
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
                                  ExpenseViewType.BreakdownViewer,
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
          ),
        ),
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
          if (updatedTripEntity.dataState == DataState.Update) {
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
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                if (totalExpense > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 3.0),
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
          if (expenseUpdatedState.dataState == DataState.NewUiEntry) {
            isEnabled = false;
          } else if (expenseUpdatedState.dataState == DataState.Create &&
              tripEntityModificationData.isFromEvent) {
            isEnabled = true;
          } else if (expenseUpdatedState.dataState == DataState.Delete &&
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
          icon: Icon(Icons.add_circle),
        );
      },
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntityUpdated<ExpenseFacade>()) {
          var expenseUpdatedState = currentState as UpdatedTripEntity;
          if (expenseUpdatedState.dataState == DataState.Create ||
              expenseUpdatedState.dataState == DataState.Delete ||
              expenseUpdatedState.dataState == DataState.NewUiEntry) {
            return true;
          }
        }
        return false;
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
