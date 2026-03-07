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
  String? _lastQueryForTimer;

  // --- Disposal guard ---
  bool _disposed = false;

  // --- Stable function reference for Autocomplete.optionsBuilder ---
  // Stored as a field so the reference never changes across rebuilds.
  // If Autocomplete receives a new function object on every build it calls
  // _onChangedField → _updateOptionsViewVisibility → hide() even when the
  // overlay has never been shown (_zOrderIndex == null) → assertion crash.
  late final Future<Iterable<T>> Function(TextEditingValue)
      _stableOptionsBuilder;

  // --- Cached constraints from LayoutBuilder for optionsViewBuilder ---
  BoxConstraints? _constraints;

  // --- State variables for managing selection and controllers ---
  late FocusNode _focusNode;
  late TextEditingController _textEditingController;
  T? _internalSelectedItem;
  bool _focusListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _internalSelectedItem = widget.selectedItem;
    _stableOptionsBuilder = _debouncedOptionsBuilder;
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _debounce = null;
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete([]);
    }
    _completer = null;
    _lastQueryForTimer = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PlatformAutoComplete<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItem != widget.selectedItem) {
      // Update the displayed text without triggering a full rebuild of Autocomplete.
      // Using post-frame so we don't mutate the controller during build.
      final newItem = widget.selectedItem;
      _internalSelectedItem = newItem;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed) return;
        if (newItem != null) {
          final text = _getDisplayString(newItem);
          if (_textEditingController.text != text) {
            _textEditingController.text = text;
          }
        }
      });
    }
  }

  Future<Iterable<T>> _debouncedOptionsBuilder(
      TextEditingValue textEditingValue) async {
    if (_disposed) return <T>[];

    final String query = textEditingValue.text;

    if (query.isEmpty) {
      return <T>[];
    }

    // Handle exact match to selected item
    if (_internalSelectedItem != null) {
      final displayString = _getDisplayString(_internalSelectedItem!);
      if (query == displayString) {
        // If focused and exact match, return empty to avoid showing redundant dropdown
        if (_focusNode.hasFocus) {
          return <T>[];
        }
        // Otherwise (e.g., initial set, no focus), return sync with selected to satisfy builder without async
        return [_internalSelectedItem!];
      }
    }

    // Standard debounced async for partial/non-matching queries
    if (query == _lastQueryForTimer && _completer != null) {
      return _completer!.future;
    }

    _debounce?.cancel();

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(<T>[]);
    }

    final Completer<Iterable<T>> completer = Completer<Iterable<T>>();
    _completer = completer;
    _lastQueryForTimer = query;

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (_disposed) return;
      try {
        final results = await widget.optionsBuilder(query);
        if (_disposed) return;
        if (completer == _completer && !completer.isCompleted) {
          completer.complete(results);
        }
      } catch (e) {
        if (_disposed) return;
        if (completer == _completer && !completer.isCompleted) {
          completer.completeError(e);
        }
      }
    });

    return completer.future;
  }

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
        _constraints = constraints;
        return SizedBox(
          width: constraints.maxWidth,
          // Autocomplete is keyed so it is never torn down and recreated during
          // parent rebuilds. This prevents _onChangedField being called on a
          // stale / not-yet-shown overlay (the _zOrderIndex == null crash).
          child: Autocomplete<T>(
            key: ObjectKey(this),
            optionsBuilder: _stableOptionsBuilder,
            onSelected: (T selection) {
              _internalSelectedItem = selection;
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

              // Attach focus listener only once per FocusNode lifetime.
              if (!_focusListenerAttached) {
                _focusListenerAttached = true;
                focusNode.addListener(() {
                  if (_disposed) return;
                  if (!focusNode.hasFocus && _internalSelectedItem != null) {
                    _textEditingController.text =
                        _getDisplayString(_internalSelectedItem!);
                  }
                });
              }

              // Sync text post-frame to avoid mutating the controller during build.
              if (_internalSelectedItem != null) {
                final expected = _getDisplayString(_internalSelectedItem!);
                if (_textEditingController.text != expected) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_disposed) return;
                    if (_textEditingController.text != expected) {
                      _textEditingController.text = expected;
                    }
                  });
                }
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
                          const TextStyle(fontSize: 16.0),
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
              final width =
                  widget.optionsViewWidth ?? _constraints?.maxWidth ?? 300.0;
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: Container(
                    color: Theme.of(context).dialogTheme.backgroundColor,
                    width: width,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Builder(
                            builder: (BuildContext context) =>
                                widget.listItem(option),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const Divider(),
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
