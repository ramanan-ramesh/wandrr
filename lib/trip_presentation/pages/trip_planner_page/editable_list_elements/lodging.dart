import 'package:flutter/material.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/date_range_pickers.dart';
import 'package:wandrr/trip_data/models/lodging.dart';
import 'package:wandrr/trip_data/models/money.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/expenditure_edit_tile.dart';
import 'package:wandrr/trip_presentation/widgets/geo_location_auto_complete.dart';

class EditableLodgingListItem extends StatefulWidget {
  UiElement<LodgingFacade> lodgingUiElement;
  ValueNotifier<bool> validityNotifier;

  EditableLodgingListItem({super.key,
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
                    child: _createLodgingElement(
                      context
                          .withLocale()
                          .stayAddress,
                      PlatformGeoLocationAutoComplete(
                        initialText: widget
                            .lodgingUiElement.element.location?.context.name,
                        onLocationSelected: (newLocation) {
                          widget.lodgingUiElement.element.location =
                              newLocation;
                          _calculateLodgingValidity();
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: PlatformDateRangePicker(
                      startDate:
                      widget.lodgingUiElement.element.checkinDateTime,
                      endDate: widget.lodgingUiElement.element.checkoutDateTime,
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
                      context
                          .withLocale()
                          .notes,
                      TextFormField(
                        maxLines: null,
                        initialValue: widget.lodgingUiElement.element.notes,
                        onChanged: (newNotes) {
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
                    '${context
                        .withLocale()
                        .confirmation} #',
                    TextFormField(
                      initialValue:
                      widget.lodgingUiElement.element.confirmationId,
                      onChanged: (newConfirmationId) {
                        widget.lodgingUiElement.element.confirmationId =
                            newConfirmationId;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: _createLodgingElement(
                    context
                        .withLocale()
                        .cost,
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
                              Money(
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: _createLodgingElement(
            context
                .withLocale()
                .stayAddress,
            PlatformGeoLocationAutoComplete(
              initialText:
              widget.lodgingUiElement.element.location?.context.name,
              onLocationSelected: (newLocation) {
                widget.lodgingUiElement.element.location = newLocation;
                _calculateLodgingValidity();
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: PlatformDateRangePicker(
            startDate: widget.lodgingUiElement.element.checkinDateTime,
            endDate: widget.lodgingUiElement.element.checkoutDateTime,
            callback: (newStartDate, newEndDate) {
              widget.lodgingUiElement.element.checkinDateTime = newStartDate;
              widget.lodgingUiElement.element.checkoutDateTime = newEndDate;
              _calculateLodgingValidity();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: _createLodgingElement(
            context
                .withLocale()
                .cost,
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
                  widget.lodgingUiElement.element.expense.totalExpense = Money(
                      currency: totalExpense.currency,
                      amount: totalExpense.amount);
                }
                _calculateLodgingValidity();
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: _createLodgingElement(
            '${context
                .withLocale()
                .confirmation} #',
            TextFormField(
              initialValue: widget.lodgingUiElement.element.confirmationId,
              onChanged: (newConfirmationId) {
                widget.lodgingUiElement.element.confirmationId =
                    newConfirmationId;
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: _createLodgingElement(
            context
                .withLocale()
                .notes,
            TextFormField(
              maxLines: null,
              initialValue: widget.lodgingUiElement.element.notes,
              onChanged: (newNotes) {
                widget.lodgingUiElement.element.notes = newNotes;
              },
            ),
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
