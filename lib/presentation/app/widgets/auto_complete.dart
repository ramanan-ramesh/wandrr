import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'text.dart';

class PlatformAutoComplete<T extends Object> extends StatelessWidget {
  final FutureOr<Iterable<T>> Function(String searchValue) optionsBuilder;
  final Widget Function(T value) listItem;
  final Widget? customPrefix;
  final void Function(T)? onSelected;
  final String? text;
  final Widget? suffix;
  final String? hintText;
  final double? maxOptionWidgetWidth;
  static const _defaultAutoCompleteHintText = 'e.g. Paris, Hawaii...';

  PlatformAutoComplete(
      {Key? key,
      required this.optionsBuilder,
      required this.listItem,
      this.text,
      this.onSelected,
      this.hintText,
      this.suffix,
      this.maxOptionWidgetWidth,
      this.customPrefix})
      : super(key: key);

  T? selectedItem;

  late FocusNode? _focusNode;
  late TextEditingController _textEditingController;

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).scaffoldBackgroundColor;
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
              _textEditingController = textEditingController;
              if (this.text != null) {
                _textEditingController.text = this.text!;
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
                    child: Container(
                      color: color,
                      child: TextFormField(
                        cursorColor: Colors.white,
                        controller: _textEditingController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          fontSize: PlatformTextElements.subHeaderSize,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                            suffix: suffix,
                            fillColor: Colors.red,
                            isDense: true,
                            hintStyle: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.white),
                            hintText: hintText ?? _defaultAutoCompleteHintText,
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ),
                ],
              );
            },
            optionsViewBuilder: (BuildContext context,
                AutocompleteOnSelected<T> onSelected, Iterable<T> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: maxOptionWidgetWidth ?? constraints.maxWidth,
                  child: Container(
                    color: Colors.green,
                    child: Material(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 200),
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
                                  final bool highlight =
                                      AutocompleteHighlightedOption.of(
                                              context) ==
                                          index;
                                  if (highlight) {
                                    SchedulerBinding.instance
                                        .addPostFrameCallback(
                                            (Duration timeStamp) {
                                      Scrollable.ensureVisible(context,
                                          alignment: 0.5);
                                    });
                                  }
                                  return Container(
                                    color: highlight
                                        ? Theme.of(context).focusColor
                                        : null,
                                    child: listItem(option),
                                  );
                                }),
                              );
                            },
                            separatorBuilder: (context, index) {
                              return Divider();
                            },
                            itemCount: options.length),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
