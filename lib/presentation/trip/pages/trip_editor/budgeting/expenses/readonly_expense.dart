import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

import 'expenses_list_view.dart';

class ReadonlyExpenseListItem extends StatelessWidget {
  final ExpenseBearingTripEntity expenseBearingTripEntity;
  final Map<ExpenseCategory, String> categoryNames;

  ReadonlyExpenseListItem({
    required this.expenseBearingTripEntity,
    required this.categoryNames,
    super.key,
  });

  ExpenseFacade get _expense => expenseBearingTripEntity.expense;

  // UI constants
  static const double _kIconColumnWidth = 70.0;
  static const double _kOuterPadding = 12.0;
  static const double _kInnerPadding = 2.0;

  String get _subTitle {
    if (_expense.dateTime == null) return '';
    return 'Paid on ${_expense.dateTime!.monthFormat} ${_expense.dateTime!.day}';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.all(_kOuterPadding),
        child: Row(
          children: [
            SizedBox(
              width: _kIconColumnWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 3.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: IconButton(
                    onPressed: null,
                    icon: Icon(
                        iconsForCategories[expenseBearingTripEntity.category]),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: _buildTitleSubtitle(context),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (expenseBearingTripEntity is StandaloneExpense)
                  _DeleteButton(
                      standaloneExpense:
                          expenseBearingTripEntity as StandaloneExpense),
                ExpenditureEditTile(
                  expenseFacade: _expense,
                  isEditable: false,
                  callback: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSubtitle(BuildContext context) {
    final description = _expense.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(_kInnerPadding),
          child: PlatformTextElements.createSubHeader(
            context: context,
            text: expenseBearingTripEntity.title,
          ),
        ),
        if (_subTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(_kInnerPadding),
            child: Text(_subTitle),
          ),
        if (description != null && description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(_kInnerPadding),
            child: Text(
              "${context.localizations.description}\n$description",
              maxLines: null,
            ),
          ),
      ],
    );
  }
}

/// Delete button for event
class _DeleteButton extends StatelessWidget {
  final StandaloneExpense standaloneExpense;

  const _DeleteButton({required this.standaloneExpense});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.addTripManagementEvent(
          UpdateTripEntity.delete(tripEntity: standaloneExpense)),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.isLightTheme
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.error.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.delete_outline,
          size: 18,
          color: AppColors.error,
        ),
      ),
    );
  }
}
