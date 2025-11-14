import 'dart:async';

import 'package:flutter/material.dart';

class PlatformAutoComplete<T extends Object> extends StatefulWidget {
  final FutureOr<Iterable<T>> Function(String searchValue) optionsBuilder;
  final Widget Function(T value) listItem;
  final Widget? customPrefix;
  final Widget? prefixIcon;
  final void Function(T)? onSelected;
  final Widget? suffix;
  final String? hintText;
  final String? labelText;
  final double? optionsViewWidth;
  final String Function(T)? displayTextCreator;
  final T? selectedItem;

  static const _defaultAutoCompleteHintText = 'e.g. Paris, Hawaii...';

  PlatformAutoComplete({
    required this.optionsBuilder,
    required this.listItem,
    super.key,
    this.selectedItem,
    this.onSelected,
    this.labelText,
    this.displayTextCreator,
    this.hintText,
    this.suffix,
    this.optionsViewWidth,
    this.customPrefix,
    this.prefixIcon,
  });

  @override
  State<PlatformAutoComplete<T>> createState() =>
      _PlatformAutoCompleteState<T>();
}

class _PlatformAutoCompleteState<T extends Object>
    extends State<PlatformAutoComplete<T>> {
  // --- Debouncer State ---
  Timer? _debounce;
  Completer<Iterable<T>>? _completer;

  // Stores the last query text that a timer was set for.
  // This is the key to fixing the RawAutocomplete bug.
  String? _lastQueryForTimer;

  // --- State variables for managing selection and controllers ---
  late FocusNode _focusNode;
  late TextEditingController _textEditingController;
  T? _internalSelectedItem;

  @override
  void initState() {
    super.initState();
    _internalSelectedItem = widget.selectedItem;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete([]);
    }
    _lastQueryForTimer = null;
    super.dispose();
  }

  Future<Iterable<T>> _debouncedOptionsBuilder(
      TextEditingValue textEditingValue) async {
    final String query = textEditingValue.text;

    if (query == _lastQueryForTimer && _completer != null) {
      return _completer!.future;
    }

    _debounce?.cancel();

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete([]);
    }

    final Completer<Iterable<T>> completer = Completer<Iterable<T>>();
    _completer = completer;
    _lastQueryForTimer = query;

    if (query.isEmpty) {
      completer.complete([]);
      return completer.future;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await widget.optionsBuilder(query);

        if (completer == _completer && !completer.isCompleted) {
          completer.complete(results);
        }
      } catch (e) {
        if (completer == _completer && !completer.isCompleted) {
          completer.completeError(e);
        }
      }
    });

    return completer.future;
  }

  /// Helper to get the display string for a given item
  String _getDisplayString(T item) {
    if (widget.displayTextCreator != null) {
      return widget.displayTextCreator!(item);
    }
    return item.toString();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Autocomplete<T>(
            optionsBuilder: _debouncedOptionsBuilder,
            onSelected: (T selection) {
              setState(() {
                _internalSelectedItem = selection;
              });
              _textEditingController.text = _getDisplayString(selection);
              widget.onSelected?.call(selection);
              _focusNode.unfocus();
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) {
              _focusNode = focusNode;
              _textEditingController = textEditingController;

              focusNode.addListener(() {
                if (!focusNode.hasFocus) {
                  if (_internalSelectedItem != null) {
                    _textEditingController.text =
                        _getDisplayString(_internalSelectedItem!);
                  }
                }
              });

              if (_internalSelectedItem != null) {
                _textEditingController.text =
                    _getDisplayString(_internalSelectedItem!);
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.customPrefix != null)
                    Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: widget.customPrefix!,
                    ),
                  Expanded(
                    child: TextFormField(
                      controller: _textEditingController,
                      focusNode: _focusNode,
                      style: Theme.of(context).textTheme.labelLarge ??
                          const TextStyle(
                            fontSize: 16.0,
                          ),
                      decoration: InputDecoration(
                        suffix: widget.suffix,
                        isDense: true,
                        prefixIcon: widget.prefixIcon,
                        hintText: widget.hintText ??
                            PlatformAutoComplete._defaultAutoCompleteHintText,
                        labelText: widget.labelText,
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
                child: Material(
                  elevation: 4.0,
                  child: Container(
                    color: Theme.of(context).dialogTheme.backgroundColor,
                    width: widget.optionsViewWidth ?? constraints.maxWidth,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                          },
                          child: Builder(builder: (BuildContext context) {
                            return widget.listItem(option);
                          }),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider();
                      },
                      itemCount: options.length,
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
