import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';

import 'date_time_selector.dart';
import 'stay_details.dart';

class LodgingEditor extends StatefulWidget {
  final Lodging initialLodging;
  final void Function(Lodging updated) onLodgingUpdated;

  const LodgingEditor({
    required this.initialLodging,
    required this.onLodgingUpdated,
    super.key,
  });

  @override
  State<LodgingEditor> createState() => _LodgingEditorState();
}

class _LodgingEditorState extends State<LodgingEditor>
    with SingleTickerProviderStateMixin {
  late Lodging _lodging;

  @override
  void initState() {
    super.initState();
    _lodging = widget.initialLodging;
  }

  @override
  void didUpdateWidget(covariant LodgingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLodging != widget.initialLodging) {
      _lodging = widget.initialLodging;
      setState(() {});
    }
  }

  void _updateLodging(Lodging updated) {
    setState(() {
      _lodging = updated;
    });
    widget.onLodgingUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    final tripMetadata = context.activeTrip.tripMetadata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StayDetails(
          lodging: _lodging,
          onLocationUpdated: (Location? location) {
            if (location != null) {
              _updateLodging(_lodging.copyWith(location: location));
            } else {
              // Create draft to allow null location
              _updateLodging(Lodging.draft(
                tripId: _lodging.tripId,
                id: _lodging.id,
                expense: _lodging.expense,
                location: null,
                checkinDateTime: _lodging.checkinDateTime,
                checkoutDateTime: _lodging.checkoutDateTime,
                confirmationId: _lodging.confirmationId,
                notes: _lodging.notes,
              ));
            }
          },
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
          _updateLodging(_lodging.copyWith(checkinDateTime: newDateTime));
        },
        onCheckoutChanged: (newDateTime) {
          _updateLodging(_lodging.copyWith(checkoutDateTime: newDateTime));
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
          _updateLodging(_lodging.copyWith(confirmationId: confirmationId));
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
              _updateLodging(_lodging.copyWith(
                expense: _lodging.expense.copyWith(
                  paidBy: Map.from(paidBy),
                  splitBy: List.from(splitBy),
                  currency: totalExpense.currency,
                ),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return EditorTheme.createSection(
      context: context,
      child: _buildNotesField(context),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    var note = Note(_lodging.notes ?? '');
    return NoteEditor(
        note: note,
        onChanged: () {
          _updateLodging(_lodging.copyWith(notes: note.text));
        });
  }
}
