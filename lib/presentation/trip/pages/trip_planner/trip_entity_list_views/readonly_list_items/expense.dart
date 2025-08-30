import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/constants.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

class ReadonlyExpenseListItem extends StatelessWidget {
  final ExpenseFacade expenseModelFacade;

  String get _subTitle {
    var subTitle = '';
    if (expenseModelFacade.location != null) {
      subTitle += '@ ${expenseModelFacade.location}';
    }
    if (expenseModelFacade.dateTime != null) {
      subTitle +=
          ' on ${DateFormat.MMMM().format(expenseModelFacade.dateTime!).substring(0, 3)} ${expenseModelFacade.dateTime!.day}';
    }
    return subTitle;
  }

  final Map<ExpenseCategory, String> categoryNames;

  const ReadonlyExpenseListItem(
      {required this.expenseModelFacade,
      required this.categoryNames,
      super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _createExpenseCategory(),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
              child: _createExpenseTitleSubtitle(context),
            ),
          ),
          ExpenditureEditTile(
            expenseUpdator: expenseModelFacade,
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
              context: context, text: expenseModelFacade.title),
        ),
        if (_subTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Text(_subTitle),
          ),
        if (expenseModelFacade.description != null &&
            expenseModelFacade.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Text(
              "${context.localizations.description}\n${expenseModelFacade.description!}",
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
              icon: Icon(iconsForCategories[expenseModelFacade.category])),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            categoryNames[expenseModelFacade.category]!,
            maxLines: null,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
