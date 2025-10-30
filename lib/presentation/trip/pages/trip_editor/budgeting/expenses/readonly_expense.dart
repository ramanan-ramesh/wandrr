import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

import 'expenses_list_view.dart';

class ReadonlyExpenseListItem extends StatelessWidget {
  final ExpenseLinkedTripEntity expenseLinkedTripEntity;
  final Map<ExpenseCategory, String> categoryNames;

  ExpenseFacade get _expense => expenseLinkedTripEntity.expense;

  const ReadonlyExpenseListItem({
    required this.expenseLinkedTripEntity,
    required this.categoryNames,
    super.key,
  });

  String get _subTitle {
    var subTitle = '';
    if (_expense.dateTime != null) {
      subTitle +=
          'on ${_expense.dateTime!.monthFormat} ${_expense.dateTime!.day}';
    }
    return subTitle;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(right: 3.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _createExpenseCategory(),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: _createExpenseTitleSubtitle(context),
            ),
          ),
          ExpenditureEditTile(
            expenseUpdator: _expense,
            isEditable: false,
            callback: null,
          ),
        ],
      ),
    );
  }

  Widget _createExpenseTitleSubtitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: PlatformTextElements.createSubHeader(
              context: context,
              text: expenseLinkedTripEntity is ExpenseFacade
                  ? _expense.title
                  : expenseLinkedTripEntity.toString()),
        ),
        if (_subTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Text(_subTitle),
          ),
        if (_expense.description != null && _expense.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Text(
              "${context.localizations.description}\n${_expense.description!}",
              maxLines: null,
            ),
          )
      ],
    );
  }

  Widget _createExpenseCategory() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: IconButton(
              onPressed: null,
              icon: Icon(iconsForCategories[_expense.category])),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            categoryNames[_expense.category]!,
            maxLines: null,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
