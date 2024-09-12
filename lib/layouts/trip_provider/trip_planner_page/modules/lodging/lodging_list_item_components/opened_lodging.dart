import 'package:flutter/material.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/trip_entity_facades/expense.dart';
import 'package:wandrr/contracts/trip_entity_facades/lodging.dart';
import 'package:wandrr/contracts/ui_element.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/budgeting/expense_list_item_components/expenditure_edit_tile.dart';
import 'package:wandrr/platform_elements/date_picker.dart';
import 'package:wandrr/platform_elements/form.dart';
import 'package:wandrr/platform_elements/text.dart';

class OpenedLodgingListItem extends StatefulWidget {
  UiElement<LodgingFacade> lodgingUiElement;
  ValueNotifier<bool> validityNotifier;

  OpenedLodgingListItem(
      {super.key,
      required this.lodgingUiElement,
      required this.validityNotifier});

  @override
  State<OpenedLodgingListItem> createState() => _OpenedLodgingListItemState();
}

class _OpenedLodgingListItemState extends State<OpenedLodgingListItem> {
  @override
  void initState() {
    super.initState();
    _calculateLodgingValidity();
  }

  @override
  Widget build(BuildContext context) {
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
                  child: _createLodgingElement(
                    context.withLocale().stayAddress,
                    PlatformGeoLocationAutoComplete(
                      initialText: widget
                          .lodgingUiElement.element.location?.context.name,
                      onLocationSelected: (newLocation) {
                        widget.lodgingUiElement.element.location = newLocation;
                        _calculateLodgingValidity();
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: PlatformDateRangePicker(
                    initialStartDate:
                        widget.lodgingUiElement.element.checkinDateTime,
                    initialEndDate:
                        widget.lodgingUiElement.element.checkoutDateTime,
                    startDateLabelText: context.withLocale().checkIn,
                    endDateLabelText: context.withLocale().checkOut,
                    callback: (newStartDate, newEndDate) {
                      widget.lodgingUiElement.element.checkinDateTime =
                          newStartDate;
                      widget.lodgingUiElement.element.checkoutDateTime =
                          newEndDate;
                      _calculateLodgingValidity();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: _createLodgingElement(
                    context.withLocale().notes,
                    PlatformTextField(
                      maxLines: null,
                      initialText: widget.lodgingUiElement.element.notes,
                      onTextChanged: (newNotes) {
                        widget.lodgingUiElement.element.notes = newNotes;
                      },
                    ),
                  ),
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
                child: _createLodgingElement(
                  '${context.withLocale().confirmation} #',
                  PlatformTextField(
                    initialText: widget.lodgingUiElement.element.confirmationId,
                    maxLines: null,
                    onTextChanged: (newConfirmationId) {
                      widget.lodgingUiElement.element.confirmationId =
                          newConfirmationId;
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: _createLodgingElement(
                  context.withLocale().cost,
                  ExpenditureEditTile(
                    expenseUpdator: widget.lodgingUiElement.element.expense,
                    isEditable: true,
                    callback: (paidBy, splitBy, totalExpense) {
                      if (paidBy != null) {
                        widget.lodgingUiElement.element.expense.paidBy =
                            Map.from(paidBy);
                      }
                      if (splitBy != null) {
                        widget.lodgingUiElement.element.expense.splitBy =
                            List.from(splitBy);
                      }
                      if (totalExpense != null) {
                        widget.lodgingUiElement.element.expense.totalExpense =
                            CurrencyWithValue(
                                currency: totalExpense.currency,
                                amount: totalExpense.amount);
                      }
                      _calculateLodgingValidity();
                    },
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  void _calculateLodgingValidity() {
    var isLocationValid = widget.lodgingUiElement.element.location != null;
    var areDateTimesValid = widget.lodgingUiElement.element.checkinDateTime !=
            null &&
        widget.lodgingUiElement.element.checkoutDateTime != null &&
        widget.lodgingUiElement.element.checkinDateTime!
                .compareTo(widget.lodgingUiElement.element.checkoutDateTime!) <
            0;
    widget.validityNotifier.value = isLocationValid && areDateTimesValid;
  }

  Widget _createLodgingElement(String? title, Widget lodgingElement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        lodgingElement
      ],
    );
  }
}
