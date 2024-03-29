import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/blocs/trip_management_bloc/expense_view_type.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/currencies.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';
import 'package:wandrr/repositories/trip_management.dart';

class BudgetingHeaderTile extends StatelessWidget {
  const BudgetingHeaderTile({
    super.key,
  });

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
                                    Icons.check_rounded,
                                    UpdateExpenseView.showBudgetEditor()),
                                _buildExpenseViewButton(
                                    context,
                                    ExpenseViewType.ShowDebtSummary,
                                    AppLocalizations.of(context)!.debt_summary,
                                    Icons.feed_rounded,
                                    UpdateExpenseView.showDebtSummary())
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(
                      color: Colors.white,
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
                                Icons.list_rounded,
                                UpdateExpenseView.showExpenseList()),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 3.0),
                            child: _buildExpenseViewButton(
                                context,
                                ExpenseViewType.ShowBreakdownViewer,
                                AppLocalizations.of(context)!.view_breakdown,
                                Icons.bar_chart,
                                UpdateExpenseView.showBreakdown()),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 3.0),
                            child: _buildExpenseViewButton(
                                context,
                                ExpenseViewType.ShowAddTripmate,
                                AppLocalizations.of(context)!.add_tripmate,
                                Icons.add_rounded,
                                UpdateExpenseView.showAddTripMate()),
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

  Widget _buildExpenseViewButton(
      BuildContext context,
      ExpenseViewType expenseViewType,
      String buttonText,
      IconData icon,
      UpdateExpenseView expenseViewUpdateEvent) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        print(
            'builder of ExpenseViewButton button called for state - ${state}');
        var shouldEnableButton = true;
        if (state is ExpenseViewUpdated &&
            state.newExpenseViewType == expenseViewType) {
          shouldEnableButton = false;
        }
        return PlatformButtonElements.createTextButtonWithIcon(
            text: buttonText,
            onPressed: shouldEnableButton
                ? () {
                    BlocProvider.of<TripManagementBloc>(context)
                        .add(expenseViewUpdateEvent);
                  }
                : null,
            iconData: icon,
            context: context);
      },
      listener: (BuildContext context, TripManagementState state) {},
      buildWhen: (previousState, currentState) {
        return currentState is ExpenseViewUpdated;
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
      builder: (BuildContext context, TripManagementState state) {
        print(
            'builder of viewBudgetOverview button called for state - ${state}');
        var tripMetadata = RepositoryProvider.of<TripManagement>(context)
            .activeTrip!
            .tripMetaData;
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
      buildWhen: _canBuildBudgetOverview,
    );
  }

  static bool _canBuildBudgetOverview(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState is LoadedTrip) {
      print("BudgetingOverview-previousStaet-${previousState}");
      print("BudgetingOverview-currentState-${currentState}");
      return true;
    } else if (currentState is UpdatedTripMetadata) {
      print("BudgetingOverview-previousStaet-${previousState}");
      print("BudgetingOverview-currentState-${currentState}");
      return true;
    }
    return false;
  }

  Widget _buildCreateExpenseButton(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        print('builder of createExpense button called for state - ${state}');
        var shouldEnableButton = true;
        if (state is ExpenseUpdated) {
          var stateOperation = state.operation;
          if (stateOperation == DataState.Created) {
            if (state.expenseUpdator.dataState == DataState.CreateNewUIEntry) {
              shouldEnableButton = false;
            }
          }
        }
        return PlatformButtonElements.createExtendedFAB(
            iconData: Icons.add_circle,
            text: AppLocalizations.of(context)!.add_expense,
            enabled: shouldEnableButton,
            onPressed: () {
              var tripManagementBloc =
                  BlocProvider.of<TripManagementBloc>(context);
              var activeTrip =
                  RepositoryProvider.of<TripManagement>(context).activeTrip!;
              var appLevelData =
                  RepositoryProvider.of<PlatformDataRepository>(context)
                      .appLevelData;
              var expenseUpdator = ExpenseUpdator.createNewUIEntry(
                  tripId: activeTrip.tripMetaData.id,
                  currentUserName: appLevelData.activeUser!.userName,
                  tripContributors: activeTrip.tripMetaData.contributors,
                  currency: activeTrip.tripMetaData.budget.currency);
              var expenseUpdated =
                  UpdateExpense.create(expenseUpdator: expenseUpdator);
              tripManagementBloc.add(expenseUpdated);
            },
            context: context);
      },
      buildWhen: (previousState, currentState) {
        return currentState is ExpenseUpdated &&
            (currentState.operation == DataState.Created ||
                currentState.operation == DataState.Deleted);
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
