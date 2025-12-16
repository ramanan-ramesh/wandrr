import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

import 'date_time_selector.dart';
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
      child: DateTimeSelector(
        checkinDateTime: _lodging.checkinDateTime,
        checkoutDateTime: _lodging.checkoutDateTime,
        firstDate: tripMetadata.startDate!,
        lastDate: tripMetadata.endDate!,
        location: _lodging.location,
        onCheckinChanged: (newDateTime) {
          setState(() {
            _lodging.checkinDateTime = newDateTime;
          });
          widget.onLodgingUpdated();
        },
        onCheckoutChanged: (newDateTime) {
          setState(() {
            _lodging.checkoutDateTime = newDateTime;
          });
          widget.onLodgingUpdated();
        },
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
            expenseFacade: _lodging.expense,
            isEditable: true,
            callback: (paidBy, splitBy, totalExpense) {
              _lodging.expense.paidBy = Map.from(paidBy);
              _lodging.expense.splitBy = List.from(splitBy);
              _lodging.expense.currency = totalExpense.currency;
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
