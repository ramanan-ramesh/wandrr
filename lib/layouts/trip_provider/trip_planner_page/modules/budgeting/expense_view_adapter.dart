import 'package:flutter/material.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/expense_view_type.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/budget_breakdown/budget_breakdown_tile.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/budget_edit_tile.dart';

import 'expenses_listview.dart';

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
          case ExpenseViewType.ShowExpenseList:
            {
              return ExpenseListViewNew();
            }
          case ExpenseViewType.ShowBudgetEditor:
            {
              return BudgetEditTile();
            }
          case ExpenseViewType.ShowBreakdownViewer:
            {
              return const BudgetBreakdownTile();
            }
          default:
            {
              return emptyWidget;
            }
        }
      },
    );
  }
}
