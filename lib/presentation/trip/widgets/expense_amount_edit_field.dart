import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/l10n/extension.dart';

class PlatformExpenseAmountEditField extends StatelessWidget {
  final bool isReadonly;
  final Function(double)? onExpenseAmountChanged;
  String? amount;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? inputDecoration;
  final Color? textColor;
  final TextInputAction textInputAction;

  PlatformExpenseAmountEditField({
    super.key,
    this.isReadonly = false,
    this.onExpenseAmountChanged,
    this.inputDecoration,
    this.textColor,
    this.textInputAction = TextInputAction.done, // changed default to done
    this.amount,
    this.controller,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController effectiveController = controller ??
        TextEditingController(
            text: amount != null
                ? (double.parse(amount!) == 0 ? '0' : amount)
                : amount);
    final FocusNode effectiveFocusNode = focusNode ?? FocusNode();
    return TextField(
      readOnly: isReadonly,
      style: TextStyle(color: textColor),
      textInputAction: textInputAction,
      controller: effectiveController,
      focusNode: effectiveFocusNode,
      onChanged: (newValue) {
        if (newValue != amount) {
          amount = newValue;
          var doubleValue = double.tryParse(newValue);
          if (onExpenseAmountChanged != null && doubleValue != null) {
            onExpenseAmountChanged!(doubleValue);
          }
        }
        // No focus shifting code here
      },
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_DecimalTextInputFormatter()],
      decoration: inputDecoration
        ?..copyWith(hintText: context.localizations.enterAmount),
    );
  }
}

class _DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  _DecimalTextInputFormatter({this.decimalRange = 2})
      : assert(decimalRange > 0);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newSelection = newValue.selection;
    var truncated = newValue.text;

    var value = newValue.text;

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
