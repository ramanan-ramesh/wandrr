import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/trip_entity_update_handler.dart';

class ItineraryNotesViewer extends StatefulWidget {
  final DateTime day;

  const ItineraryNotesViewer({
    super.key,
    required this.day,
  });

  @override
  State<ItineraryNotesViewer> createState() => _ItineraryNotesViewerState();
}

class _ItineraryNotesViewerState extends State<ItineraryNotesViewer> {
  // Layout constants
  static const double _kPaddingAll = 16.0;
  static const double _kSpacingSmall = 4.0;
  static const double _kSpacingMedium = 12.0;
  static const double _kSpacingLarge = 16.0;
  static const double _kEmptyIconSize = 48.0;

  @override
  Widget build(BuildContext context) {
    return TripEntityUpdateHandler<ItineraryPlanData>(
      shouldRebuild: (beforeUpdate, afterUpdate) {
        var isItineraryPlanDataUpdated =
            beforeUpdate.day.isOnSameDayAs(widget.day) ||
                afterUpdate.day.isOnSameDayAs(widget.day);
        if (isItineraryPlanDataUpdated) {
          var notesBeforeUpdate = beforeUpdate.notes;
          var notesAfterUpdate = afterUpdate.notes;
          return !listEquals(notesBeforeUpdate, notesAfterUpdate);
        }
        return false;
      },
      widgetBuilder: (context) {
        var notes = context.activeTrip.itineraryCollection
            .getItineraryForDay(widget.day)
            .planData
            .notes;
        // Read-only list
        if (notes.isEmpty) {
          return _emptyState(context, context.localizations.noNotesCreated,
              context.localizations.addNotesForThisDay, Icons.note_outlined);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(_kPaddingAll),
          itemCount: notes.length,
          itemBuilder: (ctx, i) {
            final note = notes[i];
            final raw = note.trim();
            final title =
                raw.isEmpty ? 'Untitled' : raw.split('\n').first.trim();
            final preview = raw.replaceAll('\n', ' ');
            final isLightTheme = Theme.of(ctx).brightness == Brightness.light;

            return Container(
              margin: EdgeInsets.only(
                  bottom: i < notes.length - 1 ? _kSpacingMedium : 0),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? Colors.white
                    : AppColors.darkSurface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.brandPrimary.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isLightTheme ? 0.06 : 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.addTripManagementEvent(
                    EditItineraryPlanData(
                      day: widget.day,
                      planDataEditorConfig:
                          UpdateItineraryPlanDataComponentConfig(
                        planDataType: PlanDataType.note,
                        index: i,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? 'Untitled' : title,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isLightTheme
                                          ? AppColors.neutral900
                                          : AppColors.neutral100,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (preview.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  preview,
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: isLightTheme
                                            ? AppColors.neutral600
                                            : AppColors.neutral400,
                                        height: 1.4,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isLightTheme
                              ? AppColors.neutral400
                              : AppColors.neutral500,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
          Icon(icon, size: _kEmptyIconSize, color: AppColors.neutral400),
          const SizedBox(height: _kSpacingMedium),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: _kSpacingSmall),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: _kSpacingLarge),
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
