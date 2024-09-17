import 'package:flutter/material.dart';

class PlatformTextElements {
  static const double subHeaderSize = 20;
  static const double formElementSize = 15;

  static Text createHeader(
      {required BuildContext context, required String text}) {
    return Text(
      text,
      style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
    );
  }

  static Text createSubHeader(
      {required BuildContext context,
      required String text,
      bool shouldBold = false}) {
    return Text(
      text,
      softWrap: true,
      style: TextStyle(
          // color: Colors.white,
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
      controller: controller,
      decoration: inputDecoration,
    );
  }
}
