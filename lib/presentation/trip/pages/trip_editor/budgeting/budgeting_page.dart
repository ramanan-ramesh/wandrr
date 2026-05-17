import 'package:flutter/material.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';
import 'package:wandrr/presentation/trip/widgets/chrome_tab.dart';

import 'breakdown/budget_breakdown_tile.dart';
import 'debt_dummary.dart';

class BudgetingPage extends StatelessWidget {
  const BudgetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChromeTabBar(
            iconsAndTitles: {
              Icons.wallet_travel_rounded: l10n.expenses,
              Icons.money_off_rounded: l10n.debt,
              Icons.pie_chart_rounded: l10n.breakdown,
            },
          ),
          const Expanded(
            child: TabBarView(
              // Disable swipe so the inner TabBarView inside BudgetBreakdownTile
              // can handle horizontal swipe gestures independently.
              physics: NeverScrollableScrollPhysics(),
              children: [
                ExpenseListView(),
                DebtSummaryTile(),
                BudgetBreakdownTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
