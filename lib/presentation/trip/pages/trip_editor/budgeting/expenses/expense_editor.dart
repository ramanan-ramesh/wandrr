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
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';

class ExpenseEditor extends StatefulWidget {
  final ExpenseLinkedTripEntity expenseLinkedTripEntity;
  final VoidCallback onExpenseUpdated;

  const ExpenseEditor({
    super.key,
    required this.expenseLinkedTripEntity,
    required this.onExpenseUpdated,
  });

  @override
  State<ExpenseEditor> createState() => _ExpenseEditorState();
}

class _ExpenseEditorState extends State<ExpenseEditor> {
  final Map<ExpenseCategory, String> _categoryNames = {};
  late TextEditingController _descriptionFieldController;
  late TextEditingController _titleEditingController;

  // Store the expense locally for immutable updates
  late Expense _currentExpense;

  // UI constants
  static const double _kBadgeHorizontalPadding = 12.0;
  static const double _kBadgeVerticalPadding = 8.0;
  static const double _kSectionSpacingLarge = 16.0;
  static const double _kSectionSpacingSmall = 12.0;

  @override
  void initState() {
    super.initState();
    _currentExpense = widget.expenseLinkedTripEntity.expense;
    _descriptionFieldController =
        TextEditingController(text: _currentExpense.description ?? '');
    _titleEditingController = TextEditingController(
      text: widget.expenseLinkedTripEntity is! Expense
          ? widget.expenseLinkedTripEntity.toString()
          : _currentExpense.title,
    );
  }

  @override
  void didUpdateWidget(ExpenseEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenseLinkedTripEntity != widget.expenseLinkedTripEntity) {
      _currentExpense = widget.expenseLinkedTripEntity.expense;
      _descriptionFieldController.text = _currentExpense.description ?? '';
      _titleEditingController.text = widget.expenseLinkedTripEntity is! Expense
          ? widget.expenseLinkedTripEntity.toString()
          : _currentExpense.title;
    }
  }

  @override
  void dispose() {
    _descriptionFieldController.dispose();
    _titleEditingController.dispose();
    super.dispose();
  }

  void _updateExpense(Expense updated) {
    setState(() {
      _currentExpense = updated;
    });
    // Update the entity's expense with the new value
    // Since ExpenseLinkedTripEntity has a getter, we need to check if we can update it
    // For now, we rely on the parent to handle this via the callback
    widget.onExpenseUpdated();
  }

  @override
  Widget build(BuildContext context) {
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
                _updateExpense(_currentExpense.copyWith(category: category));
              },
              category: _currentExpense.category,
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
          _updateExpense(_currentExpense.copyWith(
            paidBy: Map.from(paidBy),
            splitBy: List.from(splitBy),
            currency: totalExpense.currency,
          ));
        },
        expenseFacade: _currentExpense,
        isEditable: true,
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    var note = Note(_descriptionFieldController.text);
    return EditorTheme.createSection(
      context: context,
      child: NoteEditor(
        note: note,
        onChanged: () {
          _updateExpense(_currentExpense.copyWith(description: note.text));
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
          _updateExpense(_currentExpense.copyWith(dateTime: dateTime));
        },
        selectedDate: _currentExpense.dateTime,
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
    final isEditable = widget.expenseLinkedTripEntity is Expense;
    return TextField(
      controller: _titleEditingController,
      onChanged: isEditable
          ? (newTitle) {
              _updateExpense(_currentExpense.copyWith(title: newTitle));
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
  void didUpdateWidget(_CategoryPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _category = widget.category;
    }
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
