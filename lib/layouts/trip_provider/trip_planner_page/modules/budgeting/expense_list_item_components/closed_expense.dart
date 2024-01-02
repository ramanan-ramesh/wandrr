import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/platform_elements/text.dart';

import 'constants.dart';
import 'expenditure_edit_tile.dart';

class ClosedExpenseListItem extends StatelessWidget {
  final ExpenseUpdator expenseUpdator;
  String get _subTitle {
    var subTitle = '';
    if (expenseUpdator.location != null) {
      subTitle += '@ ${expenseUpdator.location.toString()}';
    }
    if (expenseUpdator.dateTime != null) {
      subTitle +=
          ' on ${DateFormat.MMMM().format(expenseUpdator.dateTime!).substring(0, 3)} ${expenseUpdator.dateTime!.day}';
    }
    return subTitle;
  }

  final Map<ExpenseCategory, String> categoryNames;
  ClosedExpenseListItem(
      {super.key, required this.expenseUpdator, required this.categoryNames});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.black12,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Icon(iconsForCategories[expenseUpdator.category!]),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        categoryNames[expenseUpdator.category!]!,
                        maxLines: 2,
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: 2.5,
              color: Colors.white,
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: _createExpenseTitle(context),
                    ),
                    if (_subTitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text(_subTitle),
                      ),
                    if (expenseUpdator.description != null &&
                        expenseUpdator.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text(
                          "Description\n${expenseUpdator.description!}",
                          maxLines: 3,
                        ),
                      )
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: 2.5,
              color: Colors.white,
            ),
            ExpenditureEditTile(
              expenseUpdator: expenseUpdator,
              isEditable: false,
              callback: null,
            ),
          ],
        ),
      ),
    );
  }

  Text _createExpenseTitle(BuildContext context) {
    return PlatformTextElements.createSubHeader(
        context: context, text: expenseUpdator.title!);
  }
}
