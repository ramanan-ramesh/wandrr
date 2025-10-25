import 'package:flutter/material.dart';

import 'breakdown/budget_breakdown_tile.dart';
import 'debt_dummary.dart';

class BudgetingPage extends StatefulWidget {
  const BudgetingPage({super.key});

  @override
  State<BudgetingPage> createState() => _BudgetingPageState();
}

class _BudgetingPageState extends State<BudgetingPage> {
  int? _expandedSectionIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = 500.0;
        final availableHeight = constraints.maxHeight < minHeight
            ? minHeight
            : constraints.maxHeight;
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Column(
            children: [
              // const ExpenseListViewNew(),
              _buildCollapsibleSection(
                index: 1,
                title: 'Debt',
                child: const DebtSummaryTile(),
                availableHeight: availableHeight,
              ),
              _buildCollapsibleSection(
                index: 2,
                title: 'Breakdown',
                child: const BudgetBreakdownTile(),
                availableHeight: availableHeight,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollapsibleSection({
    required int index,
    required String title,
    required Widget child,
    required double availableHeight,
  }) {
    final isExpanded = _expandedSectionIndex == index;
    final header = _buildSectionHeader(title, isExpanded, index);
    final divider = const Divider(height: 1, thickness: 1);
    if (isExpanded) {
      // Calculate height for expanded section so all headers are visible
      final headerHeight = 56.0; // Estimate header+divider height
      final collapsedCount = 2;
      final expandedContentHeight =
          availableHeight - (collapsedCount * headerHeight);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          divider,
          Flexible(
            child: SizedBox(
              height: expandedContentHeight > 0 ? expandedContentHeight : 100.0,
              child: SingleChildScrollView(child: child),
            ),
          ),
          // No divider after expanded content (already included above)
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          divider,
        ],
      );
    }
  }

  Widget _buildSectionHeader(String title, bool isExpanded, int index) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedSectionIndex = isExpanded ? null : index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 28.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
