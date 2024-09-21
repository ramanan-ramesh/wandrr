import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_data/models/data_states.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/blocs/bloc_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/models/expense.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/expense_view_type.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/bloc.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/events.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/states.dart';

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
              PlatformTextElements.createHeader(
                  context: context, text: context.withLocale().budgeting),
              _buildCreateExpenseButton(context)
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
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBudgetOverview(context),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                  child: _buildExpenseViewButton(
                                      context,
                                      ExpenseViewType.ShowBudgetEditor,
                                      context.withLocale().edit_budget,
                                      Icons.check_rounded),
                                ),
                                Flexible(
                                  child: _buildExpenseViewButton(
                                      context,
                                      ExpenseViewType.ShowDebtSummary,
                                      context.withLocale().debt_summary,
                                      Icons.feed_rounded),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(
                      thickness: 2,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 3.0),
                            child: _buildExpenseViewButton(
                                context,
                                ExpenseViewType.ShowExpenseList,
                                context.withLocale().view_expenses,
                                Icons.list_rounded),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 3.0),
                            child: _buildExpenseViewButton(
                                context,
                                ExpenseViewType.ShowBreakdownViewer,
                                context.withLocale().view_breakdown,
                                Icons.bar_chart),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
        //TODO: Set color to a lighter version, preferably from ThemeData(black12?)
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
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(buttonText),
          ),
          icon: Icon(icon),
          key: key,
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
    var activeTrip = context.getActiveTrip();
    return StreamBuilder(
      stream: activeTrip.budgetingModuleFacade.totalExpenditureStream,
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        var tripMetadata = activeTrip.tripMetadata;
        var currentTotalExpenditure =
            activeTrip.budgetingModuleFacade.totalExpenditure;
        var totalExpense = snapshot.data ?? currentTotalExpenditure;
        var totalBudget = tripMetadata.budget;
        double expenseRatio =
            _calculateExpenseRatio(totalExpense, totalBudget.amount);
        var currencyInfo = context.getSupportedCurrencies().firstWhere(
            (element) => element.code == tripMetadata.budget.currency);
        var budgetText =
            '${context.withLocale().budget}: ${totalBudget.toString()}';
        var totalExpenseText =
            '${currencyInfo.symbol} ${totalExpense.toStringAsFixed(2)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlatformTextElements.createHeader(
              context: context,
              text: totalExpenseText,
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
                ),
              )
          ],
        );
      },
      initialData: activeTrip.budgetingModuleFacade.totalExpenditure,
    );
  }

  Widget _buildCreateExpenseButton(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        if (state.isTripEntity<ExpenseFacade>()) {
          var expenseUpdatedState = state as UpdatedTripEntity;
          if (expenseUpdatedState.dataState == DataState.NewUiEntry) {
          } else if (expenseUpdatedState.dataState == DataState.Delete &&
              expenseUpdatedState
                      .tripEntityModificationData.modifiedCollectionItem.id ==
                  null) {}
        }
        return FloatingActionButton.extended(
          onPressed: () {
            context.addTripManagementEvent(
                UpdateTripEntity<ExpenseFacade>.createNewUiEntry());
          },
          label: Text(context.withLocale().add_expense),
          icon: Icon(Icons.add_circle),
        );
      },
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntity<ExpenseFacade>()) {
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
