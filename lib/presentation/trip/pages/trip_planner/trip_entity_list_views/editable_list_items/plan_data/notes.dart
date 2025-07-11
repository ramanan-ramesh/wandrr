import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/note.dart';
import 'package:wandrr/presentation/app/widgets/card.dart';

class NotesListView extends StatefulWidget {
  const NotesListView(
      {super.key, required this.notes, required this.onNotesChanged});

  final List<NoteFacade> notes;
  final Function() onNotesChanged;

  @override
  State<NotesListView> createState() => NotesListViewState();
}

class NotesListViewState extends State<NotesListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        var noteUpdator = widget.notes.elementAt(index);
        return Row(
          children: [
            Expanded(
              child: _NoteListItem(
                note: noteUpdator,
                onNoteChanged: () {
                  widget.onNotesChanged();
                },
              ),
            ),
            IconButton(
              onPressed: () {
                widget.notes.removeAt(index);
                widget.onNotesChanged();
                setState(() {});
              },
              icon: const Icon(Icons.delete),
            ),
          ],
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Padding(padding: EdgeInsets.symmetric(vertical: 3.0));
      },
      itemCount: widget.notes.length,
    );
  }
}

class _NoteListItem extends StatefulWidget {
  final NoteFacade note;
  final Function() onNoteChanged;

  const _NoteListItem({required this.note, required this.onNoteChanged});

  @override
  State<_NoteListItem> createState() => _NoteListItemState();
}

class _NoteListItemState extends State<_NoteListItem> {
  late TextEditingController _noteEditingController;

  @override
  void initState() {
    super.initState();
    _noteEditingController = TextEditingController(text: widget.note.note);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlatformCard(
          child: TextFormField(
            maxLines: null,
            controller: _noteEditingController,
            onChanged: (newValue) {
              if (newValue != widget.note.note) {
                widget.note.note = newValue;
                widget.onNoteChanged();
                setState(() {});
              }
            },
          ),
        ),
        AnimatedOpacity(
          opacity: widget.note.note != widget.note.note ? 1.0 : 0.0,
          duration: const Duration(seconds: 1),
          child: const Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: null,
              child: Icon(
                Icons.check_rounded,
              ),
            ),
          ),
        )
      ],
    );
  }
}
