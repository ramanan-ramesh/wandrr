import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/expense_view_type.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/budget_breakdown/budget_breakdown_tile.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/budget_edit_tile.dart';

import 'expenses_listview.dart';

class ExpenseViewAdapter extends StatelessWidget {
  const ExpenseViewAdapter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildExpenseViewAdapter,
      builder: (BuildContext context, TripManagementState state) {
        var emptyWidget = SliverToBoxAdapter(
          child: SizedBox.shrink(),
        );
        if (state is ExpenseViewUpdated) {
          switch (state.newExpenseViewType) {
            case ExpenseViewType.ShowExpenseList:
              {
                return ExpensesListView(isCollapsed: false);
              }
            case ExpenseViewType.ShowBudgetEditor:
              {
                return BudgetEditTile();
              }
            case ExpenseViewType.ShowBreakdownViewer:
              {
                return BudgetBreakdownTile();
              }
            default:
              {
                return emptyWidget;
              }
          }
        }
        return emptyWidget;
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldBuildExpenseViewAdapter(
      TripManagementState previousState, TripManagementState currentState) {
    return currentState is ExpenseViewUpdated;
  }
}
