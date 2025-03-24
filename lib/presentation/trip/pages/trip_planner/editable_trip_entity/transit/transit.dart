import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/money.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/widgets/expense_editing/expenditure_edit_tile.dart';

import 'transit_carrier_picker.dart';
import 'transit_event.dart';

class EditableTransitListItem extends StatefulWidget {
  final UiElement<TransitFacade> transitUiElement;
  final ValueNotifier<bool> validityNotifier;

  const EditableTransitListItem(
      {super.key,
      required this.transitUiElement,
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
    return context.isBigLayout
        ? _createForBigLayout(context)
        : _createForSmallLayout(context);
  }

  Widget _createForSmallLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: TransitEvent(
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
            },
          ),
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

  Widget _createForBigLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TransitEvent(
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
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _buildTransitCarrierPicker(context),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _buildNotesField(context),
                )
              ],
            ),
          ),
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

  Widget _buildExpenditureEditField(BuildContext context) {
    return createTitleSubText(
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
    return createTitleSubText(
      '${context.localizations.confirmation} #',
      TextFormField(
          initialValue: _transitUiElement.element.confirmationId,
          textInputAction: TextInputAction.next,
          onChanged: (newConfirmationId) {
            _transitUiElement.element.confirmationId = newConfirmationId;
          }),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return createTitleSubText(
      context.localizations.notes,
      TextFormField(
        initialValue: _transitUiElement.element.notes,
        textInputAction: TextInputAction.done,
        maxLines: null,
        onChanged: (newNotes) {
          _transitUiElement.element.notes = newNotes;
        },
      ),
    );
  }

  Widget _buildTransitCarrierPicker(BuildContext context) {
    return createTitleSubText(
      context.localizations.transitCarrier,
      TransitCarrierPicker(
        initialTransitOption: _transitUiElement.element.transitOption,
        initialOperator: _transitUiElement.element.operator,
        onOperatorChanged: (String? newOperator) {
          _transitUiElement.element.operator = newOperator;
          _calculateTransitValidity();
        },
        onTransitOptionChanged: (newTransitOption) {
          _transitUiElement.element.transitOption = newTransitOption;
          _transitUiElement.element.arrivalLocation = null;
          _transitUiElement.element.departureLocation = null;
          var expense = _transitUiElement.element.expense;
          expense.category = TransitFacade.getExpenseCategory(newTransitOption);
          setState(() {});
          _calculateTransitValidity();
        },
      ),
    );
  }

  void _calculateTransitValidity() {
    widget.validityNotifier.value = _transitUiElement.element.isValid();
  }
}

Widget createTitleSubText(String title, Widget subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FittedBox(
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: subtitle,
      ),
    ],
  );
}
