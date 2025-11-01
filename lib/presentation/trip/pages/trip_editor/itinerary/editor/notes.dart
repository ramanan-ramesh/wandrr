import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/note.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/common_collapsible_tab.dart';

class ItineraryNotesEditor extends StatefulWidget {
  final List<NoteFacade> notes;
  final VoidCallback onNotesChanged;

  const ItineraryNotesEditor({
    super.key,
    required this.notes,
    required this.onNotesChanged,
  });

  @override
  State<ItineraryNotesEditor> createState() => _ItineraryNotesEditorState();
}

class _ItineraryNotesEditorState extends State<ItineraryNotesEditor> {
  @override
  Widget build(BuildContext context) {
    return CommonCollapsibleTab(
      items: widget.notes,
      addButtonLabel: 'Add Note',
      addButtonIcon: Icons.note_add_rounded,
      createItem: () => NoteFacade(note: '', tripId: context.activeTripId),
      onItemsChanged: widget.onNotesChanged,
      titleBuilder: (n) {
        final raw = n.note.trim();
        if (raw.isEmpty) return 'Untitled';
        return raw.split('\n').first.trim().isEmpty
            ? 'Untitled'
            : raw.split('\n').first.trim();
      },
      previewBuilder: (ctx, n) {
        final raw = n.note.replaceAll('\n', ' ').trim();
        final preview =
            raw.length <= 80 ? raw : raw.substring(0, 80).trim() + '…';
        return Text(preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: context.isLightTheme
                      ? AppColors.neutral600
                      : AppColors.neutral400,
                ));
      },
      accentColorBuilder: (n) => n.note.trim().isNotEmpty
          ? AppColors.brandPrimary
          : AppColors.neutral400,
      expandedBuilder: (ctx, index, note, notifyParent) => _NoteEditor(
        note: note,
        isLightTheme: context.isLightTheme,
        onChanged: notifyParent,
      ),
    );
  }
}

class _NoteEditor extends StatefulWidget {
  final NoteFacade note;
  final bool isLightTheme;
  final VoidCallback onChanged;

  const _NoteEditor(
      {required this.note,
      required this.isLightTheme,
      required this.onChanged});

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late TextEditingController _controller;
  final FocusNode _keyboardFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();
  bool _bulletMode = false;
  String _previousText = '';
  static const String _indentUnit = '  ';
  static const String _bulletPrefix = '• ';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.note);
    _previousText = _controller.text;
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _NoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note != widget.note) {
      _controller.text = widget.note.note;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _keyboardFocusNode.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final newText = _controller.text;
    final caret = _controller.selection.start;
    widget.note.note = newText;
    if (_bulletMode && caret > 0 && caret <= newText.length) {
      final insertedNewline = newText.length == _previousText.length + 1 &&
          newText[caret - 1] == '\n';
      if (insertedNewline) _maybeAutoContinueBullet(newText, caret);
    }
    _previousText = newText;
    widget.onChanged();
    setState(() {}); // update toolbar state
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
    if (prevLine.startsWith(_bulletPrefix) ||
        prevLine.startsWith('- ') ||
        prevLine.startsWith('* ')) {
      final indentSpaces = prevLineRaw.substring(0, leadingSpacesLen);
      final newPrefix = indentSpaces + _bulletPrefix;
      final updated =
          text.substring(0, caret) + newPrefix + text.substring(caret);
      final newCaret = caret + newPrefix.length;
      _controller.value = TextEditingValue(
          text: updated, selection: TextSelection.collapsed(offset: newCaret));
      _previousText = updated;
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = widget.isLightTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(context),
        const SizedBox(height: 8),
        KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: TextField(
            focusNode: _textFieldFocusNode,
            controller: _controller,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Write your note here…',
              filled: true,
              fillColor: isLightTheme
                  ? Colors.white.withValues(alpha: 0.98)
                  : AppColors.darkSurface.withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final hasBullet = _currentLineHasBullet();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: _bulletMode ? 'Disable bullets' : 'Enable bullets',
              icon: Icon(Icons.format_list_bulleted,
                  color: _bulletMode ? AppColors.brandPrimary : null),
              onPressed: () {
                setState(() => _bulletMode = !_bulletMode);
                if (_bulletMode) _toggleBulletForCurrentLine(forceAdd: true);
                _textFieldFocusNode.requestFocus();
              },
            ),
            if (_bulletMode)
              TextButton.icon(
                onPressed: () {
                  _toggleBulletForCurrentLine(forceAdd: !hasBullet);
                  _textFieldFocusNode.requestFocus();
                },
                icon: Icon(
                    hasBullet
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    size: 18),
                label: Text(hasBullet ? 'Remove •' : 'Add •'),
              ),
          ],
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
    final text = _controller.text;
    final caret = _controller.selection.start;
    if (caret < 0) return false;
    final safeIndex = caret > 0 ? caret - 1 : 0;
    final prevNewline = safeIndex > 0 ? text.lastIndexOf('\n', safeIndex) : -1;
    final lineStart = prevNewline + 1;
    final nextNewline = text.indexOf('\n', caret);
    final lineEnd = nextNewline == -1 ? text.length : nextNewline;
    if (lineStart >= lineEnd) return false;
    final line = text.substring(lineStart, lineEnd).trimLeft();
    return line.startsWith(_bulletPrefix) ||
        line.startsWith('- ') ||
        line.startsWith('* ');
  }

  void _toggleBulletForCurrentLine({bool forceAdd = false}) {
    final text = _controller.text;
    final selection = _controller.selection;
    var caret = selection.start;
    if (caret < 0) return;
    final safeIndex = caret > 0 ? caret - 1 : 0;
    final prevNewline = safeIndex > 0 ? text.lastIndexOf('\n', safeIndex) : -1;
    final lineStart = prevNewline + 1;
    final nextNewline = text.indexOf('\n', caret);
    final lineEnd = nextNewline == -1 ? text.length : nextNewline;
    final line = text.substring(lineStart, lineEnd);
    const prefix = _bulletPrefix;
    final hasBullet = line.startsWith(prefix);
    String updated = line;
    int caretAdjust = 0;
    if (hasBullet && !forceAdd) {
      updated = line.substring(prefix.length);
      if (caret >= lineStart + prefix.length) caretAdjust = -prefix.length;
    } else if (!hasBullet && forceAdd) {
      updated = prefix + line;
      if (caret >= lineStart) caretAdjust = prefix.length;
    } else {
      updated = hasBullet ? line.substring(prefix.length) : prefix + line;
      if (caret >= lineStart)
        caretAdjust = hasBullet ? -prefix.length : prefix.length;
    }
    final newText =
        text.substring(0, lineStart) + updated + text.substring(lineEnd);
    final newCaret = caret + caretAdjust;
    _controller.value = TextEditingValue(
        text: newText, selection: TextSelection.collapsed(offset: newCaret));
    widget.onChanged();
    _previousText = newText;
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
    final newLine = _indentUnit + line;
    _replaceLine(lineStart, lineEnd, newLine, _indentUnit.length);
  }

  void _outdentCurrentLine() {
    final (lineStart, lineEnd, line) = _currentLineData();
    if (line.startsWith(_indentUnit)) {
      final newLine = line.substring(_indentUnit.length);
      _replaceLine(lineStart, lineEnd, newLine, -_indentUnit.length);
    }
  }

  void _replaceLine(int start, int end, String newLine, int caretDelta) {
    final caret = _controller.selection.start;
    final newText = _controller.text.substring(0, start) +
        newLine +
        _controller.text.substring(end);
    final newCaret = (caret + caretDelta).clamp(start, newText.length);
    _controller.value = TextEditingValue(
        text: newText, selection: TextSelection.collapsed(offset: newCaret));
    widget.onChanged();
    _previousText = newText;
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
