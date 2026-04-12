import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// A simple mutable wrapper class for a string.
/// This allows the note's identity (the object) to be stable,
/// while its content (the text property) can be changed.
class Note {
  String text;

  Note(this.text);
}

class NoteEditor extends StatefulWidget {
  // The editor now receives a single, stable Note object
  final Note note;
  final VoidCallback onChanged;

  const NoteEditor({
    required this.note,
    required this.onChanged,
    super.key,
  });

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Controller & focus management
  late TextEditingController _controller;
  final FocusNode _keyboardFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();

  // State
  String _previousText = '';
  bool _currentLineHasBulletState = false;

  // Styling & formatting constants (reused UI values)
  static const double _kSpacingSmall = 8.0;
  static const String _kIndentUnit = '  ';
  static const String _kBulletPrefix = '• ';
  static const double _kTextFieldBorderRadius = 14.0;

  @override
  void initState() {
    super.initState();
    // Initialize controller with the note's text
    _controller = TextEditingController(text: widget.note.text);
    _previousText = _controller.text;
    _controller.addListener(_onControllerChanged);

    // Notify parent when focus is lost (user done editing)
    _textFieldFocusNode.addListener(_onFocusChanged);

    // Update bullet state when cursor moves
    _controller.addListener(_updateBulletState);
  }

  void _onFocusChanged() {
    if (!_textFieldFocusNode.hasFocus) {
      // User stopped editing, update parent UI (title/preview)
      widget.onChanged();
    }
  }

  @override
  void didUpdateWidget(covariant NoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the Note object itself has changed (e.g., due to reordering)
    // update the controller.
    if (widget.note != oldWidget.note) {
      final newNote = widget.note.text;
      _controller.text = newNote;
      _previousText = newNote;
    }
  }

  @override
  void dispose() {
    _textFieldFocusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onControllerChanged);
    _controller.removeListener(_updateBulletState);
    _controller.dispose();
    _keyboardFocusNode.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  /// Listener for text changes; updates model, handles bullet continuation.
  void _onControllerChanged() {
    final newText = _controller.text;
    final caret = _controller.selection.start;

    // **THE FIX**: Mutate the stable Note object's text property
    widget.note.text = newText;

    if (caret > 0 && caret <= newText.length) {
      final insertedNewline = newText.length == _previousText.length + 1 &&
          newText[caret - 1] == '\n';
      if (insertedNewline) {
        _maybeAutoContinueBullet(newText, caret);
      }
    }
    _previousText = newText;

    // **THE FIX**: It is now safe to call this on every keystroke
    // because the key in CommonCollapsibleTab (ObjectKey(note)) is stable.
    widget.onChanged();
  }

  void _maybeAutoContinueBullet(String text, int caret) {
    if (caret < 1) {
      return;
    }
    final prevLineEndExclusive = caret - 1;
    final prevNewline = prevLineEndExclusive > 0
        ? text.lastIndexOf('\n', prevLineEndExclusive - 1)
        : -1;
    final prevLineStart = prevNewline + 1;
    if (prevLineStart >= prevLineEndExclusive) {
      return;
    }
    final prevLineRaw = text.substring(prevLineStart, prevLineEndExclusive);
    final leadingSpacesLen = prevLineRaw.length - prevLineRaw.trimLeft().length;
    final prevLine = prevLineRaw.trimLeft();
    if (prevLine.startsWith(_kBulletPrefix) ||
        prevLine.startsWith('- ') ||
        prevLine.startsWith('* ')) {
      final indentSpaces = prevLineRaw.substring(0, leadingSpacesLen);
      final newPrefix = indentSpaces + _kBulletPrefix;
      final updated =
          text.substring(0, caret) + newPrefix + text.substring(caret);
      final newCaret = caret + newPrefix.length;

      _previousText = updated;
      widget.note.text = updated; // Update the object
      _controller.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: newCaret),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isLightTheme = context.isLightTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(),
        const SizedBox(height: _kSpacingSmall),
        KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: TextField(
            key: const ValueKey('NoteEditor_TextField'),
            focusNode: _textFieldFocusNode,
            controller: _controller,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            scrollPadding: const EdgeInsets.only(bottom: 250),
            decoration: InputDecoration(
              hintText: '${context.localizations.writeYourNoteHere}…',
              filled: true,
              fillColor: isLightTheme
                  ? Colors.white.withValues(alpha: 0.98)
                  : AppColors.darkSurface.withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_kTextFieldBorderRadius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.format_list_bulleted,
            color: _currentLineHasBulletState ? Colors.blue : null,
          ),
          onPressed: () {
            _toggleBulletForSelection(forceAdd: !_currentLineHasBulletState);
            _textFieldFocusNode.requestFocus();
          },
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.format_indent_decrease),
              onPressed: () {
                _outdentCurrentLine();
                _textFieldFocusNode.requestFocus();
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_indent_increase),
              onPressed: () {
                _indentCurrentLine();
                _textFieldFocusNode.requestFocus();
              },
            ),
          ],
        ),
      ],
    );
  }

  bool _currentLineHasBullet() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (selection.start < 0) {
      return false;
    }

    final start = selection.start;
    final end = selection.end;

    final prevNewline = start > 0 ? text.lastIndexOf('\n', start - 1) : -1;
    final selectionStartLineStart = prevNewline + 1;

    final nextNewline = text.indexOf(
        '\n', end > start && text[end - 1] == '\n' ? end - 1 : end);
    final selectionEndLineEnd = nextNewline == -1 ? text.length : nextNewline;

    if (selectionStartLineStart >= selectionEndLineEnd) {
      return false;
    }

    final selectedLinesRaw =
        text.substring(selectionStartLineStart, selectionEndLineEnd);
    final lines = selectedLinesRaw.split('\n');

    var anyNonEmpty = false;
    for (final lineRaw in lines) {
      final line = lineRaw.trimLeft();
      if (line.isEmpty) {
        continue;
      }
      anyNonEmpty = true;
      final hasBullet = line.startsWith(_kBulletPrefix) ||
          line.startsWith('- ') ||
          line.startsWith('* ');
      if (!hasBullet) {
        return false;
      }
    }

    if (!anyNonEmpty && lines.length == 1) {
      return false;
    }
    return anyNonEmpty;
  }

  void _updateBulletState() {
    final hasBullet = _currentLineHasBullet();
    if (_currentLineHasBulletState != hasBullet) {
      setState(() {
        _currentLineHasBulletState = hasBullet;
      });
    }
  }

  void _toggleBulletForSelection({bool forceAdd = false}) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start;
    final end = selection.end;
    if (start < 0 || end < 0) {
      return;
    }

    final prevNewline = start > 0 ? text.lastIndexOf('\n', start - 1) : -1;
    final selectionStartLineStart = prevNewline + 1;

    final nextNewline = text.indexOf(
        '\n', end > start && text[end - 1] == '\n' ? end - 1 : end);
    final selectionEndLineEnd = nextNewline == -1 ? text.length : nextNewline;

    final selectedLinesRaw =
        text.substring(selectionStartLineStart, selectionEndLineEnd);
    final lines = selectedLinesRaw.split('\n');
    final updatedLines = <String>[];

    for (final lineRaw in lines) {
      final leadingSpacesLen = lineRaw.length - lineRaw.trimLeft().length;
      final indent = lineRaw.substring(0, leadingSpacesLen);
      final lineContent = lineRaw.substring(leadingSpacesLen);

      final hasBullet = lineContent.startsWith(_kBulletPrefix) ||
          lineContent.startsWith('- ') ||
          lineContent.startsWith('* ');

      var updatedLine = lineRaw;

      if (hasBullet && !forceAdd) {
        String contentAfterBullet;
        if (lineContent.startsWith(_kBulletPrefix)) {
          contentAfterBullet = lineContent.substring(_kBulletPrefix.length);
        } else if (lineContent.startsWith('- ')) {
          contentAfterBullet = lineContent.substring(2);
        } else if (lineContent.startsWith('* ')) {
          contentAfterBullet = lineContent.substring(2);
        } else {
          contentAfterBullet = lineContent;
        }
        updatedLine = indent + contentAfterBullet;
      } else if (!hasBullet && forceAdd) {
        updatedLine = indent + _kBulletPrefix + lineContent;
      }

      updatedLines.add(updatedLine);
    }

    int mapOffset(int offset) {
      if (offset <= selectionStartLineStart) {
        return offset;
      }
      var mapped = selectionStartLineStart;
      var currentOriginalOffset = selectionStartLineStart;

      for (var i = 0; i < lines.length; i++) {
        final originalLine = lines[i];
        final updatedLine = updatedLines[i];

        var lineOriginalEnd = currentOriginalOffset + originalLine.length;
        var isLast = i == lines.length - 1;
        var nextOriginalOffset = lineOriginalEnd + (isLast ? 0 : 1);

        if (offset <= nextOriginalOffset) {
          var offsetInLine = offset - currentOriginalOffset;
          if (offsetInLine > originalLine.length) {
            return mapped + updatedLine.length + (offset - lineOriginalEnd);
          }
          final leadingSpacesLen =
              originalLine.length - originalLine.trimLeft().length;
          var lengthDiff = updatedLine.length - originalLine.length;

          if (offsetInLine >= leadingSpacesLen) {
            var newOffsetInLine = offsetInLine + lengthDiff;
            if (newOffsetInLine < leadingSpacesLen && lengthDiff < 0) {
              newOffsetInLine = leadingSpacesLen;
            }
            return mapped + newOffsetInLine;
          } else {
            return mapped + offsetInLine;
          }
        }

        mapped += updatedLine.length + (isLast ? 0 : 1);
        currentOriginalOffset = nextOriginalOffset;
      }
      return mapped;
    }

    final updatedSelectionText = updatedLines.join('\n');
    final newText = text.substring(0, selectionStartLineStart) +
        updatedSelectionText +
        text.substring(selectionEndLineEnd);

    var newBase = mapOffset(selection.baseOffset);
    var newExtent = mapOffset(selection.extentOffset);

    _previousText = newText;
    widget.note.text = newText; // Update the object
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: newBase, extentOffset: newExtent),
    );

    // For toolbar actions, notify immediately for UI feedback
    widget.onChanged();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final keys = HardwareKeyboard.instance.logicalKeysPressed;
      final shift = keys.contains(LogicalKeyboardKey.shiftLeft) ||
          keys.contains(LogicalKeyboardKey.shiftRight);
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        shift ? _outdentCurrentLine() : _indentCurrentLine();
        _textFieldFocusNode.requestFocus();
      }
    }
  }

  void _indentCurrentLine() {
    final (lineStart, lineEnd, line) = _currentLineData();
    final newLine = _kIndentUnit + line;
    _replaceLine(lineStart, lineEnd, newLine, _kIndentUnit.length);
  }

  void _outdentCurrentLine() {
    final (lineStart, lineEnd, line) = _currentLineData();
    if (line.startsWith(_kIndentUnit)) {
      final newLine = line.substring(_kIndentUnit.length);
      _replaceLine(lineStart, lineEnd, newLine, -_kIndentUnit.length);
    }
  }

  void _replaceLine(int start, int end, String newLine, int caretDelta) {
    final caret = _controller.selection.start;
    final newText = _controller.text.substring(0, start) +
        newLine +
        _controller.text.substring(end);
    final newCaret = (caret + caretDelta).clamp(start, newText.length);

    _previousText = newText;
    widget.note.text = newText; // Update the object
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    );

    // For toolbar actions, notify immediately for UI feedback
    widget.onChanged();
  }

  (int, int, String) _currentLineData() {
    final text = _controller.text;
    final caret =
        _controller.selection.start < 0 ? 0 : _controller.selection.start;
    final prevNewline = caret > 0 ? text.lastIndexOf('\n', caret - 1) : -1;
    final lineStart = prevNewline + 1;
    final nextNewline = text.indexOf('\n', caret);
    final lineEnd = nextNewline == -1 ? text.length : nextNewline;
    final line = text.substring(lineStart, lineEnd);
    return (lineStart, lineEnd, line);
  }
}
