import 'dart:async';

import 'package:flutter/material.dart';

import 'text.dart';

class PlatformAutoComplete<T extends Object> extends StatelessWidget {
  final FutureOr<Iterable<T>> Function(String searchValue) optionsBuilder;
  final Widget Function(T value) listItem;
  final Widget? customPrefix;
  final Widget? prefixIcon;
  final void Function(T)? onSelected;
  final Widget? suffix;
  final String? hintText;
  final double? maxOptionWidgetWidth;
  final String Function(T)? displayTextCreator;
  T? selectedItem;

  static const _defaultAutoCompleteHintText = 'e.g. Paris, Hawaii...';
  late FocusNode? _focusNode;
  late TextEditingController _textEditingController;

  PlatformAutoComplete(
      {super.key,
      required this.optionsBuilder,
      required this.listItem,
      this.selectedItem,
      this.onSelected,
      this.displayTextCreator,
      this.hintText,
      this.suffix,
      this.maxOptionWidgetWidth,
      this.customPrefix,
      this.prefixIcon});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Autocomplete<T>(
            optionsBuilder: (textEditingValue) async {
              return await optionsBuilder(textEditingValue.text);
            },
            onSelected: (T selection) {
              selectedItem = selection;
              _textEditingController.text = selection.toString();
              if (onSelected != null) {
                onSelected!(selection);
              }
              if (_focusNode != null) {
                _focusNode!.unfocus();
              }
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) {
              _focusNode = focusNode;
              focusNode.addListener(() {
                if (!focusNode.hasFocus) {
                  if (selectedItem != null) {
                    if (displayTextCreator != null) {
                      _textEditingController.text =
                          displayTextCreator!(selectedItem!);
                    } else {
                      _textEditingController.text = selectedItem.toString();
                    }
                  }
                }
              });
              _textEditingController = textEditingController;
              if (selectedItem != null) {
                _textEditingController.text = displayTextCreator != null
                    ? displayTextCreator!(selectedItem!)
                    : selectedItem!.toString();
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (customPrefix != null)
                    Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: customPrefix!,
                    ),
                  Expanded(
                    child: TextFormField(
                      controller: _textEditingController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        fontSize: PlatformTextElements.subHeaderSize,
                      ),
                      decoration: InputDecoration(
                        suffix: suffix,
                        isDense: true,
                        prefixIcon: prefixIcon,
                        hintText: hintText ?? _defaultAutoCompleteHintText,
                        // border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              );
            },
            optionsViewBuilder: (BuildContext context,
                AutocompleteOnSelected<T> onSelected, Iterable<T> options) {
              return SizedBox(
                width: maxOptionWidgetWidth ?? constraints.maxWidth,
                child: Container(
                  constraints: BoxConstraints(maxHeight: 200, maxWidth: 300),
                  color: Theme.of(context).dialogTheme.backgroundColor,
                  child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        final T option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                          },
                          child: Builder(builder: (BuildContext context) {
                            return listItem(option);
                          }),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Divider();
                      },
                      itemCount: options.length),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
