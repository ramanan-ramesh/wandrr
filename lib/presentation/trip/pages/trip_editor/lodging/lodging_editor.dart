import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/location/location_timezone_date_time.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';
import 'package:wandrr/presentation/trip/widgets/stay_date_time_range_editor.dart';

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

class _LodgingEditorState extends State<LodgingEditor> {
  LodgingFacade get _lodging => widget.lodging;
  late LocationFacade? _lastKnownLocation;

  @override
  void initState() {
    super.initState();
    _lastKnownLocation = _lodging.location;
  }

  @override
  Widget build(BuildContext context) {
    final tripMetadata = context.activeTrip.tripMetadata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StayDetails(
          lodging: _lodging,
          onLocationUpdated: () {
            final newLocation = _lodging.location;
            setState(() {
              if (_lodging.checkinDateTime != null) {
                _lodging.checkinDateTime =
                    LocationTimezoneDateTime.retargetStoredDateTime(
                  storedDateTime: _lodging.checkinDateTime!,
                  oldLocation: _lastKnownLocation,
                  newLocation: newLocation,
                );
              }
              if (_lodging.checkoutDateTime != null) {
                _lodging.checkoutDateTime =
                    LocationTimezoneDateTime.retargetStoredDateTime(
                  storedDateTime: _lodging.checkoutDateTime!,
                  oldLocation: _lastKnownLocation,
                  newLocation: newLocation,
                );
              }
              _lastKnownLocation = newLocation;
            });
            widget.onLodgingUpdated();
          },
        ),
        _buildDatesSection(context, tripMetadata),
        _buildConfirmationSection(context),
        _buildNotesSection(context),
        _buildPaymentDetailsSection(context),
      ],
    );
  }

  Widget _buildDatesSection(
      BuildContext context, TripMetadataFacade tripMetadata) {
    return EditorTheme.createSection(
      context: context,
      child: StayDateTimeRangeEditor(
        checkinDateTime: _lodging.checkinDateTime,
        checkoutDateTime: _lodging.checkoutDateTime,
        tripStartDate: tripMetadata.startDate!,
        tripEndDate: tripMetadata.endDate!,
        location: _lodging.location,
        onStayRangeChanged: (checkin, checkout) {
          setState(() {
            final location = _lodging.location;
            _lodging.checkinDateTime =
                LocationTimezoneDateTime.encodeWallClockToUtc(
              wallClock: checkin,
              location: location,
            );
            _lodging.checkoutDateTime =
                LocationTimezoneDateTime.encodeWallClockToUtc(
              wallClock: checkout,
              location: location,
            );
            _lastKnownLocation = location;
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
        scrollPadding: const EdgeInsets.only(top: 24.0, bottom: 50),
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
          _lodging.notes = note.text;
          widget.onLodgingUpdated();
        });
  }
}
