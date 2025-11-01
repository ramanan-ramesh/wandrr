import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/plan_data_edit_context.dart';
import 'package:wandrr/data/trip/models/itinerary/note.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

class ItineraryNotesViewer extends StatefulWidget {
  final List<NoteFacade> notes;
  final DateTime day;

  const ItineraryNotesViewer({
    super.key,
    required this.notes,
    required this.day,
  });

  @override
  State<ItineraryNotesViewer> createState() => _ItineraryNotesViewerState();
}

class _ItineraryNotesViewerState extends State<ItineraryNotesViewer> {
  @override
  Widget build(BuildContext context) {
    // Read-only list
    if (widget.notes.isEmpty) {
      return _emptyState(context, 'No notes yet', 'Add notes for this day',
          Icons.note_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.notes.length,
      itemBuilder: (ctx, i) {
        final note = widget.notes[i];
        final raw = note.note.trim();
        final title = raw.isEmpty ? 'Untitled' : raw.split('\n').first.trim();
        final preview = raw.replaceAll('\n', ' ');
        return Card(
          child: ListTile(
            title: Text(title.isEmpty ? 'Untitled' : title),
            subtitle: Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => context.addTripManagementEvent(
              EditItineraryPlanData(
                day: widget.day,
                planDataEditorConfig: UpdateItineraryPlanDataComponentConfig(
                  planDataType: PlanDataType.note,
                  index: i,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(
      BuildContext context, String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.neutral400),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Note'),
            onPressed: () =>
                context.addTripManagementEvent(EditItineraryPlanData(
              day: widget.day,
              planDataEditorConfig: CreateNewItineraryPlanDataComponentConfig(
                  planDataType: PlanDataType.note),
            )),
          ),
        ],
      ),
    );
  }
}
