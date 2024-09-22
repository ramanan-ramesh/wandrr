import 'package:flutter/material.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/date_range_pickers.dart';
import 'package:wandrr/trip_data/models/lodging.dart';
import 'package:wandrr/trip_data/models/money.dart';
import 'package:wandrr/trip_data/models/trip_metadata.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/expenditure_edit_tile/expenditure_edit_tile.dart';
import 'package:wandrr/trip_presentation/widgets/geo_location_auto_complete.dart';

class EditableLodgingListItem extends StatefulWidget {
  UiElement<LodgingFacade> lodgingUiElement;
  ValueNotifier<bool> validityNotifier;

  EditableLodgingListItem(
      {super.key,
      required this.lodgingUiElement,
      required this.validityNotifier});

  @override
  State<EditableLodgingListItem> createState() =>
      _EditableLodgingListItemState();
}

class _EditableLodgingListItemState extends State<EditableLodgingListItem> {
  @override
  void initState() {
    super.initState();
    _calculateLodgingValidity();
  }

  @override
  Widget build(BuildContext context) {
    var isBigLayout = context.isBigLayout();
    var tripMetadata = context.getActiveTrip().tripMetadata;
    if (isBigLayout) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: _buildStayLocationAutoComplete(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: _buildDateRangePicker(tripMetadata),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: _buildNotesEditor(context),
                  )
                ],
              ),
            ),
          ),
          VerticalDivider(),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: _buildConfirmationIdEditor(context),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: _buildExpenseEditTile(context),
                ),
              ],
            ),
          )
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: _buildStayLocationAutoComplete(context),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: _buildDateRangePicker(tripMetadata),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: _buildExpenseEditTile(context),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: _buildConfirmationIdEditor(context),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: _buildNotesEditor(context),
        )
      ],
    );
  }

  Widget _buildExpenseEditTile(BuildContext context) {
    return _createLodgingElement(
      context.withLocale().cost,
      ExpenditureEditTile(
        expenseUpdator: widget.lodgingUiElement.element.expense,
        isEditable: true,
        callback: (paidBy, splitBy, totalExpense) {
          widget.lodgingUiElement.element.expense.paidBy = Map.from(paidBy);
          widget.lodgingUiElement.element.expense.splitBy = List.from(splitBy);
          widget.lodgingUiElement.element.expense.totalExpense = Money(
              currency: totalExpense.currency, amount: totalExpense.amount);
          _calculateLodgingValidity();
        },
      ),
    );
  }

  Widget _buildConfirmationIdEditor(BuildContext context) {
    return _createLodgingElement(
      '${context.withLocale().confirmation} #',
      TextFormField(
        initialValue: widget.lodgingUiElement.element.confirmationId,
        onChanged: (newConfirmationId) {
          widget.lodgingUiElement.element.confirmationId = newConfirmationId;
        },
      ),
    );
  }

  Widget _buildNotesEditor(BuildContext context) {
    return _createLodgingElement(
      context.withLocale().notes,
      TextFormField(
        maxLines: null,
        initialValue: widget.lodgingUiElement.element.notes,
        onChanged: (newNotes) {
          widget.lodgingUiElement.element.notes = newNotes;
        },
      ),
    );
  }

  PlatformDateRangePicker _buildDateRangePicker(
      TripMetadataFacade tripMetadata) {
    return PlatformDateRangePicker(
      startDate: widget.lodgingUiElement.element.checkinDateTime,
      endDate: widget.lodgingUiElement.element.checkoutDateTime,
      callback: (newStartDate, newEndDate) {
        widget.lodgingUiElement.element.checkinDateTime = newStartDate;
        widget.lodgingUiElement.element.checkoutDateTime = newEndDate;
        _calculateLodgingValidity();
      },
      firstDate: tripMetadata.startDate!,
      lastDate: tripMetadata.endDate!,
    );
  }

  Widget _buildStayLocationAutoComplete(BuildContext context) {
    return _createLodgingElement(
      context.withLocale().stayAddress,
      PlatformGeoLocationAutoComplete(
        initialText: widget.lodgingUiElement.element.location?.context.name,
        onLocationSelected: (newLocation) {
          widget.lodgingUiElement.element.location = newLocation;
          _calculateLodgingValidity();
        },
      ),
    );
  }

  void _calculateLodgingValidity() {
    widget.validityNotifier.value = widget.lodgingUiElement.element.isValid();
  }

  Widget _createLodgingElement(String? title, Widget lodgingElement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(
            title.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: lodgingElement,
        )
      ],
    );
  }
}
