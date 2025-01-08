import 'package:flutter/material.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/budgeting/breakdown/budget_breakdown_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/budgeting/budget_edit_tile.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/budgeting/debt_dummary.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/expense_view_type.dart';

import 'trip_entity_list_views/expenses.dart';

class ExpenseViewAdapter extends StatelessWidget {
  final ValueNotifier<ExpenseViewType> _expenseViewTypeNotifier;

  const ExpenseViewAdapter(
      {super.key,
      required ValueNotifier<ExpenseViewType> expenseViewTypeNotifier})
      : _expenseViewTypeNotifier = expenseViewTypeNotifier;

  @override
  Widget build(BuildContext context) {
    var emptyWidget = const SliverToBoxAdapter(
      child: SizedBox.shrink(),
    );
    return ValueListenableBuilder(
      valueListenable: _expenseViewTypeNotifier,
      builder: (BuildContext context, ExpenseViewType value, Widget? child) {
        switch (_expenseViewTypeNotifier.value) {
          case ExpenseViewType.ExpenseList:
            {
              return ExpenseListViewNew();
            }
          case ExpenseViewType.BudgetEditor:
            {
              return BudgetEditTile();
            }
          case ExpenseViewType.BreakdownViewer:
            {
              return const BudgetBreakdownTile();
            }
          case ExpenseViewType.DebtSummary:
            {
              return const DebtSummaryTile();
            }
        }
      },
    );
  }
}
