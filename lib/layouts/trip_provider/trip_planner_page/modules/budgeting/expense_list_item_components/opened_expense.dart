import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/date_picker.dart';
import 'package:wandrr/platform_elements/dialog.dart';
import 'package:wandrr/platform_elements/text.dart';

import 'constants.dart';
import 'expenditure_edit_tile.dart';

class OpenedExpenseListItem extends StatelessWidget {
  final ExpenseUpdator initialExpenseUpdator;
  final ExpenseUpdator _expenseUpdator;
  final Map<ExpenseCategory, String> categoryNames;
  final TextEditingController _descriptionFieldController =
      TextEditingController();
  final _canUpdateExpenseNotifier = ValueNotifier<bool>(false);
  final TextEditingController _titleEditingController = TextEditingController();
  final bool isLinkedExpense;

  TripManagementEvent Function(ExpenseUpdator expenseUpdator)
      updateEventCreator;

  OpenedExpenseListItem(
      {super.key,
      required this.initialExpenseUpdator,
      required this.isLinkedExpense,
      required this.updateEventCreator,
      required this.categoryNames})
      : _expenseUpdator = initialExpenseUpdator.clone();

  @override
  Widget build(BuildContext context) {
    _descriptionFieldController.text = _expenseUpdator.description ?? '';
    _titleEditingController.text = _expenseUpdator.title ?? '';
    _calculateExpenseUpdatePossibility();
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: Colors.white24,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                callback: isLinkedExpense
                                    ? null
                                    : (category) {
                                        _expenseUpdator.category = category;
                                        _calculateExpenseUpdatePossibility();
                                      },
                                category: _expenseUpdator.category!,
                                categories: categoryNames,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: PlatformDatePicker(
                                callBack: (dateTime) {
                                  _expenseUpdator.dateTime = dateTime;
                                },
                                initialDateTime: _expenseUpdator.dateTime,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: PlatformTextElements.createTextField(
                                  context: context,
                                  labelText:
                                      AppLocalizations.of(context)!.description,
                                  border: OutlineInputBorder(),
                                  controller: _descriptionFieldController,
                                  onTextChanged: (updatedDescription) {
                                    _expenseUpdator.description =
                                        updatedDescription;
                                  }),
                            ),
                            if (!isLinkedExpense)
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: PlatformGeoLocationAutoComplete(
                                  initialText:
                                      _expenseUpdator.location?.toString(),
                                  onLocationSelected: (location) {
                                    _expenseUpdator.location = location;
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
                              _expenseUpdator.paidBy = Map.from(paidBy);
                            }
                            if (splitBy != null) {
                              _expenseUpdator.splitBy = List.from(splitBy);
                            }
                            if (totalExpense != null) {
                              _expenseUpdator.totalExpense = CurrencyWithValue(
                                  currency: totalExpense.currency,
                                  amount: totalExpense.amount);
                            }
                            _calculateExpenseUpdatePossibility();
                          },
                          expenseUpdator: _expenseUpdator,
                          isEditable: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: _buildUpdateExpenseButton(),
            ),
            if (!isLinkedExpense)
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: _buildDeleteExpenseButton(context),
              )
          ],
        )
      ],
    );
  }

  Widget _createExpenseTitle(BuildContext context) {
    if (!isLinkedExpense) {
      return PlatformTextElements.createTextField(
          context: context,
          labelText: AppLocalizations.of(context)!.title,
          border: OutlineInputBorder(),
          controller: _titleEditingController,
          onTextChanged: (newTitle) {
            _expenseUpdator.title = newTitle;
            _calculateExpenseUpdatePossibility();
          });
    } else {
      return PlatformTextElements.createHeader(
          context: context, text: _expenseUpdator.title!);
    }
  }

  Widget _buildDeleteExpenseButton(BuildContext context) {
    return PlatformSubmitterFAB(
      icon: Icons.delete_rounded,
      backgroundColor: Colors.black,
      context: context,
      callback: () {
        var tripManagementBloc = BlocProvider.of<TripManagementBloc>(context);
        tripManagementBloc
            .add(UpdateExpense.delete(expenseUpdator: _expenseUpdator));
      },
    );
  }

  Widget _buildUpdateExpenseButton() {
    return ValueListenableBuilder(
        valueListenable: _canUpdateExpenseNotifier,
        builder: (context, canUpdateExpense, oldWidget) {
          return PlatformSubmitterFAB(
              icon: Icons.check_rounded,
              context: context,
              backgroundColor: Colors.black,
              callback: canUpdateExpense
                  ? () {
                      var tripManagementBloc =
                          BlocProvider.of<TripManagementBloc>(context);
                      if (_expenseUpdator.dataState ==
                          DataState.CreateNewUIEntry) {
                        tripManagementBloc.add(UpdateExpense.create(
                            expenseUpdator: _expenseUpdator));
                      } else {
                        tripManagementBloc
                            .add(updateEventCreator(_expenseUpdator));
                      }
                    }
                  : null);
        });
  }

  void _calculateExpenseUpdatePossibility() {
    var isTitleValid =
        _expenseUpdator.title != null && _expenseUpdator.title!.isNotEmpty;
    var isTotalExpenseValid = _expenseUpdator.totalExpense != null;
    var isPaidByValid =
        _expenseUpdator.paidBy != null && _expenseUpdator.paidBy!.isNotEmpty;
    var isSplitByValid =
        _expenseUpdator.splitBy != null && _expenseUpdator.splitBy!.isNotEmpty;
    var isCategoryValid = _expenseUpdator.category != null;
    var isExpenseValid = isTitleValid &&
        isTotalExpenseValid &&
        isPaidByValid &&
        isSplitByValid &&
        isCategoryValid;
    _canUpdateExpenseNotifier.value = isExpenseValid;
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
  var _widgetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return PlatformButtonElements.createTextButtonWithIcon(
        key: _widgetKey,
        text: AppLocalizations.of(context)!.category,
        iconData: iconsForCategories[widget.category]!,
        context: context,
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
              });
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
