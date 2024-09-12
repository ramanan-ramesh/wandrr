import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlatformTextField extends StatefulWidget {
  PlatformTextField(
      {super.key,
      TextEditingController? controller,
      this.icon,
      this.labelText,
      this.errorText,
      this.hintText,
      this.initialText,
      this.onTextChanged,
      this.maxLines,
      this.prefixText,
      this.textInputAction,
      this.validator,
      this.suffix,
      this.prefix,
      this.isDarkMode = true})
      : controller = controller ?? TextEditingController();

  final TextEditingController? controller;
  final bool isDarkMode;
  final IconData? icon;
  final String? labelText, errorText, hintText, initialText, prefixText;
  final Widget? suffix, prefix;
  final FormFieldValidator<String>? validator;
  final Function(String)? onTextChanged;
  final int? maxLines;
  final TextInputAction? textInputAction;

  @override
  State<PlatformTextField> createState() => _PlatformTextFieldState();
}

class _PlatformTextFieldState extends State<PlatformTextField> {
  @override
  Widget build(BuildContext context) {
    if (widget.initialText != null) {
      widget.controller?.text = widget.initialText!;
    }
    return TextFormField(
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      onChanged: widget.onTextChanged,
      controller: widget.controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        suffix: widget.suffix,
        prefix: widget.prefix,
        prefixText: widget.prefixText,
        icon: widget.icon != null ? Icon(widget.icon) : null,
        labelText: widget.labelText,
        errorText: widget.errorText,
      ),
      validator: widget.validator,
    );
  }
}

class PlatformPasswordField extends StatefulWidget {
  PlatformPasswordField(
      {super.key,
      TextEditingController? controller,
      this.labelText,
      this.errorText,
      this.helperText,
      this.textInputAction,
      this.validator})
      : controller = controller ?? TextEditingController();

  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final String? labelText, errorText, helperText;
  final FormFieldValidator<String>? validator;

  @override
  State<PlatformPasswordField> createState() => _PlatformPasswordFieldState();
}

class _PlatformPasswordFieldState extends State<PlatformPasswordField> {
  bool _obscurePassword = true;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      controller: widget.controller,
      obscureText: _obscurePassword,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        icon: Icon(Icons.password_rounded),
        labelText: widget.labelText,
        suffixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: IconButton(
            icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: _togglePasswordVisibility,
          ),
        ),
        errorText: widget.errorText,
      ),
      validator: widget.validator,
    );
  }
}

class PlatformCurrencyDropDownTextField extends StatefulWidget {
  final List<Map<String, dynamic>> allCurrencies;
  Map<String, dynamic> currencyInfo;
  String amount;
  bool isAmountEditable;
  final Function(Map<String, dynamic> selectedCurrencyInfo)
      currencySelectedCallback;
  Function(double updatedAmount) onAmountUpdatedCallback;

  PlatformCurrencyDropDownTextField(
      {super.key,
      required this.allCurrencies,
      required this.currencyInfo,
      required double? amount,
      this.isAmountEditable = true,
      required this.onAmountUpdatedCallback,
      required this.currencySelectedCallback})
      : amount = amount?.toStringAsFixed(2) ?? '0';

  @override
  State<PlatformCurrencyDropDownTextField> createState() =>
      _PlatformCurrencyDropDownTextFieldState();
}

class _PlatformCurrencyDropDownTextFieldState
    extends State<PlatformCurrencyDropDownTextField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  static const _inputBorder = UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.green, width: 2.0),
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(0),
      topRight: Radius.circular(0),
      bottomLeft: Radius.circular(0),
      bottomRight: Radius.circular(0),
    ),
  );

  final _amountEditingController = TextEditingController();

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _amountEditingController.text = widget.amount;
    return CompositedTransformTarget(
      link: _layerLink,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(50.0),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: IconButton(
                  onPressed: _toggleDropdown,
                  icon: Text(
                    widget.currencyInfo['symbol'],
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              ),
              Expanded(
                  child: PlatformExpenseEditTextField(
                amount: widget.amount,
                isReadonly: !widget.isAmountEditable,
                onExpenseAmountChanged: (newValue) {
                  widget.amount = newValue.toStringAsFixed(2);
                  widget.onAmountUpdatedCallback(newValue);
                },
                inputDecoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: _inputBorder,
                  focusedBorder: _inputBorder,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
        child: Stack(
          children: [
            Positioned(
              width: size.width,
              left: offset.dx,
              top: offset.dy + size.height,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, size.height),
                child: Material(
                  elevation: 4.0,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: 350,
                    ),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: widget.allCurrencies.map((item) {
                          return _buildCurrencyListTile(item);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyListTile(Map<String, dynamic> currency) {
    Color textColor = Colors.white;
    var isEqualToCurrentlySelectedItem =
        mapEquals(currency, widget.currencyInfo);
    if (isEqualToCurrentlySelectedItem) {
      textColor = Colors.green;
    }
    return SizedBox(
      height: 60,
      child: ListTile(
        onTap: () {
          if (!mapEquals(currency, widget.currencyInfo)) {
            setState(() {
              widget.currencyInfo = currency;
              widget.currencySelectedCallback(currency);
              _toggleDropdown();
            });
          }
        },
        selected: isEqualToCurrentlySelectedItem,
        leading: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            currency['symbol'],
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
        title: FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            currency['name'],
            style: TextStyle(
                color:
                    textColor), //TODO: This should also be scaled down. But it makes text center in the ListTile. How to avoid this?
          ),
        ),
        subtitle: Text(
          currency['code'],
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
}

class PlatformExpenseEditTextField extends StatelessWidget {
  bool isReadonly;
  Function(double)? onExpenseAmountChanged;
  String amount;
  final TextEditingController _amountEditingController;
  InputDecoration? inputDecoration;
  Color? textColor;

  PlatformExpenseEditTextField(
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
    return newValue;
  }
}
