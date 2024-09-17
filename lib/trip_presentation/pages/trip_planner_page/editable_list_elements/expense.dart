import 'package:flutter/material.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/date_picker.dart';
import 'package:wandrr/app_presentation/widgets/dialog.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/models/expense.dart';
import 'package:wandrr/trip_data/models/money.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/budgeting/constants.dart';
import 'package:wandrr/trip_presentation/widgets/geo_location_auto_complete.dart';

import '../expenditure_edit_tile.dart';

class EditableExpenseListItem extends StatelessWidget {
  final UiElement<ExpenseFacade> expenseUiElement;
  final Map<ExpenseCategory, String> categoryNames;
  final TextEditingController _descriptionFieldController =
      TextEditingController();
  ValueNotifier<bool> validityNotifier;
  final TextEditingController _titleEditingController = TextEditingController();

  bool get _isLinkedExpense {
    return expenseUiElement is UiElementWithMetadata;
  }

  EditableExpenseListItem(
      {super.key,
      required this.expenseUiElement,
      required this.categoryNames,
      required this.validityNotifier}) {
    _calculateExpenseUpdatePossibility();
  }

  @override
  Widget build(BuildContext context) {
    _descriptionFieldController.text =
        expenseUiElement.element.description ?? '';
    _titleEditingController.text = expenseUiElement.element.title;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(5.0),
          child: _createExpenseTitle(context),
        ),
        Padding(
          padding: EdgeInsets.all(5.0),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(5.0),
                        child: _CategoryPicker(
                          callback: _isLinkedExpense
                              ? null
                              : (category) {
                                  expenseUiElement.element.category = category;
                                  _calculateExpenseUpdatePossibility();
                                },
                          category: expenseUiElement.element.category,
                          categories: categoryNames,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: PlatformDatePicker(
                          callBack: (dateTime) {
                            expenseUiElement.element.dateTime = dateTime;
                          },
                          initialDateTime: expenseUiElement.element.dateTime,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: TextFormField(
                          controller: _descriptionFieldController,
                          maxLines: null,
                          decoration: InputDecoration(
                              labelText: context.withLocale().description),
                          onChanged: (updatedDescription) {
                            expenseUiElement.element.description =
                                updatedDescription;
                          },
                        ),
                      ),
                      if (expenseUiElement is! UiElementWithMetadata)
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: PlatformGeoLocationAutoComplete(
                            initialText:
                                expenseUiElement.element.location?.toString(),
                            onLocationSelected: (location) {
                              expenseUiElement.element.location = location;
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              VerticalDivider(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: ExpenditureEditTile(
                    callback: (paidBy, splitBy, totalExpense) {
                      if (paidBy != null) {
                        expenseUiElement.element.paidBy = Map.from(paidBy);
                      }
                      if (splitBy != null) {
                        expenseUiElement.element.splitBy = List.from(splitBy);
                      }
                      if (totalExpense != null) {
                        expenseUiElement.element.totalExpense = Money(
                            currency: totalExpense.currency,
                            amount: totalExpense.amount);
                      }
                      _calculateExpenseUpdatePossibility();
                    },
                    expenseUpdator: expenseUiElement.element,
                    isEditable: true,
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _createExpenseTitle(BuildContext context) {
    if (!_isLinkedExpense) {
      return PlatformTextElements.createTextField(
          context: context,
          labelText: context.withLocale().title,
          controller: _titleEditingController,
          onTextChanged: (newTitle) {
            expenseUiElement.element.title = newTitle;
            _calculateExpenseUpdatePossibility();
          });
    } else {
      var title =
          (expenseUiElement as UiElementWithMetadata).metadata.toString();
      return PlatformTextElements.createHeader(context: context, text: title);
    }
  }

  void _calculateExpenseUpdatePossibility() {
    var isTitleValid = expenseUiElement.element.title.isNotEmpty;
    var isPaidByValid = expenseUiElement.element.paidBy.isNotEmpty;
    var isSplitByValid = expenseUiElement.element.splitBy.isNotEmpty;
    var isExpenseValid = isTitleValid && isPaidByValid && isSplitByValid;
    validityNotifier.value = isExpenseValid;
  }
}

class _CategoryPicker extends StatefulWidget {
  final Function(ExpenseCategory expenseCategory)? callback;
  final Map<ExpenseCategory, String> categories;
  ExpenseCategory category;

  _CategoryPicker(
      {super.key,
      required this.callback,
      required this.category,
      required this.categories});

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  final _widgetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: _widgetKey,
      icon: Icon(iconsForCategories[widget.category]!),
      onPressed: widget.callback == null
          ? null
          : () {
              PlatformDialogElements.showAlignedDialog(
                  context: context,
                  widgetBuilder: (context) => Material(
                        elevation: 5.0,
                        child: Container(
                          width: 200,
                          color: Colors.white24,
                          child: GridView.extent(
                            shrinkWrap: true,
                            maxCrossAxisExtent: 75,
                            mainAxisSpacing: 5,
                            crossAxisSpacing: 5,
                            children: widget.categories.keys
                                .map((e) => _createCategory(e, context))
                                .toList(),
                          ),
                        ),
                      ),
                  widgetKey: _widgetKey);
            },
      label: Text(context.withLocale().category),
    );
  }

  Widget _createCategory(
      ExpenseCategory expenseCategory, BuildContext dialogContext) {
    return InkWell(
      splashColor: Colors.white,
      onTap: () {
        setState(() {
          widget.category = expenseCategory;
          if (widget.callback != null) {
            widget.callback!(expenseCategory);
            Navigator.of(dialogContext).pop();
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Icon(
                iconsForCategories[expenseCategory],
                color: Colors.black,
              ),
            ),
            Text(
              widget.categories[expenseCategory]!,
              style: TextStyle(color: Colors.black),
            )
          ],
        ),
      ),
    );
  }
}
