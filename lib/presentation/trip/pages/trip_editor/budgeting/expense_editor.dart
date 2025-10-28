import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

class ExpenseEditor extends StatelessWidget {
  final ExpenseFacade expense;
  final VoidCallback onExpenseUpdated;
  final Map<ExpenseCategory, String> _categoryNames = {};
  final TextEditingController _descriptionFieldController =
      TextEditingController();
  final TextEditingController _titleEditingController = TextEditingController();

  ExpenseEditor(
      {super.key, required this.expense, required this.onExpenseUpdated});

  @override
  Widget build(BuildContext context) {
    _descriptionFieldController.text = expense.description ?? '';
    _titleEditingController.text = expense.title;
    _initializeUIComponentNames(context);
    var isBigLayout = context.isBigLayout;
    if (isBigLayout) {
      return _createBigLayoutEditor(context);
    }
    return _createSmallLayoutEditor(context);
  }

  Column _createSmallLayoutEditor(BuildContext context) {
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
                child: _createCategoryPicker(),
              ),
              Expanded(
                child: _createDatePicker(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: _createDescriptionField(context),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: _createExpenditureEditTile(),
        ),
      ],
    );
  }

  Column _createBigLayoutEditor(BuildContext context) {
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
                        child: _createCategoryPicker(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: _createDatePicker(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: _createDescriptionField(context),
                      ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: _createExpenditureEditTile(),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _createExpenditureEditTile() {
    return ExpenditureEditTile(
      callback: (paidBy, splitBy, totalExpense) {
        expense.paidBy = Map.from(paidBy);
        expense.splitBy = List.from(splitBy);
        expense.totalExpense =
            Money(currency: totalExpense.currency, amount: totalExpense.amount);
        onExpenseUpdated();
      },
      expenseUpdator: expense,
      isEditable: true,
    );
  }

  Widget _createDatePicker() {
    return PlatformDatePicker(
      callBack: (dateTime) {
        expense.dateTime = dateTime;
        onExpenseUpdated();
      },
      initialDateTime: expense.dateTime,
    );
  }

  Widget _createDescriptionField(BuildContext context) {
    return TextFormField(
      controller: _descriptionFieldController,
      maxLines: null,
      decoration: InputDecoration(labelText: context.localizations.description),
      onChanged: (updatedDescription) {
        expense.description = updatedDescription;
        onExpenseUpdated();
      },
    );
  }

  Widget _createCategoryPicker() {
    return _CategoryPicker(
      callback: (category) {
        expense.category = category;
        onExpenseUpdated();
      },
      category: expense.category,
      categories: _categoryNames,
    );
  }

  void _initializeUIComponentNames(BuildContext context) {
    _categoryNames[ExpenseCategory.flights] = context.localizations.flights;
    _categoryNames[ExpenseCategory.lodging] = context.localizations.lodging;
    _categoryNames[ExpenseCategory.carRental] = context.localizations.carRental;
    _categoryNames[ExpenseCategory.publicTransit] =
        context.localizations.publicTransit;
    _categoryNames[ExpenseCategory.food] = context.localizations.food;
    _categoryNames[ExpenseCategory.drinks] = context.localizations.drinks;
    _categoryNames[ExpenseCategory.sightseeing] =
        context.localizations.sightseeing;
    _categoryNames[ExpenseCategory.activities] =
        context.localizations.activities;
    _categoryNames[ExpenseCategory.shopping] = context.localizations.shopping;
    _categoryNames[ExpenseCategory.fuel] = context.localizations.fuel;
    _categoryNames[ExpenseCategory.groceries] = context.localizations.groceries;
    _categoryNames[ExpenseCategory.other] = context.localizations.other;
  }

  Widget _createExpenseTitle(BuildContext context) {
    return TextField(
      controller: _titleEditingController,
      onChanged: (newTitle) {
        expense.title = newTitle;
        onExpenseUpdated();
      },
      decoration: InputDecoration(labelText: context.localizations.title),
    );
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
                        child: Icon(_iconsForCategories[expenseCategory]!),
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
                        child: Icon(_iconsForCategories[expenseCategory]!),
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

const Map<ExpenseCategory, IconData> _iconsForCategories = {
  ExpenseCategory.flights: Icons.flight_rounded,
  ExpenseCategory.lodging: Icons.hotel_rounded,
  ExpenseCategory.carRental: Icons.car_rental_outlined,
  ExpenseCategory.publicTransit: Icons.emoji_transportation_rounded,
  ExpenseCategory.food: Icons.fastfood_rounded,
  ExpenseCategory.drinks: Icons.local_drink_rounded,
  ExpenseCategory.sightseeing: Icons.attractions_rounded,
  ExpenseCategory.activities: Icons.confirmation_num_rounded,
  ExpenseCategory.shopping: Icons.shopping_bag_rounded,
  ExpenseCategory.fuel: Icons.local_gas_station_rounded,
  ExpenseCategory.groceries: Icons.local_grocery_store_rounded,
  ExpenseCategory.other: Icons.feed_rounded
};
