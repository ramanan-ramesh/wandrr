import 'package:flutter/material.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

import 'expenses_list_view.dart';

class ReadonlyExpenseListItem extends StatelessWidget {
  final ExpenseBearingTripEntity expenseBearingTripEntity;
  final Map<ExpenseCategory, String> categoryNames;

  const ReadonlyExpenseListItem({
    required this.expenseBearingTripEntity,
    required this.categoryNames,
    super.key,
  });

  ExpenseFacade get _expense => expenseBearingTripEntity.expense;

  Color _accentColor() {
    switch (expenseBearingTripEntity.category) {
      case ExpenseCategory.flights:
        return AppColors.info;
      case ExpenseCategory.lodging:
        return AppColors.success;
      case ExpenseCategory.food:
      case ExpenseCategory.drinks:
      case ExpenseCategory.groceries:
        return AppColors.warning;
      case ExpenseCategory.shopping:
      case ExpenseCategory.activities:
      case ExpenseCategory.sightseeing:
        return const Color(0xFF667EEA);
      default:
        return AppColors.neutral500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLightTheme;
    final accent = _accentColor();
    final dateText = _expense.dateTime != null
        ? '${_expense.dateTime!.monthFormat} ${_expense.dateTime!.day}'
        : '';
    final isStandalone = expenseBearingTripEntity is StandaloneExpense;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isLight ? 0.12 : 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconsForCategories[expenseBearingTripEntity.category],
              size: 18,
              color: accent,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  expenseBearingTripEntity.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dateText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLight
                              ? AppColors.neutral600
                              : AppColors.neutral400,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Right column: optional delete button stacked above the amount
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isStandalone) ...[
                _DeleteButton(
                    standaloneExpense:
                        expenseBearingTripEntity as StandaloneExpense),
                const SizedBox(height: 4),
              ],
              ExpenditureEditTile(
                expenseFacade: _expense,
                isEditable: false,
                callback: null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final StandaloneExpense standaloneExpense;

  const _DeleteButton({required this.standaloneExpense});

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          AppColors.error.withValues(alpha: context.isLightTheme ? 0.12 : 0.22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.addTripManagementEvent(
            UpdateTripEntity.delete(tripEntity: standaloneExpense)),
        child: const Padding(
          padding: EdgeInsets.all(5),
          child: Icon(
            Icons.delete_rounded,
            size: 14,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}
