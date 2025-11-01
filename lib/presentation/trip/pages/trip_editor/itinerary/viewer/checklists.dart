import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/plan_data_edit_context.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

class ItineraryChecklistTab extends StatefulWidget {
  final List<CheckListFacade> checklists;
  final bool isLightTheme;
  final VoidCallback onChanged;
  final DateTime day;

  const ItineraryChecklistTab({
    super.key,
    required this.checklists,
    required this.isLightTheme,
    required this.onChanged,
    required this.day,
  });

  @override
  State<ItineraryChecklistTab> createState() => _ItineraryChecklistTabState();
}

class _ItineraryChecklistTabState extends State<ItineraryChecklistTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.checklists.isEmpty) {
      return _emptyState(context);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (c, i) {
        final cl = widget.checklists[i];
        final title =
            cl.title?.trim().isEmpty ?? true ? 'Checklist' : cl.title!.trim();
        return Card(
          child: ListTile(
            title: Text(title),
            subtitle: Text('${cl.items.length} items'),
            onTap: () => context.addTripManagementEvent(
              EditItineraryPlanData(
                day: widget.day,
                planDataEditorConfig: UpdateItineraryPlanDataComponentConfig(
                  planDataType: PlanDataType.checklist,
                  index: i,
                ),
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: widget.checklists.length,
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.checklist_outlined,
              size: 48, color: AppColors.neutral400),
          const SizedBox(height: 12),
          Text('No checklists', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Add a checklist for this day'),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Checklist'),
            onPressed: () => context.addTripManagementEvent(
              EditItineraryPlanData(
                day: widget.day,
                planDataEditorConfig:
                    const CreateNewItineraryPlanDataComponentConfig(
                  planDataType: PlanDataType.checklist,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
