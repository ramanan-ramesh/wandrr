import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/widgets/common_collapsible_tab.dart';

/// A simple mutable wrapper class for a string.
/// This allows the note's identity (the object) to be stable,
/// while its content (the text property) can be changed.
class Note {
  String text;

  Note(this.text);
}

class ItineraryNotesEditor extends StatefulWidget {
  // The API now takes a List<Note> for stable identity
  final List<Note> notes;
  final Function(List<Note>) onNotesChanged;
  final int? initialExpandedIndex;

  ItineraryNotesEditor({
    super.key,
    required List<String> notes,
    required this.onNotesChanged,
    this.initialExpandedIndex,
  }) : notes = notes.map(Note.new).toList(); // Wrap strings in Note objects

  @override
  State<ItineraryNotesEditor> createState() => _ItineraryNotesEditorState();
}

class _ItineraryNotesEditorState extends State<ItineraryNotesEditor> {
  @override
  Widget build(BuildContext context) {
    return CommonCollapsibleTab<Note>(
      // Generics updated to Note
      items: widget.notes,
      addButtonLabel: 'Add Note',
      addButtonIcon: Icons.note_add_rounded,
      createItem: () => Note(''),
      // Create a new Note object
      onItemsChanged: () {
        widget.onNotesChanged(widget.notes);
      },
      titleBuilder: (n) {
        // `n` is now a Note object
        final raw = n.text.trim();
        if (raw.isEmpty) return 'Untitled';
        final firstLine = raw.split('\n').first.trim();
        return firstLine.isEmpty ? 'Untitled' : firstLine;
      },
      previewBuilder: (ctx, n) {
        // `n` is now a Note object
        final raw = n.text.replaceAll('\n', ' ').trim();
        final preview =
            raw.length <= 80 ? raw : raw.substring(0, 80).trim() + '…';
        return Text(
          preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: ctx.isLightTheme
                    ? AppColors.neutral600
                    : AppColors.neutral400,
              ),
        );
      },
      accentColorBuilder: (n) => // `n` is now a Note object
          n.text.trim().isNotEmpty
              ? AppColors.brandPrimary
              : AppColors.neutral400,
      expandedBuilder: (ctx, index, note, notifyParent) => _NoteEditor(
        // Use the stable Note object instance as the key
        key: ValueKey(note),
        note: note, // Pass the Note object directly
        onChanged: notifyParent,
      ),
      initialExpandedIndex: widget.initialExpandedIndex,
    );
  }
}

class _NoteEditor extends StatefulWidget {
  // The editor now receives a single, stable Note object
  final Note note;
  final VoidCallback onChanged;

  const _NoteEditor({
    super.key,
    required this.note,
    required this.onChanged,
  });

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Controller & focus management
  late TextEditingController _controller;
  final FocusNode _keyboardFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();

  // State
  String _previousText = '';

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
  }

  void _onFocusChanged() {
    if (!_textFieldFocusNode.hasFocus) {
      // User stopped editing, update parent UI (title/preview)
      widget.onChanged();
    }
  }

  @override
  void didUpdateWidget(covariant _NoteEditor oldWidget) {
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
      if (insertedNewline) _maybeAutoContinueBullet(newText, caret);
    }
    _previousText = newText;

    // **THE FIX**: It is now safe to call this on every keystroke
    // because the key in CommonCollapsibleTab (ObjectKey(note)) is stable.
    widget.onChanged();
  }

  void _maybeAutoContinueBullet(String text, int caret) {
    if (caret < 1) return;
    final prevLineEndExclusive = caret - 1;
    final prevNewline = prevLineEndExclusive > 0
        ? text.lastIndexOf('\n', prevLineEndExclusive - 1)
        : -1;
    final prevLineStart = prevNewline + 1;
    if (prevLineStart >= prevLineEndExclusive) return;
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
            focusNode: _textFieldFocusNode,
            controller: _controller,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            scrollPadding: const EdgeInsets.only(bottom: 250),
            decoration: InputDecoration(
              hintText: 'Write your note here…',
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
    final hasBullet = _currentLineHasBullet();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: hasBullet ? 'Remove bullet' : 'Add bullet',
          icon: Icon(
            Icons.format_list_bulleted,
            color: hasBullet ? AppColors.brandPrimary : null,
          ),
          onPressed: () {
            _toggleBulletForCurrentLine(forceAdd: !hasBullet);
            _textFieldFocusNode.requestFocus();
          },
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Outdent (Shift+Tab)',
              icon: const Icon(Icons.format_indent_decrease),
              onPressed: () {
                _outdentCurrentLine();
                _textFieldFocusNode.requestFocus();
              },
            ),
            IconButton(
              tooltip: 'Indent (Tab)',
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
    final (lineStart, lineEnd, lineRaw) = _currentLineData();
    if (lineStart >= lineEnd) return false;
    final line = lineRaw.trimLeft();
    return line.startsWith(_kBulletPrefix) ||
        line.startsWith('- ') ||
        line.startsWith('* ');
  }

  void _toggleBulletForCurrentLine({bool forceAdd = false}) {
    final text = _controller.text;
    final selection = _controller.selection;
    var caret = selection.start;
    if (caret < 0) return;

    final prevNewline = caret > 0 ? text.lastIndexOf('\n', caret - 1) : -1;
    final lineStart = prevNewline + 1;
    final nextNewline = text.indexOf('\n', caret);
    final lineEnd = nextNewline == -1 ? text.length : nextNewline;
    final lineRaw = text.substring(lineStart, lineEnd);

    // Extract leading spaces and the actual content
    final leadingSpacesLen = lineRaw.length - lineRaw.trimLeft().length;
    final indent = lineRaw.substring(0, leadingSpacesLen);
    final lineContent = lineRaw.substring(leadingSpacesLen);

    // Check if line has a bullet (after indentation)
    final hasBullet = lineContent.startsWith(_kBulletPrefix) ||
        lineContent.startsWith('- ') ||
        lineContent.startsWith('* ');

    String updated;
    int caretAdjust = 0;

    if (hasBullet && !forceAdd) {
      // Remove bullet - find which prefix is used and remove it
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
      updated = indent + contentAfterBullet;
      // Move cursor to start of line (after indent)
      caretAdjust = lineStart + leadingSpacesLen - caret;
    } else if (!hasBullet && forceAdd) {
      // Add bullet after indentation
      updated = indent + _kBulletPrefix + lineContent;
      if (caret >= lineStart + leadingSpacesLen) {
        caretAdjust = _kBulletPrefix.length;
      }
    } else {
      // Toggle: same logic as above
      if (hasBullet) {
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
        updated = indent + contentAfterBullet;
        caretAdjust = lineStart + leadingSpacesLen - caret;
      } else {
        updated = indent + _kBulletPrefix + lineContent;
        if (caret >= lineStart + leadingSpacesLen) {
          caretAdjust = _kBulletPrefix.length;
        }
      }
    }

    final newText =
        text.substring(0, lineStart) + updated + text.substring(lineEnd);
    final newCaret = caret + caretAdjust;

    _previousText = newText;
    widget.note.text = newText; // Update the object
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
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
