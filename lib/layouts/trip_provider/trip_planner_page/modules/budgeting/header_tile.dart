import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/blocs/trip_management/states.dart';
import 'package:wandrr/contracts/data_states.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/currencies.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/expense_view_type.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/text.dart';

class BudgetingHeaderTile extends StatelessWidget {
  final ValueNotifier<ExpenseViewType> _expenseViewTypeNotifier;

  const BudgetingHeaderTile(
      {super.key,
      required ValueNotifier<ExpenseViewType> expenseViewTypeNotifier})
      : _expenseViewTypeNotifier = expenseViewTypeNotifier;

  @override
  Widget build(BuildContext context) {
    print("BudgetingHeaderTile-build");
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
                  context: context,
                  text: AppLocalizations.of(context)!.budgeting),
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
                                _buildExpenseViewButton(
                                    context,
                                    ExpenseViewType.ShowBudgetEditor,
                                    AppLocalizations.of(context)!.edit_budget,
                                    Icons.check_rounded),
                                _buildExpenseViewButton(
                                    context,
                                    ExpenseViewType.ShowDebtSummary,
                                    AppLocalizations.of(context)!.debt_summary,
                                    Icons.feed_rounded)
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
                                AppLocalizations.of(context)!.view_expenses,
                                Icons.list_rounded),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 3.0),
                            child: _buildExpenseViewButton(
                                context,
                                ExpenseViewType.ShowBreakdownViewer,
                                AppLocalizations.of(context)!.view_breakdown,
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
        return PlatformButtonElements.createTextButtonWithIcon(
          key: key,
          onPressed: shouldEnableButton
              ? () {
                  _expenseViewTypeNotifier.value = expenseViewType;
                }
              : null,
          isEnabled: shouldEnableButton,
          iconData: icon,
          text: buttonText,
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
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntity<TripMetadataModelFacade>()) {
          return (currentState as UpdatedTripEntity).dataState ==
              DataState.Update;
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        var tripMetadata = context.getActiveTrip().tripMetadata;
        var totalExpenditure = tripMetadata.totalExpenditure;
        var totalBudget = tripMetadata.budget;
        double expenseRatio =
            _calculateExpenseRatio(totalExpenditure, totalBudget.amount);
        var currencyInfo = currencies.firstWhere(
            (element) => element['code'] == tripMetadata.budget.currency);
        var budgetText =
            '${AppLocalizations.of(context)!.budget}: ${totalBudget.toString()}';
        var totalExpenseText =
            '${currencyInfo['symbol']} ${totalExpenditure.toStringAsFixed(2)}';
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
            if (totalExpenditure > 0)
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
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildCreateExpenseButton(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        print('builder of createExpense button called for state - ${state}');
        var shouldEnableButton = true;
        if (state.isTripEntity<ExpenseModelFacade>()) {
          var expenseUpdatedState = state as UpdatedTripEntity;
          if (expenseUpdatedState.dataState == DataState.NewUiEntry) {
            shouldEnableButton = false;
          } else if (expenseUpdatedState.dataState == DataState.Delete &&
              expenseUpdatedState
                      .tripEntityModificationData.modifiedCollectionItem.id ==
                  null) {
            shouldEnableButton = true;
          }
        }
        return FloatingActionButton.extended(
          onPressed: () {
            var tripManagementBloc =
                BlocProvider.of<TripManagementBloc>(context);
            var expenseUpdated =
                UpdateTripEntity<ExpenseModelFacade>.createNewUiEntry();
            tripManagementBloc.add(expenseUpdated);
          },
          label: Text(AppLocalizations.of(context)!.add_expense),
          icon: Icon(Icons.add_circle),
        );
      },
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntity<ExpenseModelFacade>()) {
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
