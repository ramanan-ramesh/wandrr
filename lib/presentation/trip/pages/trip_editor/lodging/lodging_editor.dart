import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

import 'lodging_card_base.dart';

class LodgingEditor extends StatelessWidget {
  final LodgingFacade lodging;
  final void Function() onLodgingUpdated;

  const LodgingEditor({
    required this.lodging,
    required this.onLodgingUpdated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var tripMetadata = context.activeTrip.tripMetadata;
    return LodgingCardBase(
        lodgingFacade: lodging,
        location: PlatformGeoLocationAutoComplete(
          selectedLocation: lodging.location,
          onLocationSelected: (newLocation) {
            lodging.location = newLocation;
            onLodgingUpdated();
          },
        ),
        dateTime: PlatformDateRangePicker(
          startDate: lodging.checkinDateTime,
          endDate: lodging.checkoutDateTime,
          callback: (newStartDate, newEndDate) {
            lodging.checkinDateTime = newStartDate;
            lodging.checkoutDateTime = newEndDate;
            onLodgingUpdated();
          },
          firstDate: tripMetadata.startDate!,
          lastDate: tripMetadata.endDate!,
        ),
        notes: TextField(
          controller: TextEditingController(text: lodging.notes),
          onChanged: (newNotes) {
            lodging.notes = newNotes;
            onLodgingUpdated();
          },
          decoration: InputDecoration(
            labelText: context.localizations.notes,
          ),
          maxLines: null,
        ),
        confirmationId: TextField(
          controller: TextEditingController(text: lodging.confirmationId),
          onChanged: (confirmationId) {
            lodging.confirmationId = confirmationId;
            onLodgingUpdated();
          },
          decoration: InputDecoration(
            labelText: '${context.localizations.confirmation} #',
          ),
        ),
        expense: ExpenditureEditTile(
          expenseUpdator: lodging.expense,
          isEditable: true,
          callback: (paidBy, splitBy, totalExpense) {
            lodging.expense.paidBy = Map.from(paidBy);
            lodging.expense.splitBy = List.from(splitBy);
            lodging.expense.totalExpense = totalExpense;
            onLodgingUpdated();
          },
        ),
        isEditable: true);
  }
}
