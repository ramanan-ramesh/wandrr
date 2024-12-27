import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/money.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

import 'airport_data_editor.dart';
import 'transit_carrier_picker.dart';

class _LocationDetails extends StatefulWidget {
  TransitFacade transitFacade;
  Function(TransitFacade) onUpdated;

  _LocationDetails(
      {super.key, required this.transitFacade, required this.onUpdated});

  @override
  State<_LocationDetails> createState() => _LocationDetailsState();
}

class _LocationDetailsState extends State<_LocationDetails> {
  @override
  Widget build(BuildContext context) {
    var isBigLayout = context.isBigLayout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationDetails(context, false, isBigLayout),
        _buildLocationDetails(context, true, isBigLayout)
      ],
    );
  }

  Widget _buildLocationDetails(
      BuildContext context, bool isArrival, bool isBigLayout) {
    var locationEditorWidget = _buildLocationEditor(isArrival);
    var tripMetadata = context.activeTrip.tripMetadata;
    var dateTimeEditorWidget = _buildDateTimePicker(isArrival, tripMetadata);
    return _createTitleSubText(
      isArrival ? context.localizations.arrive : context.localizations.depart,
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

  PlatformDateTimePicker _buildDateTimePicker(
      bool isArrival, TripMetadataFacade tripMetadata) {
    return PlatformDateTimePicker(
      //TODO: While choosing arrival date, initial date in DatePicker should be departure date
      initialDateTime: isArrival
          ? widget.transitFacade.arrivalDateTime
          : widget.transitFacade.departureDateTime,
      dateTimeUpdated: (updatedDateTime) {
        if (isArrival) {
          widget.transitFacade.arrivalDateTime = updatedDateTime;
        } else {
          widget.transitFacade.departureDateTime = updatedDateTime;
        }
        setState(() {});
        widget.onUpdated(widget.transitFacade);
      },
      startDateTime: isArrival
          ? widget.transitFacade.departureDateTime ?? tripMetadata.startDate!
          : tripMetadata.startDate!,
      currentDateTime: (isArrival
          ? widget.transitFacade.departureDateTime ?? tripMetadata.startDate!
          : tripMetadata.startDate!)
        ..add(Duration(minutes: 1)),
      endDateTime: tripMetadata.endDate!,
    );
  }

  Widget _buildLocationEditor(bool isArrival) {
    var locationToConsider = isArrival
        ? widget.transitFacade.arrivalLocation
        : widget.transitFacade.departureLocation;
    return widget.transitFacade.transitOption == TransitOption.Flight
        ? AirportsDataEditor(
            initialLocation: locationToConsider,
            onLocationSelected: (newLocation) {
              if (isArrival) {
                widget.transitFacade.arrivalLocation = newLocation;
              } else {
                widget.transitFacade.departureLocation = newLocation;
              }
              widget.onUpdated(widget.transitFacade);
            },
          )
        : PlatformGeoLocationAutoComplete(
            onLocationSelected: (newLocation) {
              if (isArrival) {
                widget.transitFacade.arrivalLocation = newLocation;
              } else {
                widget.transitFacade.departureLocation = newLocation;
              }
              widget.onUpdated(widget.transitFacade);
            },
            initialText: locationToConsider?.toString(),
          );
  }
}

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
    var isBigLayout = context.isBigLayout;
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
                  _LocationDetails(
                      transitFacade: _transitUiElement.element,
                      onUpdated: (transitFacade) {
                        _transitUiElement.element.departureDateTime =
                            transitFacade.departureDateTime;
                        _transitUiElement.element.arrivalDateTime =
                            transitFacade.arrivalDateTime;
                        _transitUiElement.element.departureLocation =
                            transitFacade.departureLocation;
                        _transitUiElement.element.arrivalLocation =
                            transitFacade.arrivalLocation;
                        _calculateTransitValidity();
                      }),
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
      context.localizations.cost,
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
      '${context.localizations.confirmation} #',
      TextFormField(
          initialValue: _transitUiElement.element.confirmationId,
          onChanged: (newConfirmationId) {
            _transitUiElement.element.confirmationId = newConfirmationId;
          }),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return _createTitleSubText(
      context.localizations.notes,
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
      context.localizations.transitCarrier,
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
    var tripMetadata = context.activeTrip.tripMetadata;
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
      isArrival ? context.localizations.arrive : context.localizations.depart,
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
