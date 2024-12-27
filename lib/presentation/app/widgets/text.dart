import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/extensions.dart';

class PlatformTextElements {
  static const double subHeaderSize = 20;
  static const double formElementSize = 15;
  static final _emailRegExValidator = RegExp('.*@.*.com');

  static Text createHeader(
      {required BuildContext context, required String text, Color? color}) {
    return Text(
      text,
      style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: color),
    );
  }

  static Text createSubHeader(
      {required BuildContext context,
      required String text,
      Color? color,
      bool shouldBold = false}) {
    return Text(
      text,
      softWrap: true,
      style: TextStyle(
          color: color,
          fontSize: subHeaderSize,
          fontWeight: shouldBold ? FontWeight.bold : null),
    );
  }

  //TODO: Use PlatformTextField instead of this. Replace all usages
  static TextField createTextField(
      {required BuildContext context,
      String? labelText,
      InputBorder? border,
      TextEditingController? controller,
      Function(String)? onTextChanged,
      String? hintText,
      Widget? suffix,
      TextInputAction? textInputAction,
      int? maxLines = 10}) {
    InputDecoration? inputDecoration;
    if (labelText != null || border != null || suffix != null) {
      inputDecoration = InputDecoration(
          labelText: labelText,
          border: border,
          suffix: suffix,
          hintText: hintText);
    }
    return TextField(
      style: TextStyle(fontSize: PlatformTextElements.formElementSize),
      minLines: 1,
      maxLines: maxLines,
      onChanged: onTextChanged,
      textInputAction: textInputAction,
      controller: controller,
      decoration: inputDecoration,
    );
  }

  static TextFormField createUsernameFormField(
      {required BuildContext context,
      InputDecoration? inputDecoration,
      TextEditingController? controller,
      Function(String, bool)? onTextChanged,
      TextInputAction? textInputAction,
      String? Function(String? value)? validator}) {
    return TextFormField(
      style: TextStyle(fontSize: PlatformTextElements.formElementSize),
      minLines: 1,
      textInputAction: textInputAction,
      onChanged: (username) {
        if (onTextChanged != null) {
          var isValid = _isEmailValid(username);
          onTextChanged(username, isValid);
        }
      },
      controller: controller,
      validator: (username) {
        if (username != null) {
          var isEmailValid = _isEmailValid(username);
          if (!isEmailValid) {
            return context.localizations.enterValidEmail;
          }
          if (validator != null) {
            return validator(username);
          }
          return null;
        }
        if (validator != null) {
          return validator(username);
        }
        return null;
      },
      decoration: inputDecoration,
    );
  }

  static bool _isEmailValid(String username) {
    var matches = _emailRegExValidator.firstMatch(username);
    final matchedText = matches?.group(0);
    return matchedText == username;
  }
}
