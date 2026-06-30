import 'package:flutter/material.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/common_collapsible_tab.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';
class ItineraryNotesEditor extends StatefulWidget {
  final List<Note> notes;
  final Function(List<Note>) onNotesChanged;
  final int? initialExpandedIndex;
  const ItineraryNotesEditor({
    required List<Note> stableNotes,
    required this.onNotesChanged,
    super.key,
    this.initialExpandedIndex,
  }) : notes = stableNotes;
  @override
  State<ItineraryNotesEditor> createState() => _ItineraryNotesEditorState();
}
class _ItineraryNotesEditorState extends State<ItineraryNotesEditor> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: context.tripRepository.activeTrip!.isFullyLoaded,
      initialData: context.tripRepository.activeTrip!.isFullyLoadedValue,
      builder: (context, snapshot) {
        final isLoaded = snapshot.data ?? false;
        return CommonCollapsibleTab<Note>(
          isLoading: !isLoaded,
          items: widget.notes,
          addButtonLabel: context.localizations.addNote,
          addButtonIcon: Icons.note_add_rounded,
          createItem: () => Note(''),
          onItemsChanged: () {
            widget.onNotesChanged(widget.notes);
          },
          titleBuilder: (n, context) {
            final raw = n.text.trim();
            final untitledText = context.localizations.untitled;
            if (raw.isEmpty) {
              return untitledText;
            }
            final firstLine = raw.split('\n').first.trim();
            return firstLine.isEmpty ? untitledText : firstLine;
          },
          accentColorBuilder: (n) =>
              n.text.trim().isNotEmpty
                  ? AppColors.brandPrimary
                  : AppColors.neutral400,
          expandedBuilder: (ctx, index, note, notifyParent) => NoteEditor(
            key: ValueKey(note),
            note: note,
            onChanged: notifyParent,
          ),
          initialExpandedIndex: widget.initialExpandedIndex,
        );
      },
    );
  }
}
