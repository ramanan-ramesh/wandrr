import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/widgets/common_collapsible_tab.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';

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
      items: widget.notes,
      addButtonLabel: context.localizations.addNote,
      addButtonIcon: Icons.note_add_rounded,
      createItem: () => Note(''),
      // Create a new Note object
      onItemsChanged: () {
        widget.onNotesChanged(widget.notes);
      },
      titleBuilder: (n, context) {
        // `n` is now a Note object
        final raw = n.text.trim();
        final untitledText = context.localizations.untitled;
        if (raw.isEmpty) return untitledText;
        final firstLine = raw.split('\n').first.trim();
        return firstLine.isEmpty ? untitledText : firstLine;
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
      expandedBuilder: (ctx, index, note, notifyParent) => NoteEditor(
        // Use the stable Note object instance as the key
        key: ValueKey(note),
        note: note, // Pass the Note object directly
        onChanged: notifyParent,
      ),
      initialExpandedIndex: widget.initialExpandedIndex,
    );
  }
}
