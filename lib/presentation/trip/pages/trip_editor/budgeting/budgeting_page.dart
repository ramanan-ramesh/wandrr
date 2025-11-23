import 'package:flutter/material.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/collapsible_section.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/collapsible_sections_page.dart';

import 'breakdown/budget_breakdown_tile.dart';
import 'debt_dummary.dart';

class BudgetingPage extends StatelessWidget {
  const BudgetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      CollapsibleSection(
        title: context.localizations.expenses,
        icon: Icons.wallet_travel_rounded,
        child: const ExpenseListView(),
      ),
      CollapsibleSection(
        title: 'Debt',
        icon: Icons.money_off_rounded,
        child: DebtSummaryTile(),
      ),
      CollapsibleSection(
        title: 'Breakdown',
        icon: Icons.pie_chart_rounded,
        child: BudgetBreakdownTile(),
      ),
    ];
    return CollapsibleSectionsPage(
      sections: sections,
      initiallyExpandedIndex: 0,
    );
  }
}
