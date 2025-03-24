import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/expense.dart';
import 'package:wandrr/data/trip/models/money.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/constants.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

import '../../../widgets/expense_editing/expenditure_edit_tile.dart';

class EditableExpenseListItem extends StatelessWidget {
  final UiElement<ExpenseFacade> expenseUiElement;
  final Map<ExpenseCategory, String> categoryNames;
  final TextEditingController _descriptionFieldController =
      TextEditingController();
  final ValueNotifier<bool> validityNotifier;
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
    var isBigLayout = context.isBigLayout;
    if (isBigLayout) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: _createExpenseTitle(context),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: _CategoryPicker(
                            callback: _isLinkedExpense
                                ? null
                                : (category) {
                                    expenseUiElement.element.category =
                                        category;
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
                                labelText: context.localizations.description),
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
                              selectedLocation:
                                  expenseUiElement.element.location,
                              onLocationSelected: (location) {
                                expenseUiElement.element.location = location;
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: ExpenditureEditTile(
                      callback: (paidBy, splitBy, totalExpense) {
                        expenseUiElement.element.paidBy = Map.from(paidBy);
                        expenseUiElement.element.splitBy = List.from(splitBy);
                        expenseUiElement.element.totalExpense = Money(
                            currency: totalExpense.currency,
                            amount: totalExpense.amount);
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: _createExpenseTitle(context),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            children: [
              Expanded(
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
              Expanded(
                child: PlatformDatePicker(
                  callBack: (dateTime) {
                    expenseUiElement.element.dateTime = dateTime;
                  },
                  initialDateTime: expenseUiElement.element.dateTime,
                ),
              ),
            ],
          ),
        ),
        if (expenseUiElement is! UiElementWithMetadata)
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: PlatformGeoLocationAutoComplete(
              selectedLocation: expenseUiElement.element.location,
              onLocationSelected: (location) {
                expenseUiElement.element.location = location;
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: TextFormField(
            controller: _descriptionFieldController,
            maxLines: null,
            decoration:
                InputDecoration(labelText: context.localizations.description),
            onChanged: (updatedDescription) {
              expenseUiElement.element.description = updatedDescription;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: ExpenditureEditTile(
            callback: (paidBy, splitBy, totalExpense) {
              expenseUiElement.element.paidBy = Map.from(paidBy);
              expenseUiElement.element.splitBy = List.from(splitBy);
              expenseUiElement.element.totalExpense = Money(
                  currency: totalExpense.currency, amount: totalExpense.amount);
              _calculateExpenseUpdatePossibility();
            },
            expenseUpdator: expenseUiElement.element,
            isEditable: true,
          ),
        ),
      ],
    );
  }

  Widget _createExpenseTitle(BuildContext context) {
    if (!_isLinkedExpense) {
      return TextField(
        controller: _titleEditingController,
        onChanged: (newTitle) {
          expenseUiElement.element.title = newTitle;
          _calculateExpenseUpdatePossibility();
        },
        decoration: InputDecoration(labelText: context.localizations.title),
      );
    } else {
      var title =
          (expenseUiElement as UiElementWithMetadata).metadata.toString();
      return PlatformTextElements.createSubHeader(
          context: context, text: title);
    }
  }

  void _calculateExpenseUpdatePossibility() {
    var isTitleValid = expenseUiElement.element.title.isNotEmpty;
    var isExpenseValid = isTitleValid && expenseUiElement.element.isValid();
    validityNotifier.value = isExpenseValid;
  }
}

class _CategoryPicker extends StatefulWidget {
  final Function(ExpenseCategory expenseCategory)? callback;
  final Map<ExpenseCategory, String> categories;
  final ExpenseCategory category;

  const _CategoryPicker(
      {required this.callback,
      required this.category,
      required this.categories});

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  late ExpenseCategory _category;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<ExpenseCategory>(
        value: _category,
        selectedItemBuilder: (context) => widget.categories.keys
            .map(
              (expenseCategory) => DropdownMenuItem<ExpenseCategory>(
                value: expenseCategory,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(iconsForCategories[expenseCategory]!),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(widget.categories[expenseCategory]!),
                      )
                    ],
                  ),
                ),
              ),
            )
            .toList(),
        items: widget.categories.keys
            .map(
              (expenseCategory) => DropdownMenuItem<ExpenseCategory>(
                value: expenseCategory,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(iconsForCategories[expenseCategory]!),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(widget.categories[expenseCategory]!),
                      )
                    ],
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: widget.callback == null
            ? null
            : (selectedExpenseCategory) {
                if (selectedExpenseCategory != null) {
                  _category = selectedExpenseCategory;
                  setState(() {});
                  widget.callback!(selectedExpenseCategory);
                }
              });
  }
}
