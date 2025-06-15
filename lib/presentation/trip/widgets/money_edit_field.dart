import 'package:flutter/material.dart';
import 'package:wandrr/presentation/trip/widgets/currency_drop_down.dart';

import 'expense_amount_edit_field.dart';

//TODO: Align the drop-down in such a way that the search box icon now becomes a cancel icon, and the amount input becomes currency name search input area. On clicking on cancel, it reverts to original field
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
  final _amountEditingController = TextEditingController();
  late String _currentAmount;

  @override
  void initState() {
    super.initState();
    _currentAmount = widget.initialAmount?.toStringAsFixed(2) ?? '0';
    _amountEditingController.text = _currentAmount;
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PlatformExpenseAmountEditField(
                  textInputAction: widget.textInputAction,
                  amount: _currentAmount,
                  isReadonly: !widget.isAmountEditable,
                  onExpenseAmountChanged: (newValue) {
                    _currentAmount = newValue.toStringAsFixed(2);
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
