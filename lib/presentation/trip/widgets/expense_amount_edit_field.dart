import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/l10n/extension.dart';

class PlatformExpenseAmountEditField extends StatelessWidget {
  final bool isReadonly;
  final Function(double)? onExpenseAmountChanged;
  String? amount;
  final TextEditingController _amountEditingController;
  final InputDecoration? inputDecoration;
  final Color? textColor;
  TextInputAction textInputAction;

  PlatformExpenseAmountEditField(
      {super.key,
      this.isReadonly = false,
      this.onExpenseAmountChanged,
      this.inputDecoration,
      this.textColor,
      this.textInputAction = TextInputAction.next,
      this.amount})
      : _amountEditingController = TextEditingController(
            text: amount != null
                ? (double.parse(amount) == 0 ? null : amount)
                : amount);

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: isReadonly,
      style: TextStyle(color: textColor),
      textInputAction: textInputAction,
      onChanged: (newValue) {
        if (newValue != amount) {
          amount = newValue;
          var doubleValue = double.tryParse(newValue);
          if (onExpenseAmountChanged != null && doubleValue != null) {
            onExpenseAmountChanged!(doubleValue);
          }
        }
      },
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      controller: _amountEditingController,
      inputFormatters: [_DecimalTextInputFormatter()],
      decoration: inputDecoration
        ?..copyWith(hintText: context.localizations.enterAmount),
    );
  }
}

class _DecimalTextInputFormatter extends TextInputFormatter {
  _DecimalTextInputFormatter({this.decimalRange = 2})
      : assert(decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    TextSelection newSelection = newValue.selection;
    String truncated = newValue.text;

    String value = newValue.text;

    // Check if more than one decimal point exists
    if (value.indexOf('.') != value.lastIndexOf('.')) {
      truncated = oldValue.text;
      newSelection = oldValue.selection;
    } else if (value.contains(".") &&
        value.substring(value.indexOf(".") + 1).length > decimalRange) {
      truncated = oldValue.text;
      newSelection = oldValue.selection;
    } else if (value == ".") {
      truncated = "0.";

      newSelection = newValue.selection.copyWith(
        baseOffset: min(truncated.length, truncated.length + 1),
        extentOffset: min(truncated.length, truncated.length + 1),
      );
    }

    return TextEditingValue(
      text: truncated,
      selection: newSelection,
      composing: TextRange.empty,
    );
  }
}
