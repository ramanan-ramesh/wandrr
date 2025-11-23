import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/l10n/extension.dart';

class PlatformExpenseAmountEditField extends StatefulWidget {
  final bool isReadonly;
  final Function(double)? onExpenseAmountChanged;
  final String? amount;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? inputDecoration;
  final Color? textColor;
  final TextInputAction textInputAction;

  const PlatformExpenseAmountEditField({
    super.key,
    this.isReadonly = false,
    this.onExpenseAmountChanged,
    this.inputDecoration,
    this.textColor,
    this.textInputAction = TextInputAction.done,
    this.amount,
    this.controller,
    this.focusNode,
  });

  @override
  State<PlatformExpenseAmountEditField> createState() =>
      _PlatformExpenseAmountEditFieldState();
}

class _PlatformExpenseAmountEditFieldState
    extends State<PlatformExpenseAmountEditField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _amount;
  bool _isExternalController = false;

  @override
  void initState() {
    super.initState();
    _isExternalController = widget.controller != null;
    _controller = widget.controller ??
        TextEditingController(
            text: widget.amount != null
                ? (double.parse(widget.amount!) == 0 ? '0' : widget.amount)
                : widget.amount);
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(covariant PlatformExpenseAmountEditField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update text if we're using internal controller and amount changed
    if (!_isExternalController && widget.amount != _amount) {
      _amount = widget.amount;
      _controller.text = (widget.amount != null
          ? (double.parse(widget.amount!) == 0 ? '0' : widget.amount)
          : widget.amount ?? '')!;
    }
  }

  @override
  void dispose() {
    // Only dispose if we created them internally
    if (!_isExternalController) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: widget.isReadonly,
      style: TextStyle(color: widget.textColor),
      textInputAction: widget.textInputAction,
      controller: _controller,
      focusNode: _focusNode,
      onChanged: (newValue) {
        if (newValue != widget.amount) {
          _amount = newValue;
          var doubleValue = double.tryParse(newValue);
          if (widget.onExpenseAmountChanged != null && doubleValue != null) {
            widget.onExpenseAmountChanged!(doubleValue);
          }
        }
      },
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_DecimalTextInputFormatter()],
      decoration: widget.inputDecoration
        ?..copyWith(hintText: context.localizations.enterAmount),
      scrollPadding: const EdgeInsets.only(bottom: 250),
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
