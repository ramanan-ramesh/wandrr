import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

import 'stay_details.dart';

class LodgingEditor extends StatefulWidget {
  final LodgingFacade lodging;
  final void Function() onLodgingUpdated;

  const LodgingEditor({
    required this.lodging,
    required this.onLodgingUpdated,
    super.key,
  });

  @override
  State<LodgingEditor> createState() => _LodgingEditorState();
}

class _LodgingEditorState extends State<LodgingEditor>
    with SingleTickerProviderStateMixin {
  LodgingFacade get _lodging => widget.lodging;

  @override
  void didUpdateWidget(covariant LodgingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lodging != _lodging) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripMetadata = context.activeTrip.tripMetadata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StayDetails(
          lodging: _lodging,
          onLocationUpdated: widget.onLodgingUpdated,
        ),
        _buildDatesSection(context, tripMetadata),
        _buildConfirmationSection(context),
        _buildExpenseSection(context),
        _buildNotesSection(context),
      ],
    );
  }

  Widget _buildDatesSection(BuildContext context, dynamic tripMetadata) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return EditorTheme.buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.buildSectionHeader(
            context,
            icon: Icons.calendar_today_rounded,
            title: 'Check-in & Check-out',
            iconColor: isLightTheme ? AppColors.info : AppColors.infoLight,
          ),
          const SizedBox(height: 12),
          PlatformDateRangePicker(
            startDate: _lodging.checkinDateTime,
            endDate: _lodging.checkoutDateTime,
            callback: (newStartDate, newEndDate) {
              _lodging.checkinDateTime = newStartDate;
              _lodging.checkoutDateTime = newEndDate;
              widget.onLodgingUpdated();
            },
            firstDate: tripMetadata.startDate!,
            lastDate: tripMetadata.endDate!,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationSection(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.buildSectionHeader(
            context,
            icon: Icons.confirmation_number_outlined,
            title: context.localizations.confirmation,
            iconColor: isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight,
          ),
          const SizedBox(height: 12),
          _buildConfirmationField(context),
        ],
      ),
    );
  }

  Widget _buildConfirmationField(BuildContext context) {
    return TextFormField(
      decoration: EditorTheme.buildTextFieldDecoration(
        labelText: '${context.localizations.confirmation} #',
        hintText: 'Enter confirmation number',
        prefixIcon: Icons.tag,
      ),
      initialValue: _lodging.confirmationId,
      textInputAction: TextInputAction.next,
      onChanged: (confirmationId) {
        _lodging.confirmationId = confirmationId;
        widget.onLodgingUpdated();
      },
    );
  }

  Widget _buildExpenseSection(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExpenseHeader(context, isLightTheme),
          const SizedBox(height: 12),
          ExpenditureEditTile(
            expenseUpdator: _lodging.expense,
            isEditable: true,
            callback: (paidBy, splitBy, totalExpense) {
              _lodging.expense.paidBy = Map.from(paidBy);
              _lodging.expense.splitBy = List.from(splitBy);
              _lodging.expense.totalExpense = totalExpense;
              widget.onLodgingUpdated();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseHeader(BuildContext context, bool isLightTheme) {
    return Row(
      children: [
        EditorTheme.buildIconContainer(
          icon: Icons.account_balance_wallet,
          gradientColors: [AppColors.warning, AppColors.warningLight],
          size: EditorTheme.iconSizeSmall,
        ),
        const SizedBox(width: 12),
        Text(
          context.localizations.expenses,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLightTheme
                    ? AppColors.brandSecondary
                    : AppColors.neutral100,
              ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.buildSectionHeader(
            context,
            icon: Icons.notes_outlined,
            title: context.localizations.notes,
            iconColor: isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight,
          ),
          const SizedBox(height: 12),
          _buildNotesField(context),
        ],
      ),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return TextFormField(
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: EditorTheme.buildTextFieldDecoration(
        labelText: context.localizations.notes,
        hintText: 'Add any additional notes...',
        alignLabelWithHint: true,
      ),
      initialValue: _lodging.notes,
      maxLines: 4,
      minLines: 3,
      textInputAction: TextInputAction.done,
      onChanged: (newNotes) {
        _lodging.notes = newNotes;
        widget.onLodgingUpdated();
      },
    );
  }
}
