import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/ui_element.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/base_list_items/lodging_card_base.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

class EditableLodgingPlan extends StatelessWidget {
  final UiElement<LodgingFacade> lodgingUiElement;
  final ValueNotifier<bool> validityNotifier;

  const EditableLodgingPlan({
    required this.lodgingUiElement,
    required this.validityNotifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    _calculateLodgingValidity();
    var tripMetadata = context.activeTrip.tripMetadata;
    return LodgingCardBase(
        lodgingFacade: lodgingUiElement.element,
        location: PlatformGeoLocationAutoComplete(
          selectedLocation: lodgingUiElement.element.location,
          onLocationSelected: (newLocation) {
            lodgingUiElement.element.location = newLocation;
            _calculateLodgingValidity();
          },
        ),
        dateTime: PlatformDateRangePicker(
          startDate: lodgingUiElement.element.checkinDateTime,
          endDate: lodgingUiElement.element.checkoutDateTime,
          callback: (newStartDate, newEndDate) {
            lodgingUiElement.element.checkinDateTime = newStartDate;
            lodgingUiElement.element.checkoutDateTime = newEndDate;
            _calculateLodgingValidity();
          },
          firstDate: tripMetadata.startDate!,
          lastDate: tripMetadata.endDate!,
        ),
        notes: TextField(
          controller:
              TextEditingController(text: lodgingUiElement.element.notes),
          onChanged: (newNotes) {
            lodgingUiElement.element.notes = newNotes;
          },
          decoration: InputDecoration(
            labelText: context.localizations.notes,
          ),
          maxLines: null,
        ),
        confirmationId: TextField(
          controller: TextEditingController(
              text: lodgingUiElement.element.confirmationId),
          onChanged: (confirmationId) {
            lodgingUiElement.element.confirmationId = confirmationId;
          },
          decoration: InputDecoration(
            labelText: '${context.localizations.confirmation} #',
          ),
        ),
        expense: ExpenditureEditTile(
          expenseUpdator: lodgingUiElement.element.expense,
          isEditable: true,
          callback: (paidBy, splitBy, totalExpense) {
            lodgingUiElement.element.expense.paidBy = Map.from(paidBy);
            lodgingUiElement.element.expense.splitBy = List.from(splitBy);
            lodgingUiElement.element.expense.totalExpense = totalExpense;
          },
        ),
        isEditable: true);
  }

  void _calculateLodgingValidity() {
    validityNotifier.value = lodgingUiElement.element.validate();
  }
}
