import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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

// ---------------------------------------------------------------------------
// URL-highlighting TextEditingController
// ---------------------------------------------------------------------------

/// Detects URLs in the text and renders them with a distinct style
/// (blue + underline) while the user types, without interfering with
/// normal editing or IME composing sessions.
class _LinkHighlightingController extends TextEditingController {
  static final _urlRegex = RegExp(
    r'https?://[^\s"<>]+|www\.[^\s"<>]+',
    caseSensitive: false,
  );

  /// Returns every URL [Match] found in the current text.
  Iterable<RegExpMatch> get urlMatches => _urlRegex.allMatches(value.text);

  /// Returns the URL string that overlaps with [position], or null.
  String? urlAtPosition(int position) {
    if (position < 0) return null;
    for (final m in urlMatches) {
      if (m.start <= position && position <= m.end) {
        return m.group(0);
      }
    }
    return null;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    // While the keyboard has an active composing region (mobile IME),
    // show the composing underline via default logic and skip URL styling
    // to avoid caret jumps.
    if (value.isComposingRangeValid && withComposing) {
      final composingStyle = (style ?? const TextStyle()).copyWith(
        decoration: TextDecoration.underline,
      );
      return TextSpan(style: style, children: [
        TextSpan(text: text.substring(0, value.composing.start)),
        TextSpan(
          style: composingStyle,
          text: text.substring(value.composing.start, value.composing.end),
        ),
        TextSpan(text: text.substring(value.composing.end)),
      ]);
    }

    // Build spans, coloring URL segments distinctly.
    final spans = <InlineSpan>[];
    var lastEnd = 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDark ? AppColors.infoLight : AppColors.info;
    final linkStyle = (style ?? const TextStyle()).copyWith(
      color: linkColor,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
    );

    for (final m in _urlRegex.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, m.start),
          style: style,
        ));
      }
      spans.add(TextSpan(text: m.group(0)!, style: linkStyle));
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }

    return TextSpan(style: style, children: spans);
  }
}

// ---------------------------------------------------------------------------
// NoteEditor widget
// ---------------------------------------------------------------------------

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
  late _LinkHighlightingController _controller;
  final FocusNode _keyboardFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();

  // State
  String _previousText = '';
  bool _currentLineHasBulletState = false;
  String? _urlAtCursor; // URL under the cursor — drives the launch button

  // Styling & formatting constants (reused UI values)
  static const double _kSpacingSmall = 8.0;
  static const String _kIndentUnit = '  ';
  static const String _kBulletPrefix = '• ';
  static const double _kTextFieldBorderRadius = 14.0;

  @override
  void initState() {
    super.initState();
    _controller = _LinkHighlightingController()..text = widget.note.text;
    _previousText = _controller.text;
    _controller.addListener(_onControllerChanged);
    _controller.addListener(_updateBulletState);
    _controller.addListener(_updateUrlAtCursor);

    // Notify parent when focus is lost (user done editing)
    _textFieldFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!_textFieldFocusNode.hasFocus) {
      widget.onChanged();
    }
  }

  @override
  void didUpdateWidget(covariant NoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _controller.removeListener(_updateUrlAtCursor);
    _controller.dispose();
    _keyboardFocusNode.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  // ── Listeners ──────────────────────────────────────────────────────────────

  void _onControllerChanged() {
    final newText = _controller.text;
    final caret = _controller.selection.start;

    widget.note.text = newText;

    if (caret > 0 && caret <= newText.length) {
      final insertedNewline = newText.length == _previousText.length + 1 &&
          newText[caret - 1] == '\n';
      if (insertedNewline) {
        _maybeAutoContinueBullet(newText, caret);
      }
    }
    _previousText = newText;
    widget.onChanged();
  }

  void _updateBulletState() {
    final hasBullet = _currentLineHasBullet();
    if (_currentLineHasBulletState != hasBullet) {
      setState(() => _currentLineHasBulletState = hasBullet);
    }
  }

  void _updateUrlAtCursor() {
    final url = _controller.urlAtPosition(_controller.selection.baseOffset);
    if (url != _urlAtCursor) {
      setState(() => _urlAtCursor = url);
    }
  }

  // ── URL launcher ───────────────────────────────────────────────────────────

  Future<void> _launchUrl(String raw) async {
    final urlStr = raw.startsWith('http') ? raw : 'https://$raw';
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Bullet auto-continue ───────────────────────────────────────────────────

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
      widget.note.text = updated;
      _controller.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: newCaret),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLightTheme = context.isLightTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(isLightTheme),
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
            scrollPadding: const EdgeInsets.only(top: 24.0, bottom: 50),
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

  Widget _buildToolbar(bool isLight) {
    final urlColor = isLight ? AppColors.info : AppColors.infoLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Bullet toggle
        IconButton(
          icon: Icon(
            Icons.format_list_bulleted,
            size: 20,
            color: _currentLineHasBulletState
                ? (isLight
                    ? AppColors.brandPrimary
                    : AppColors.brandPrimaryLight)
                : null,
          ),
          tooltip: 'Toggle bullet',
          visualDensity: VisualDensity.compact,
          onPressed: () {
            _toggleBulletForSelection(forceAdd: !_currentLineHasBulletState);
            _textFieldFocusNode.requestFocus();
          },
        ),
        // Indent / outdent
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.format_indent_decrease, size: 20),
              tooltip: 'Decrease indent',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                _outdentCurrentLine();
                _textFieldFocusNode.requestFocus();
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_indent_increase, size: 20),
              tooltip: 'Increase indent',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                _indentCurrentLine();
                _textFieldFocusNode.requestFocus();
              },
            ),
          ],
        ),
        // Open URL button — visible only when cursor is on a link
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _urlAtCursor != null
              ? IconButton(
                  key: const ValueKey('url_launch'),
                  icon: Icon(Icons.open_in_new_rounded,
                      size: 20, color: urlColor),
                  tooltip: 'Open link',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _launchUrl(_urlAtCursor!),
                )
              : const SizedBox(key: ValueKey('url_none'), width: 40),
        ),
      ],
    );
  }

  // ── Bullet helpers ─────────────────────────────────────────────────────────

  bool _currentLineHasBullet() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (selection.start < 0) return false;

    final start = selection.start;
    final end = selection.end;
    final prevNewline = start > 0 ? text.lastIndexOf('\n', start - 1) : -1;
    final lineStart = prevNewline + 1;
    final nextNewline = text.indexOf(
        '\n', end > start && text[end - 1] == '\n' ? end - 1 : end);
    final lineEnd = nextNewline == -1 ? text.length : nextNewline;

    if (lineStart >= lineEnd) return false;
    final selectedLinesRaw = text.substring(lineStart, lineEnd);
    final lines = selectedLinesRaw.split('\n');

    var anyNonEmpty = false;
    for (final lineRaw in lines) {
      final line = lineRaw.trimLeft();
      if (line.isEmpty) continue;
      anyNonEmpty = true;
      final hasBullet = line.startsWith(_kBulletPrefix) ||
          line.startsWith('- ') ||
          line.startsWith('* ');
      if (!hasBullet) return false;
    }
    if (!anyNonEmpty && lines.length == 1) return false;
    return anyNonEmpty;
  }

  void _toggleBulletForSelection({bool forceAdd = false}) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start;
    final end = selection.end;
    if (start < 0 || end < 0) return;

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
        String content;
        if (lineContent.startsWith(_kBulletPrefix)) {
          content = lineContent.substring(_kBulletPrefix.length);
        } else if (lineContent.startsWith('- ') ||
            lineContent.startsWith('* ')) {
          content = lineContent.substring(2);
        } else {
          content = lineContent;
        }
        updatedLine = indent + content;
      } else if (!hasBullet && forceAdd) {
        updatedLine = indent + _kBulletPrefix + lineContent;
      }
      updatedLines.add(updatedLine);
    }

    int mapOffset(int offset) {
      if (offset <= selectionStartLineStart) return offset;
      var mapped = selectionStartLineStart;
      var currentOriginalOffset = selectionStartLineStart;
      for (var i = 0; i < lines.length; i++) {
        final originalLine = lines[i];
        final updatedLine = updatedLines[i];
        final lineOriginalEnd = currentOriginalOffset + originalLine.length;
        final isLast = i == lines.length - 1;
        final nextOriginalOffset = lineOriginalEnd + (isLast ? 0 : 1);
        if (offset <= nextOriginalOffset) {
          final offsetInLine = offset - currentOriginalOffset;
          if (offsetInLine > originalLine.length) {
            return mapped + updatedLine.length + (offset - lineOriginalEnd);
          }
          final leadingSpacesLen =
              originalLine.length - originalLine.trimLeft().length;
          final lengthDiff = updatedLine.length - originalLine.length;
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
    final newBase = mapOffset(selection.baseOffset);
    final newExtent = mapOffset(selection.extentOffset);

    _previousText = newText;
    widget.note.text = newText;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: newBase, extentOffset: newExtent),
    );
    widget.onChanged();
  }

  // ── Indent helpers ─────────────────────────────────────────────────────────

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
    _replaceLine(lineStart, lineEnd, _kIndentUnit + line, _kIndentUnit.length);
  }

  void _outdentCurrentLine() {
    final (lineStart, lineEnd, line) = _currentLineData();
    if (line.startsWith(_kIndentUnit)) {
      _replaceLine(lineStart, lineEnd, line.substring(_kIndentUnit.length),
          -_kIndentUnit.length);
    }
  }

  void _replaceLine(int start, int end, String newLine, int caretDelta) {
    final caret = _controller.selection.start;
    final newText = _controller.text.substring(0, start) +
        newLine +
        _controller.text.substring(end);
    final newCaret = (caret + caretDelta).clamp(start, newText.length);
    _previousText = newText;
    widget.note.text = newText;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    );
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
    return (lineStart, lineEnd, text.substring(lineStart, lineEnd));
  }
}
