import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/models/expense.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/constants.dart';

import '../expenditure_edit_tile/expenditure_edit_tile.dart';

class ReadonlyExpenseListItem extends StatelessWidget {
  final ExpenseFacade expenseModelFacade;

  String get _subTitle {
    var subTitle = '';
    if (expenseModelFacade.location != null) {
      subTitle += '@ ${expenseModelFacade.location.toString()}';
    }
    if (expenseModelFacade.dateTime != null) {
      subTitle +=
          ' on ${DateFormat.MMMM().format(expenseModelFacade.dateTime!).substring(0, 3)} ${expenseModelFacade.dateTime!.day}';
    }
    return subTitle;
  }

  final Map<ExpenseCategory, String> categoryNames;

  ReadonlyExpenseListItem(
      {super.key,
      required this.expenseModelFacade,
      required this.categoryNames});

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child:
                          Icon(iconsForCategories[expenseModelFacade.category]),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        categoryNames[expenseModelFacade.category]!,
                        maxLines: null,
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          VerticalDivider(),
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
                  if (expenseModelFacade.description != null &&
                      expenseModelFacade.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        "Description\n${expenseModelFacade.description!}",
                        maxLines: null,
                      ),
                    )
                ],
              ),
            ),
          ),
          VerticalDivider(),
          ExpenditureEditTile(
            expenseUpdator: expenseModelFacade,
            isEditable: false,
            callback: null,
          ),
        ],
      ),
    );
  }

  Text _createExpenseTitle(BuildContext context) {
    return PlatformTextElements.createSubHeader(
        context: context, text: expenseModelFacade.title);
  }
}
