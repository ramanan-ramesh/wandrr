import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_entities_model.dart';

class AffectedExpensesSection extends StatefulWidget {
  final List<AffectedEntityItem<ExpenseFacade>> allExpenses;
  final List<String> addedContributors;
  final VoidCallback onChanged;

  const AffectedExpensesSection({
    super.key,
    required this.allExpenses,
    required this.addedContributors,
    required this.onChanged,
  });

  @override
  State<AffectedExpensesSection> createState() =>
      _AffectedExpensesSectionState();
}

class _AffectedExpensesSectionState extends State<AffectedExpensesSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.allExpenses.isEmpty || widget.addedContributors.isEmpty) {
      return const SizedBox.shrink();
    }

    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.receipt_long_rounded,
            title: 'Expenses (${widget.allExpenses.length})',
            iconColor:
                isLightTheme ? AppColors.warning : AppColors.warningLight,
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            _buildNewContributorsInfo(context),
            const SizedBox(height: 8),
            _buildSelectAllToggle(context),
            const SizedBox(height: 12),
            ...widget.allExpenses
                .map((item) => _buildExpenseItem(context, item)),
          ],
        ],
      ),
    );
  }

  Widget _buildNewContributorsInfo(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.successLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.successLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_add_rounded,
                size: 16,
                color:
                    isLightTheme ? AppColors.success : AppColors.successLight,
              ),
              const SizedBox(width: 8),
              Text(
                'New tripmates:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isLightTheme
                          ? AppColors.success
                          : AppColors.successLight,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.addedContributors
                .map((contributor) => Chip(
                      label: Text(
                        contributor,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      backgroundColor: isLightTheme
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.successLight.withValues(alpha: 0.2),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Select expenses to split with new tripmates',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLightTheme
                      ? Colors.grey.shade700
                      : Colors.grey.shade400,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAllToggle(BuildContext context) {
    final allSelected =
        widget.allExpenses.every((item) => item.includeInSplitBy);
    final noneSelected =
        widget.allExpenses.every((item) => !item.includeInSplitBy);
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () {
            setState(() {
              final newValue = !allSelected;
              for (final item in widget.allExpenses) {
                item.includeInSplitBy = newValue;
              }
            });
            widget.onChanged();
          },
          icon: Icon(
            allSelected
                ? Icons.deselect
                : noneSelected
                    ? Icons.select_all
                    : Icons.select_all,
            size: 18,
            color: isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight,
          ),
          label: Text(
            allSelected ? 'Deselect All' : 'Select All',
            style: TextStyle(
              color: isLightTheme
                  ? AppColors.brandPrimary
                  : AppColors.brandPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseItem(
      BuildContext context, AffectedEntityItem<ExpenseFacade> item) {
    final expense = item.modifiedEntity;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isLightTheme
            ? Colors.grey.shade100
            : Colors.grey.shade800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.includeInSplitBy
              ? (isLightTheme ? AppColors.success : AppColors.successLight)
              : (isLightTheme ? Colors.grey.shade300 : Colors.grey.shade700),
          width: item.includeInSplitBy ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: item.includeInSplitBy,
        onChanged: (value) {
          setState(() {
            item.includeInSplitBy = value ?? false;
          });
          widget.onChanged();
        },
        title: Text(
          expense.title.isNotEmpty ? expense.title : 'Unnamed Expense',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expense.description != null && expense.description!.isNotEmpty)
              Text(
                expense.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getCategoryIcon(expense.category.name),
                  size: 14,
                  color: isLightTheme
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  expense.category.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLightTheme
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${expense.totalExpense.currency} ${expense.totalExpense.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLightTheme
                            ? AppColors.warning
                            : AppColors.warningLight,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Current split: ${expense.splitBy.join(", ")}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        activeColor: isLightTheme ? AppColors.success : AppColors.successLight,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'lodging':
        return Icons.hotel;
      case 'flight':
        return Icons.flight;
      case 'train':
        return Icons.train;
      case 'bus':
        return Icons.directions_bus;
      case 'ferry':
        return Icons.directions_ferry;
      case 'vehicle':
      case 'rentedvehicle':
        return Icons.directions_car;
      case 'food':
        return Icons.restaurant;
      case 'sightseeing':
        return Icons.attractions;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.receipt;
    }
  }
}
