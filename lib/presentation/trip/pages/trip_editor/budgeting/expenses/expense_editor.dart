import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

class ExpenseEditor extends StatelessWidget {
  final ExpenseLinkedTripEntity expenseLinkedTripEntity;
  final VoidCallback onExpenseUpdated;
  final Map<ExpenseCategory, String> _categoryNames = {};
  final TextEditingController _descriptionFieldController =
      TextEditingController();
  final TextEditingController _titleEditingController = TextEditingController();

  ExpenseFacade get _expense => expenseLinkedTripEntity.expense;

  ExpenseEditor(
      {super.key,
      required this.expenseLinkedTripEntity,
      required this.onExpenseUpdated});

  @override
  Widget build(BuildContext context) {
    _descriptionFieldController.text = _expense.description ?? '';
    _titleEditingController.text = expenseLinkedTripEntity is! ExpenseFacade
        ? expenseLinkedTripEntity.toString()
        : _expense.title;
    _initializeUIComponentNames(context);
    var isBigLayout = context.isBigLayout;
    if (isBigLayout) {
      return _createBigLayoutEditor(context);
    }
    return _createSmallLayoutEditor(context);
  }

  Column _createSmallLayoutEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTransitTypeBadge(context, context.isLightTheme,
            EditorTheme.getCardBorderRadius(context.isBigLayout)),
        EditorTheme.buildSection(
          context: context,
          child: _createExpenseTitle(context),
        ),
        _createPaidOnSection(context),
        _createDescriptionSection(context),
        _createPaymentDetailsSection(context),
      ],
    );
  }

  Column _createBigLayoutEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTransitTypeBadge(context, context.isLightTheme,
            EditorTheme.getCardBorderRadius(context.isBigLayout)),
        EditorTheme.buildSection(
          context: context,
          child: _createExpenseTitle(context),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _createPaidOnSection(context),
                  _createDescriptionSection(context),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: _createPaymentDetailsSection(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransitTypeBadge(
    BuildContext context,
    bool isLightTheme,
    double cardBorderRadius,
  ) {
    return Row(
      children: [
        Flexible(
          child: Container(
            decoration: _buildBadgeDecoration(isLightTheme, cardBorderRadius),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _CategoryPicker(
              callback: (category) {
                _expense.category = category;
                onExpenseUpdated();
              },
              category: _expense.category,
              categories: _categoryNames,
            ),
          ),
        ),
        Expanded(child: Container()),
      ],
    );
  }

  BoxDecoration _buildBadgeDecoration(
      bool isLightTheme, double cardBorderRadius) {
    return BoxDecoration(
      gradient: EditorTheme.buildPrimaryGradient(isLightTheme),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(cardBorderRadius - 2),
        bottomRight: const Radius.circular(16),
      ),
      boxShadow: [EditorTheme.buildBadgeShadow(isLightTheme)],
    );
  }

  Widget _createPaymentDetailsSection(BuildContext context) {
    return _createSection(
      context,
      EditorTheme.buildSectionHeader(
        context,
        icon: Icons.payments_rounded,
        title: 'Payment Details',
        iconColor:
            context.isLightTheme ? AppColors.error : AppColors.errorLight,
        useLargeText: context.isBigLayout,
      ),
      ExpenditureEditTile(
        callback: (paidBy, splitBy, totalExpense) {
          _expense.paidBy = Map.from(paidBy);
          _expense.splitBy = List.from(splitBy);
          _expense.totalExpense = Money(
              currency: totalExpense.currency, amount: totalExpense.amount);
          onExpenseUpdated();
        },
        expenseUpdator: _expense,
        isEditable: true,
      ),
    );
  }

  Widget _createDescriptionSection(BuildContext context) {
    return EditorTheme.buildSection(
      context: context,
      child: TextFormField(
        controller: _descriptionFieldController,
        maxLines: null,
        decoration: EditorTheme.buildTextFieldDecoration(
          labelText: context.localizations.description,
          hintText: 'Enter expense details...',
          alignLabelWithHint: true,
        ),
        onChanged: (updatedDescription) {
          _expense.description = updatedDescription;
          onExpenseUpdated();
        },
      ),
    );
  }

  Widget _createPaidOnSection(BuildContext context) {
    return _createSection(
      context,
      EditorTheme.buildSectionHeader(
        context,
        icon: Icons.calendar_today_rounded,
        title: 'Paid On',
        iconColor:
            context.isLightTheme ? AppColors.success : AppColors.successLight,
      ),
      PlatformDatePicker(
        callBack: (dateTime) {
          _expense.dateTime = dateTime;
          onExpenseUpdated();
        },
        initialDateTime: _expense.dateTime,
      ),
    );
  }

  Widget _createSection(
      BuildContext context, Widget sectionHeader, Widget child) {
    return EditorTheme.buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader,
          SizedBox(height: context.isBigLayout ? 16 : 12),
          child,
        ],
      ),
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
    final isEditable = expenseLinkedTripEntity is ExpenseFacade;
    return TextField(
      controller: _titleEditingController,
      onChanged: isEditable
          ? (newTitle) {
              _expense.title = newTitle;
              onExpenseUpdated();
            }
          : null,
      decoration: EditorTheme.buildTextFieldDecoration(
        labelText: context.localizations.title,
        hintText: 'Enter expense name...',
      ),
      enabled: isEditable,
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
        isExpanded: true,
        // Fix for RenderFlex overflow
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
