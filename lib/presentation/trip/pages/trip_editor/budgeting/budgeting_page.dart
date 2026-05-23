import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/bubble_tab_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';

import 'breakdown/budget_breakdown_tile.dart';
import 'debt_dummary.dart';

class BudgetingPage extends StatefulWidget {
  const BudgetingPage({super.key});

  @override
  State<BudgetingPage> createState() => _BudgetingPageState();
}

class _BudgetingPageState extends State<BudgetingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final isLight = context.isLightTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BubbleTabBar(
          controller: _tabController,
          height: 48,
          showLabels: true,
          tabs: [
            BubbleTabData(
              icon: Icons.wallet_travel_rounded,
              label: l10n.expenses,
              semanticLabel: l10n.expenses,
            ),
            BubbleTabData(
              icon: Icons.money_off_rounded,
              label: l10n.debt,
              semanticLabel: l10n.debt,
            ),
            BubbleTabData(
              icon: Icons.pie_chart_rounded,
              label: l10n.breakdown,
              semanticLabel: l10n.breakdown,
            ),
          ],
        ),
        Expanded(
          child: ColoredBox(
            color: isLight
                ? AppColors.lightBackground
                : AppColors.darkSurfaceVariant,
            child: TabBarView(
              controller: _tabController,
              children: const [
                ExpenseListView(),
                DebtSummaryTile(),
                BudgetBreakdownTile(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
