import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
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

  // UI constants
  static const double _kBadgeHorizontalPadding = 12.0;
  static const double _kBadgeVerticalPadding = 8.0;
  static const double _kSectionSpacingLarge = 16.0;
  static const double _kSectionSpacingSmall = 12.0;

  ExpenseFacade get _expense => expenseLinkedTripEntity.expense;

  ExpenseEditor({
    super.key,
    required this.expenseLinkedTripEntity,
    required this.onExpenseUpdated,
  });

  @override
  Widget build(BuildContext context) {
    _descriptionFieldController.text = _expense.description ?? '';
    _titleEditingController.text = expenseLinkedTripEntity is! ExpenseFacade
        ? expenseLinkedTripEntity.toString()
        : _expense.title;
    _initializeCategoryNames(context);
    return context.isBigLayout
        ? _buildBigLayout(context)
        : _buildSmallLayout(context);
  }

  Column _buildSmallLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCategoryBadge(context),
        EditorTheme.createSection(
          context: context,
          child: _buildTitleField(context),
        ),
        _buildPaidOnSection(context),
        _buildDescriptionSection(context),
        _buildPaymentDetailsSection(context),
      ],
    );
  }

  Column _buildBigLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCategoryBadge(context),
        EditorTheme.createSection(
          context: context,
          child: _buildTitleField(context),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildPaidOnSection(context),
                  _buildDescriptionSection(context),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildPaymentDetailsSection(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Container(
            decoration: _buildBadgeDecoration(context),
            padding: const EdgeInsets.symmetric(
              horizontal: _kBadgeHorizontalPadding,
              vertical: _kBadgeVerticalPadding,
            ),
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
        const Expanded(child: SizedBox()),
      ],
    );
  }

  BoxDecoration _buildBadgeDecoration(BuildContext context) {
    final isLightTheme = context.isLightTheme;
    final cardBorderRadius =
        EditorTheme.getCardBorderRadius(context.isBigLayout);
    return BoxDecoration(
      gradient: EditorTheme.createPrimaryGradient(isLightTheme),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(cardBorderRadius - 2),
        bottomRight: const Radius.circular(16),
      ),
      boxShadow: [EditorTheme.createBadgeShadow(isLightTheme)],
    );
  }

  Widget _buildPaymentDetailsSection(BuildContext context) {
    return _wrapInSection(
      context,
      EditorTheme.createSectionHeader(
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
          _expense.currency = totalExpense.currency;
          onExpenseUpdated();
        },
        expenseFacade: _expense,
        isEditable: true,
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: TextFormField(
        controller: _descriptionFieldController,
        maxLines: null,
        decoration: EditorTheme.createTextFieldDecoration(
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

  Widget _buildPaidOnSection(BuildContext context) {
    return _wrapInSection(
      context,
      EditorTheme.createSectionHeader(
        context,
        icon: Icons.calendar_today_rounded,
        title: 'Paid On',
        iconColor:
            context.isLightTheme ? AppColors.success : AppColors.successLight,
      ),
      PlatformDatePicker(
        onDateSelected: (dateTime) {
          _expense.dateTime = dateTime;
          onExpenseUpdated();
        },
        selectedDate: _expense.dateTime,
      ),
    );
  }

  Widget _wrapInSection(BuildContext context, Widget header, Widget child) {
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(
              height: context.isBigLayout
                  ? _kSectionSpacingLarge
                  : _kSectionSpacingSmall),
          child,
        ],
      ),
    );
  }

  void _initializeCategoryNames(BuildContext context) {
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
    _categoryNames[ExpenseCategory.taxi] = context.localizations.taxi;
    _categoryNames[ExpenseCategory.other] = context.localizations.other;
  }

  Widget _buildTitleField(BuildContext context) {
    final isEditable = expenseLinkedTripEntity is ExpenseFacade;
    return TextField(
      controller: _titleEditingController,
      onChanged: isEditable
          ? (newTitle) {
              _expense.title = newTitle;
              onExpenseUpdated();
            }
          : null,
      decoration: EditorTheme.createTextFieldDecoration(
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

  const _CategoryPicker({
    required this.callback,
    required this.category,
    required this.categories,
  });

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
                    ),
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
                    ),
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
            },
    );
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
  ExpenseCategory.other: Icons.feed_rounded,
  ExpenseCategory.taxi: Icons.local_taxi_rounded,
};
