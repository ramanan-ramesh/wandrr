import 'package:flutter/material.dart';

class PlatformTextField extends StatelessWidget {
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
      this.validator,
      this.isDarkMode = true})
      : controller = controller ?? TextEditingController();

  final TextEditingController? controller;
  final bool isDarkMode;
  final IconData? icon;
  final String? labelText, errorText, hintText, initialText, prefixText;
  final FormFieldValidator<String>? validator;
  final Function(String)? onTextChanged;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (initialText != null) {
      controller?.text = initialText!;
    }
    return TextFormField(
      maxLines: maxLines,
      onChanged: onTextChanged,
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        icon: icon != null ? Icon(icon) : null,
        labelText: labelText,
        errorText: errorText,
      ),
      validator: validator,
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
      this.validator})
      : controller = controller ?? TextEditingController();

  final TextEditingController? controller;
  final String? labelText, errorText, helperText;
  final FormFieldValidator<String>? validator;

  @override
  State<PlatformPasswordField> createState() => _PlatformPasswordFieldState();
}

class _PlatformPasswordFieldState extends State<PlatformPasswordField> {
  bool _obscurePassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        icon: Icon(Icons.password_rounded),
        labelText: widget.labelText,
        suffixIcon: IconButton(
          icon:
              Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: _togglePasswordVisibility,
        ),
        errorText: widget.errorText,
      ),
      validator: widget.validator,
    );
  }
}

class PlatformCurrencyDropDown extends StatefulWidget {
  Map<String, dynamic> currencyInfo;
  final List<Map<String, dynamic>> allCurrencies;
  final Function(Map<String, dynamic> selectedCurrencyInfo) callBack;

  PlatformCurrencyDropDown(
      {super.key,
      required this.currencyInfo,
      required this.allCurrencies,
      required this.callBack});

  @override
  State<PlatformCurrencyDropDown> createState() =>
      _PlatformCurrencyDropDownState();
}

class _PlatformCurrencyDropDownState extends State<PlatformCurrencyDropDown> {
  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      width: 100,
      label: CircleAvatar(
        child: Text("${widget.currencyInfo["symbol"]}"),
        radius: 12,
      ),
      initialSelection: widget.currencyInfo['name'],
      onSelected: (currencyName) {
        if (currencyName != null) {
          setState(() {
            var currencyInfo = widget.allCurrencies
                .firstWhere((e) => e['name'] == currencyName);
            widget.currencyInfo = currencyInfo;
            widget.callBack(currencyInfo);
          });
        }
      },
      dropdownMenuEntries: widget.allCurrencies
          .map(
            (e) => DropdownMenuEntry<String>(
              value: e['name'],
              leadingIcon: Text(e['symbol']),
              label: e['name'] + '\n' + e['code'],
            ),
          )
          .toList(),
    );
  }
}
