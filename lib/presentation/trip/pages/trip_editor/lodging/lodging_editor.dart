import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
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
        _buildNotesSection(context),
        _buildPaymentDetailsSection(context),
      ],
    );
  }

  Widget _buildDatesSection(BuildContext context, dynamic tripMetadata) {
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.calendar_today_rounded,
            title: 'Check-in & Check-out',
            iconColor:
                context.isLightTheme ? AppColors.info : AppColors.infoLight,
          ),
          const SizedBox(height: 12),
          PlatformDateRangePicker(
            startDate: _lodging.checkinDateTime,
            endDate: _lodging.checkoutDateTime,
            callback: (newStartDate, newEndDate) {
              _lodging.checkinDateTime = newStartDate;
              _lodging.checkoutDateTime = newEndDate;
              widget.onLodgingUpdated();
              setState(() {});
            },
            firstDate: tripMetadata.startDate!,
            lastDate: tripMetadata.endDate!,
          ),
          const SizedBox(width: 8),
          if (_lodging.checkinDateTime != null &&
              _lodging.checkoutDateTime != null)
            _buildDurationIndicator(context),
        ],
      ),
    );
  }

  Widget _buildDurationIndicator(BuildContext context) {
    final startDate = _lodging.checkinDateTime!;
    final endDate = _lodging.checkoutDateTime!;
    final days = endDate.difference(startDate).inDays;
    final isLightTheme = context.isLightTheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.info.withValues(alpha: 0.2),
              AppColors.infoLight.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLightTheme
                ? AppColors.info.withValues(alpha: 0.3)
                : AppColors.infoLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              size: 18,
              color: isLightTheme ? AppColors.info : AppColors.infoLight,
            ),
            const SizedBox(width: 8),
            Text(
              '$days ${days == 1 ? 'day' : 'days'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLightTheme ? AppColors.info : AppColors.infoLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationSection(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: TextFormField(
        decoration: EditorTheme.createTextFieldDecoration(
          labelText: '${context.localizations.confirmation} ID',
          prefixIcon: Icons.tag,
        ),
        initialValue: _lodging.confirmationId,
        textInputAction: TextInputAction.next,
        onChanged: (confirmationId) {
          _lodging.confirmationId = confirmationId;
          widget.onLodgingUpdated();
        },
      ),
    );
  }

  Widget _buildPaymentDetailsSection(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.account_balance_wallet,
            title: context.localizations.expenses,
            iconColor: context.isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight,
          ),
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

  Widget _buildNotesSection(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
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
      decoration: EditorTheme.createTextFieldDecoration(
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
