import 'package:flutter/material.dart';
import 'package:wandrr/l10n/extension.dart';

typedef OnEmailChangedCallback = void Function(String, {required bool isValid});

class PlatformTextElements {
  static final _emailRegExValidator = RegExp(r'^[^@]+@[^@]+\.[a-zA-Z]+$');

  static Text createHeader(
      {required BuildContext context, required String text, Color? color}) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color),
    );
  }

  static Text createSubHeader(
      {required BuildContext context,
      required String text,
      Color? color,
      TextAlign? textAlign,
      bool shouldBold = false}) {
    final baseStyle = Theme.of(context).textTheme.titleMedium;
    return Text(
      text,
      softWrap: true,
      textAlign: textAlign,
      style: baseStyle?.copyWith(
        color: color,
        fontWeight: shouldBold ? FontWeight.w700 : baseStyle.fontWeight,
      ),
    );
  }

  static TextFormField createUsernameFormField(
      {required BuildContext context,
      Key? key,
      InputDecoration? inputDecoration,
      TextEditingController? controller,
      OnEmailChangedCallback? onEmailChanged,
      TextInputAction? textInputAction,
      String? Function(String? value)? validator,
      void Function(String)? onFieldSubmitted,
      GlobalKey<FormState>? formKey,
      bool readonly = false}) {
    return TextFormField(
      key: key ?? formKey,
      readOnly: readonly,
      style: Theme.of(context).textTheme.bodyLarge,
      minLines: 1,
      textInputAction: textInputAction,
      scrollPadding: const EdgeInsets.only(top: 24.0, bottom: 50),
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
      onFieldSubmitted: (newEmail) {
        if (onFieldSubmitted != null) {
          onFieldSubmitted(newEmail);
        }
      },
    );
  }

  static bool _isEmailValid(String username) {
    var matches = _emailRegExValidator.firstMatch(username);
    final matchedText = matches?.group(0);
    return matchedText == username;
  }
}
