import 'package:flutter/material.dart';
import 'package:wandrr/presentation/trip/widgets/currency_drop_down.dart';

import 'expense_amount_edit_field.dart';

class PlatformMoneyEditField extends CurrencyDropDownField {
  String amount;
  final bool isAmountEditable;
  final Function(double updatedAmount) onAmountUpdatedCallback;

  PlatformMoneyEditField(
      {required super.selectedCurrencyData,
      required super.allCurrencies,
      required this.onAmountUpdatedCallback,
      double? amount,
      required this.isAmountEditable,
      super.overlayEntry,
      super.key,
      required super.currencySelectedCallback})
      : amount = amount?.toStringAsFixed(2) ?? '0';

  @override
  State<PlatformMoneyEditField> createState() => _PlatformMoneyEditFieldState();
}

class _PlatformMoneyEditFieldState extends State<PlatformMoneyEditField> {
  final _amountEditingController = TextEditingController();

  @override
  void dispose() {
    widget.removeOverlayEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _amountEditingController.text = widget.amount;
    return CompositedTransformTarget(
      link: widget.layerLink,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(50.0),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: () => widget.toggleDropdown(context, setState),
                  icon: Text(
                    widget.selectedCurrencyData.symbol,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PlatformExpenseAmountEditField(
                  amount: widget.amount,
                  isReadonly: !widget.isAmountEditable,
                  onExpenseAmountChanged: (newValue) {
                    widget.amount = newValue.toStringAsFixed(2);
                    widget.onAmountUpdatedCallback(newValue);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
