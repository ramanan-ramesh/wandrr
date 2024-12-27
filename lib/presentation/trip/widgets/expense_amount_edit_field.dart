import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlatformExpenseAmountEditField extends StatelessWidget {
  bool isReadonly;
  Function(double)? onExpenseAmountChanged;
  String amount;
  final TextEditingController _amountEditingController;
  InputDecoration? inputDecoration;
  Color? textColor;

  PlatformExpenseAmountEditField(
      {super.key,
      this.isReadonly = false,
      this.onExpenseAmountChanged,
      this.inputDecoration,
      this.textColor,
      required this.amount})
      : _amountEditingController = TextEditingController(text: amount);

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: isReadonly,
      style: TextStyle(color: textColor),
      onChanged: (newValue) {
        if (newValue != amount) {
          amount = newValue;
          var doubleValue = double.tryParse(newValue);
          if (onExpenseAmountChanged != null && doubleValue != null) {
            onExpenseAmountChanged!(doubleValue);
          }
        }
      },
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      controller: _amountEditingController,
      inputFormatters: [_DecimalTextInputFormatter()],
      decoration: inputDecoration,
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
