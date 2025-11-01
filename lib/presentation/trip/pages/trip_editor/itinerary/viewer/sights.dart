import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/plan_data_edit_context.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// Tab content for managing sights (places) for a day's itinerary.
/// Allows adding, editing (location/time/description/expense), deleting sights.
class ItinerarySightsViewer extends StatelessWidget {
  final List<SightFacade> sights;
  final bool isLightTheme;
  final String tripId;
  final DateTime day;

  const ItinerarySightsViewer({
    super.key,
    required this.sights,
    required this.isLightTheme,
    required this.tripId,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    if (sights.isEmpty) {
      return _emptyState(context);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (c, i) {
        final s = sights[i];
        final subtitleParts = <String>[];
        if (s.visitTime != null) {
          subtitleParts.add(_formatTime(s.visitTime!));
        }
        if (s.location != null) {
          subtitleParts.add(s.location!.context.name);
        }
        final subtitle = subtitleParts.join(' • ');
        return Card(
          child: ListTile(
            title: Text(s.name.isEmpty
                ? (s.location?.context.name ?? 'Sight')
                : s.name),
            subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
            trailing: s.expense.totalExpense.amount > 0
                ? Text(s.expense.totalExpense.toString())
                : null,
            onTap: () => context.addTripManagementEvent(
              EditItineraryPlanData(
                day: day,
                planDataEditorConfig: UpdateItineraryPlanDataComponentConfig(
                  planDataType: PlanDataType.sight,
                  index: i,
                ),
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: sights.length,
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.place_outlined,
              size: 48, color: AppColors.neutral400),
          const SizedBox(height: 12),
          Text('No sights added',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Add places you plan to visit'),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text('Add Sight'),
            onPressed: () => context.addTripManagementEvent(
              EditItineraryPlanData(
                day: day,
                planDataEditorConfig: CreateNewItineraryPlanDataComponentConfig(
                  planDataType: PlanDataType.sight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
