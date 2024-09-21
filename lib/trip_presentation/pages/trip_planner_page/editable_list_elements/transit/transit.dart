import 'package:flutter/material.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/date_time_picker.dart';
import 'package:wandrr/trip_data/models/money.dart';
import 'package:wandrr/trip_data/models/transit.dart';
import 'package:wandrr/trip_data/models/transit_option_metadata.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/expenditure_edit_tile/expenditure_edit_tile.dart';
import 'package:wandrr/trip_presentation/widgets/geo_location_auto_complete.dart';

import 'airport_data_editor.dart';
import 'transit_carrier_picker.dart';

class EditableTransitListItem extends StatefulWidget {
  UiElement<TransitFacade> transitUiElement;
  Iterable<TransitOptionMetadata> transitOptionMetadatas;
  ValueNotifier<bool> validityNotifier;

  EditableTransitListItem(
      {super.key,
      required this.transitUiElement,
      required this.transitOptionMetadatas,
      required this.validityNotifier});

  @override
  State<EditableTransitListItem> createState() =>
      _EditableTransitListItemState();
}

class _EditableTransitListItemState extends State<EditableTransitListItem> {
  late UiElement<TransitFacade> _transitUiElement;

  @override
  void initState() {
    super.initState();
    _transitUiElement = widget.transitUiElement.clone();
    _calculateTransitValidity();
  }

  @override
  Widget build(BuildContext context) {
    var isBigLayout = context.isBigLayout();
    if (isBigLayout) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationDetails(context, false, isBigLayout),
                  _buildLocationDetails(context, true, isBigLayout),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: _buildTransitCarrierPicker(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: _buildNotesField(context),
                  )
                ],
              ),
            ),
          ),
          VerticalDivider(
            color: Colors.black,
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: _buildConfirmationIdField(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: _buildExpenditureEditField(context),
                  )
                ],
              ),
            ),
          )
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: _buildLocationDetails(context, false, isBigLayout),
        ),
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: _buildLocationDetails(context, true, isBigLayout),
        ),
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: _buildTransitCarrierPicker(context),
        ),
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: _buildExpenditureEditField(context),
        ),
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: _buildConfirmationIdField(context),
        ),
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: _buildNotesField(context),
        ),
      ],
    );
  }

  Widget _buildExpenditureEditField(BuildContext context) {
    return _createTitleSubText(
      context.withLocale().cost,
      ExpenditureEditTile(
        expenseUpdator: _transitUiElement.element.expense,
        isEditable: true,
        callback: (paidBy, splitBy, totalExpense) {
          _transitUiElement.element.expense.paidBy = Map.from(paidBy);
          _transitUiElement.element.expense.splitBy = List.from(splitBy);
          _transitUiElement.element.expense.totalExpense = Money(
              currency: totalExpense.currency, amount: totalExpense.amount);
          _calculateTransitValidity();
        },
      ),
    );
  }

  Widget _buildConfirmationIdField(BuildContext context) {
    return _createTitleSubText(
      '${context.withLocale().confirmation} #',
      TextFormField(
          initialValue: _transitUiElement.element.confirmationId,
          onChanged: (newConfirmationId) {
            _transitUiElement.element.confirmationId = newConfirmationId;
          }),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return _createTitleSubText(
      context.withLocale().notes,
      TextFormField(
        initialValue: _transitUiElement.element.notes,
        maxLines: null,
        onChanged: (newNotes) {
          _transitUiElement.element.notes = newNotes;
        },
      ),
    );
  }

  Widget _buildTransitCarrierPicker(BuildContext context) {
    return _createTitleSubText(
      context.withLocale().transitCarrier,
      TransitCarrierPicker(
        transitOption: _transitUiElement.element.transitOption,
        operator: _transitUiElement.element.operator,
        transitOptionMetadatas: widget.transitOptionMetadatas,
        onOperatorChanged: (String? newOperator) {
          _transitUiElement.element.operator = newOperator;
          _calculateTransitValidity();
        },
        onTransitOptionChanged: (newTransitOption) {
          _transitUiElement.element.transitOption = newTransitOption;
          var expense = _transitUiElement.element.expense;
          expense.category = TransitFacade.getExpenseCategory(newTransitOption);
          setState(() {});
          _calculateTransitValidity();
        },
      ),
    );
  }

  Widget _buildLocationDetails(
      BuildContext context, bool isArrival, bool isBigLayout) {
    var transitModelFacade = _transitUiElement.element;
    var locationToConsider = isArrival
        ? transitModelFacade.arrivalLocation
        : transitModelFacade.departureLocation;
    var locationEditorWidget =
        transitModelFacade.transitOption == TransitOption.Flight
            ? AirportsDataEditor(
                initialLocation: locationToConsider,
                onLocationSelected: (newLocation) {
                  if (isArrival) {
                    transitModelFacade.arrivalLocation = newLocation;
                  } else {
                    transitModelFacade.departureLocation = newLocation;
                  }
                  _calculateTransitValidity();
                },
              )
            : PlatformGeoLocationAutoComplete(
                onLocationSelected: (newLocation) {
                  if (isArrival) {
                    transitModelFacade.arrivalLocation = newLocation;
                  } else {
                    transitModelFacade.departureLocation = newLocation;
                  }
                  _calculateTransitValidity();
                },
                initialText: locationToConsider?.toString(),
              );
    var tripMetadata = context.getActiveTrip().tripMetadata;
    var dateTimeEditorWidget = PlatformDateTimePicker(
      //TODO: While choosing arrival date, initial date in DatePicker should be departure date
      initialDateTime: isArrival
          ? transitModelFacade.arrivalDateTime
          : transitModelFacade.departureDateTime,
      dateTimeUpdated: (updatedDateTime) {
        if (isArrival) {
          transitModelFacade.arrivalDateTime = updatedDateTime;
        } else {
          transitModelFacade.departureDateTime = updatedDateTime;
        }
        _calculateTransitValidity();
      },
      startDateTime: isArrival
          ? transitModelFacade.departureDateTime ?? tripMetadata.startDate!
          : tripMetadata.startDate!,
      endDateTime: tripMetadata.endDate!,
    );
    return _createTitleSubText(
      isArrival ? context.withLocale().arrive : context.withLocale().depart,
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isBigLayout)
            Expanded(
              child: locationEditorWidget,
            )
          else
            Flexible(
              child: locationEditorWidget,
            ),
          dateTimeEditorWidget
        ],
      ),
    );
  }

  void _calculateTransitValidity() {
    widget.validityNotifier.value = _transitUiElement.element.isValid();
  }

  Widget _createTitleSubText(String title, Widget subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: EdgeInsets.only(top: 2.0),
          child: subtitle,
        ),
      ],
    );
  }
}
