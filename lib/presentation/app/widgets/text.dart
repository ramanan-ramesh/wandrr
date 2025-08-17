import 'package:flutter/material.dart';
import 'package:wandrr/l10n/extension.dart';

typedef OnEmailChangedCallback = void Function(String, {required bool isValid});

class PlatformTextElements {
  static const double subHeaderSize = 17;
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
      TextAlign? textAlign,
      bool shouldBold = false}) {
    return Text(
      text,
      softWrap: true,
      textAlign: textAlign,
      style: TextStyle(
          color: color,
          fontSize: subHeaderSize,
          fontWeight: shouldBold ? FontWeight.bold : null),
    );
  }

  static TextFormField createUsernameFormField(
      {required BuildContext context,
      InputDecoration? inputDecoration,
      TextEditingController? controller,
      OnEmailChangedCallback? onEmailChanged,
      TextInputAction? textInputAction,
      String? Function(String? value)? validator,
      bool readonly = false}) {
    return TextFormField(
      readOnly: readonly,
      style: const TextStyle(fontSize: PlatformTextElements.formElementSize),
      minLines: 1,
      textInputAction: textInputAction,
      onChanged: (username) {
        if (onEmailChanged != null) {
          var isValid = _isEmailValid(username);
          onEmailChanged(username, isValid: isValid);
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
