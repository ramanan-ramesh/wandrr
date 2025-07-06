import 'package:flutter/material.dart';
import 'package:wandrr/presentation/trip/widgets/currency_drop_down.dart';

import 'expense_amount_edit_field.dart';

class PlatformMoneyEditField extends CurrencyDropDownField {
  final bool isAmountEditable;
  final Function(double updatedAmount) onAmountUpdatedCallback;
  final TextInputAction textInputAction;
  final double? initialAmount;

  PlatformMoneyEditField(
      {required super.selectedCurrencyData,
      required super.allCurrencies,
      required this.onAmountUpdatedCallback,
      this.initialAmount,
      required this.isAmountEditable,
      super.overlayEntry,
      super.key,
      this.textInputAction = TextInputAction.next,
      required super.currencySelectedCallback});

  @override
  State<PlatformMoneyEditField> createState() => _PlatformMoneyEditFieldState();
}

class _PlatformMoneyEditFieldState extends State<PlatformMoneyEditField> {
  late String _currentAmount;

  @override
  void initState() {
    super.initState();
    _currentAmount = widget.initialAmount?.toStringAsFixed(2) ?? '0';
  }

  @override
  void dispose() {
    widget.removeOverlayEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: widget.layerLink,
      child: PlatformExpenseAmountEditField(
        textInputAction: widget.textInputAction,
        amount: _currentAmount,
        isReadonly: !widget.isAmountEditable,
        onExpenseAmountChanged: (newValue) {
          _currentAmount = newValue.toStringAsFixed(2);
          widget.onAmountUpdatedCallback(newValue);
        },
        inputDecoration: InputDecoration(
          prefixIcon: widget.buildButton(context, setState),
        ),
      ),
    );
  }
}
