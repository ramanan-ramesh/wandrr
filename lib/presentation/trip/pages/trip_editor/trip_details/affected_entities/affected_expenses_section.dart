import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';

class AffectedExpensesSection extends StatefulWidget {
  final Iterable<EntityChange<ExpenseBearingTripEntity>> allExpenses;
  final Iterable<String> addedContributors;
  final Iterable<String> removedContributors;
  final VoidCallback onChanged;

  const AffectedExpensesSection({
    super.key,
    required this.allExpenses,
    required this.addedContributors,
    required this.removedContributors,
    required this.onChanged,
  });

  @override
  State<AffectedExpensesSection> createState() =>
      _AffectedExpensesSectionState();
}

class _AffectedExpensesSectionState extends State<AffectedExpensesSection> {
  bool _isExpanded = false;

  int get _activeExpenseCount =>
      widget.allExpenses.where((e) => !e.isMarkedForDeletion).length;

  @override
  Widget build(BuildContext context) {
    // Show section if there are added contributors with expenses, or removed contributors
    final hasAddedContributors = widget.addedContributors.isNotEmpty;
    final hasRemovedContributors = widget.removedContributors.isNotEmpty;

    if (widget.allExpenses.isEmpty ||
        (!hasAddedContributors && !hasRemovedContributors)) {
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
            title:
                'Expenses ($_activeExpenseCount/${widget.allExpenses.length})',
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
            if (hasAddedContributors) _buildNewContributorsInfo(context),
            if (hasAddedContributors && hasRemovedContributors)
              const SizedBox(height: 8),
            if (hasRemovedContributors) _buildRemovedContributorsInfo(context),
            const SizedBox(height: 8),
            _buildInfoMessage(context),
            if (hasAddedContributors) ...[
              const SizedBox(height: 8),
              _buildSelectAllToggle(context),
            ],
            const SizedBox(height: 12),
            ...widget.allExpenses
                .map((item) => _buildExpenseItem(context, item)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoMessage(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final hasAdded = widget.addedContributors.isNotEmpty;
    final hasRemoved = widget.removedContributors.isNotEmpty;

    String message = '';
    if (hasAdded && hasRemoved) {
      message = '• Select expenses to include new tripmates in the split\n'
          '• Past expenses with removed tripmates are preserved for historical accuracy\n'
          '• Use the delete button to remove expenses you no longer need';
    } else if (hasAdded) {
      message = '• Select expenses to include new tripmates in the split\n'
          '• Unselected expenses will keep their current split\n'
          '• Use the delete button to remove expenses you no longer need';
    } else {
      message =
          '• Past expenses with removed tripmates are preserved for historical accuracy\n'
          '• Removed tripmates will be shown with a special indicator\n'
          '• Use the delete button to remove expenses you no longer need';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.info.withValues(alpha: 0.1)
            : AppColors.infoLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.infoLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 16,
              color: isLightTheme ? AppColors.info : AppColors.infoLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isLightTheme
                        ? Colors.grey.shade700
                        : Colors.grey.shade400,
                  ),
            ),
          ),
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
                'New tripmates added:',
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
                      avatar: const Icon(Icons.person_add, size: 14),
                      label: Text(
                        contributor.split('@').first,
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
        ],
      ),
    );
  }

  Widget _buildRemovedContributorsInfo(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.warningLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.warningLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_remove_rounded,
                size: 16,
                color:
                    isLightTheme ? AppColors.warning : AppColors.warningLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Tripmates removed:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isLightTheme
                          ? AppColors.warning
                          : AppColors.warningLight,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.removedContributors
                .map((contributor) => Chip(
                      avatar: const Icon(Icons.person_off, size: 14),
                      label: Text(
                        contributor,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      backgroundColor: isLightTheme
                          ? AppColors.warning.withValues(alpha: 0.2)
                          : AppColors.warningLight.withValues(alpha: 0.2),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          Text(
            'Past expenses are preserved for accuracy',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isLightTheme
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAllToggle(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Include new tripmates in:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  for (final item in widget.allExpenses) {
                    if (!item.isMarkedForDeletion) {
                      item.includeInSplitBy = false;
                    }
                  }
                });
                widget.onChanged();
              },
              child: Text(
                'None',
                style: TextStyle(
                  color: isLightTheme
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  for (final item in widget.allExpenses) {
                    if (!item.isMarkedForDeletion) {
                      item.includeInSplitBy = true;
                    }
                  }
                });
                widget.onChanged();
              },
              child: Text(
                'All',
                style: TextStyle(
                  color: isLightTheme
                      ? AppColors.brandPrimary
                      : AppColors.brandPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseItem(
      BuildContext context, EntityChange<ExpenseBearingTripEntity> item) {
    var expenseBearingTripEntity = item.modifiedEntity;
    final expense = expenseBearingTripEntity.expense;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final isMarkedForDeletion = item.isMarkedForDeletion;
    final hasAddedContributors = widget.addedContributors.isNotEmpty;

    // Check if any removed contributors are in this expense's splitBy
    final removedInExpense = widget.removedContributors
        .where((c) => expense.splitBy.contains(c))
        .toList();

    return Opacity(
      opacity: isMarkedForDeletion ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isMarkedForDeletion
              ? (isLightTheme
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.errorLight.withValues(alpha: 0.1))
              : item.includeInSplitBy
                  ? (isLightTheme
                      ? AppColors.success.withValues(alpha: 0.05)
                      : AppColors.successLight.withValues(alpha: 0.05))
                  : (isLightTheme
                      ? Colors.grey.shade100
                      : Colors.grey.shade800.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMarkedForDeletion
                ? (isLightTheme ? AppColors.error : AppColors.errorLight)
                : item.includeInSplitBy
                    ? (isLightTheme
                        ? AppColors.success
                        : AppColors.successLight)
                    : (isLightTheme
                        ? Colors.grey.shade300
                        : Colors.grey.shade700),
            width: (item.includeInSplitBy || isMarkedForDeletion) ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: hasAddedContributors && !isMarkedForDeletion
                  ? Checkbox(
                      value: item.includeInSplitBy,
                      onChanged: (value) {
                        setState(() {
                          item.includeInSplitBy = value ?? false;
                        });
                        widget.onChanged();
                      },
                      activeColor: isLightTheme
                          ? AppColors.success
                          : AppColors.successLight,
                    )
                  : Icon(
                      _getCategoryIcon(expenseBearingTripEntity.category.name),
                      color: isLightTheme
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
              title: Text(
                expenseBearingTripEntity.title.isNotEmpty
                    ? expenseBearingTripEntity.title
                    : 'Unnamed Expense',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isMarkedForDeletion
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (expense.description != null &&
                      expense.description!.isNotEmpty)
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
                        _getCategoryIcon(
                            expenseBearingTripEntity.category.name),
                        size: 14,
                        color: isLightTheme
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        expenseBearingTripEntity.category.name,
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
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  isMarkedForDeletion ? Icons.restore : Icons.delete_outline,
                  color: isMarkedForDeletion
                      ? (isLightTheme
                          ? AppColors.success
                          : AppColors.successLight)
                      : (isLightTheme ? AppColors.error : AppColors.errorLight),
                ),
                tooltip: isMarkedForDeletion ? 'Restore' : 'Delete',
                onPressed: () {
                  setState(() {
                    item.changeType = isMarkedForDeletion
                        ? EntityChangeType.update
                        : EntityChangeType.delete;
                  });
                  widget.onChanged();
                },
              ),
            ),
            if (!isMarkedForDeletion) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                child: _buildSplitByInfo(context, expense, removedInExpense),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: Text(
                    'This expense will be deleted',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLightTheme
                              ? AppColors.error
                              : AppColors.errorLight,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitByInfo(BuildContext context, ExpenseFacade expense,
      List<String> removedInExpense) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        Text(
          'Split: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        ...expense.splitBy.map((contributor) {
          final isRemoved = removedInExpense.contains(contributor);
          final displayName = contributor.split('@').first;

          if (isRemoved) {
            // Show removed contributor with special indicator
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : AppColors.warningLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isLightTheme
                      ? AppColors.warning.withValues(alpha: 0.3)
                      : AppColors.warningLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 12,
                    color: isLightTheme
                        ? AppColors.warning
                        : AppColors.warningLight,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLightTheme
                              ? AppColors.warning
                              : AppColors.warningLight,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            );
          } else {
            return Text(
              displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            );
          }
        }),
      ],
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
