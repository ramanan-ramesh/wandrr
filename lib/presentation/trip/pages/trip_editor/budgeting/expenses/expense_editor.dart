import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/app/widgets/option_grid_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';

class ExpenseEditor extends StatelessWidget {
  final ExpenseBearingTripEntity expenseBearingTripEntity;
  final VoidCallback onExpenseUpdated;
  final Map<ExpenseCategory, String> _categoryNames = {};
  final TextEditingController _descriptionFieldController =
      TextEditingController();
  final TextEditingController _titleEditingController = TextEditingController();

  // UI constants
  static const double _kBadgeHorizontalPadding = 12.0;
  static const double _kBadgeVerticalPadding = 8.0;
  static const double _kSectionSpacingSmall = 12.0;

  ExpenseFacade get _expense => expenseBearingTripEntity.expense;

  ExpenseEditor({
    required this.expenseBearingTripEntity,
    required this.onExpenseUpdated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    _descriptionFieldController.text = _expense.description ?? '';
    _titleEditingController.text = expenseBearingTripEntity.title;
    _initializeCategoryNames(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCategoryBadge(context),
        // Title + Paid On combined — saves one full section's worth of margins
        EditorTheme.createSection(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleField(context),
              const SizedBox(height: 10),
              EditorTheme.createSectionHeader(
                context,
                icon: Icons.calendar_today_rounded,
                title: 'Paid On',
                iconColor: context.isLightTheme
                    ? AppColors.success
                    : AppColors.successLight,
              ),
              const SizedBox(height: 8),
              PlatformDatePicker(
                onDateSelected: (dateTime) {
                  _expense.dateTime = dateTime;
                  onExpenseUpdated();
                },
                selectedDate: _expense.dateTime,
              ),
            ],
          ),
        ),
        _buildDescriptionSection(context),
        _buildPaymentDetailsSection(context),
      ],
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    final items = _categoryNames.entries
        .map((e) => OptionGridItem<ExpenseCategory>(
              value: e.key,
              icon: _iconsForCategories[e.key]!,
              label: e.value,
            ))
        .toList();

    return Row(
      children: [
        Flexible(
          child: Container(
            decoration: _buildBadgeDecoration(context),
            padding: const EdgeInsets.symmetric(
              horizontal: _kBadgeHorizontalPadding,
              vertical: _kBadgeVerticalPadding,
            ),
            child: OptionGridPicker<ExpenseCategory>(
              items: items,
              selectedValue: expenseBearingTripEntity.category,
              overlayTitle: context.localizations.category,
              onChanged: (category) {
                expenseBearingTripEntity.category = category;
                onExpenseUpdated();
              },
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
        EditorTheme.getCardBorderRadius(isBigLayout: context.isBigLayout);
    return BoxDecoration(
      gradient: EditorTheme.createPrimaryGradient(isLightTheme: isLightTheme),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(cardBorderRadius - 2),
        bottomRight: const Radius.circular(16),
      ),
      boxShadow: [EditorTheme.createBadgeShadow(isLightTheme: isLightTheme)],
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
    var note = Note(_expense.description ?? '');
    return EditorTheme.createSection(
      context: context,
      child: NoteEditor(
        note: note,
        onChanged: () {
          _expense.description = note.text;
          onExpenseUpdated();
        },
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
          const SizedBox(height: _kSectionSpacingSmall),
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
    final isEditable = expenseBearingTripEntity is StandaloneExpense;
    return TextField(
      key: const ValueKey('ExpenseEditor_Title_TextField'),
      controller: _titleEditingController,
      scrollPadding: const EdgeInsets.only(top: 24.0, bottom: 50),
      onChanged: isEditable
          ? (newTitle) {
              expenseBearingTripEntity.title = newTitle;
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
