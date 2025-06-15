import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/base_list_items/lodging_card_base.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

class EditableLodgingPlan extends StatefulWidget {
  final UiElement<LodgingFacade> lodgingUiElement;
  final ValueNotifier<bool> validityNotifier;

  const EditableLodgingPlan({
    super.key,
    required this.lodgingUiElement,
    required this.validityNotifier,
  });

  @override
  State<EditableLodgingPlan> createState() => _EditableLodgingPlanState();
}

class _EditableLodgingPlanState extends State<EditableLodgingPlan> {
  @override
  void initState() {
    super.initState();
    _calculateLodgingValidity();
  }

  @override
  Widget build(BuildContext context) {
    var tripMetadata = context.activeTrip.tripMetadata;
    return LodgingCardBase(
        lodgingFacade: widget.lodgingUiElement.element,
        location: PlatformGeoLocationAutoComplete(
          selectedLocation: widget.lodgingUiElement.element.location,
          onLocationSelected: (newLocation) {
            widget.lodgingUiElement.element.location = newLocation;
            _calculateLodgingValidity();
          },
        ),
        dateTime: PlatformDateRangePicker(
          startDate: widget.lodgingUiElement.element.checkinDateTime,
          endDate: widget.lodgingUiElement.element.checkoutDateTime,
          callback: (newStartDate, newEndDate) {
            widget.lodgingUiElement.element.checkinDateTime = newStartDate;
            widget.lodgingUiElement.element.checkoutDateTime = newEndDate;
            _calculateLodgingValidity();
          },
          firstDate: tripMetadata.startDate!,
          lastDate: tripMetadata.endDate!,
        ),
        notes: TextField(
          controller: TextEditingController(
              text: widget.lodgingUiElement.element.notes),
          onChanged: (newNotes) {
            widget.lodgingUiElement.element.notes = newNotes;
          },
          decoration: InputDecoration(
            labelText: context.localizations.notes,
          ),
        ),
        confirmationId: TextField(
          controller: TextEditingController(
              text: widget.lodgingUiElement.element.confirmationId),
          onChanged: (confirmationId) {
            widget.lodgingUiElement.element.confirmationId = confirmationId;
          },
          decoration: InputDecoration(
            labelText: '${context.localizations.confirmation} #',
          ),
        ),
        expense: ExpenditureEditTile(
            expenseUpdator: widget.lodgingUiElement.element.expense,
            isEditable: true),
        isEditable: true);
  }

  void _calculateLodgingValidity() {
    widget.validityNotifier.value = widget.lodgingUiElement.element.isValid();
  }
}
