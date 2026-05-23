import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_event_factory.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_rebuild_helper.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_theme_helper.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/transit_journey_timeline_event.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/animated_list_item.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/widgets/timeline_item.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/widgets/transit_journey_timeline_item.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/shimmer_placeholder.dart';

import 'timeline_event.dart';

/// Timeline-only view for a specific itinerary day.
/// Tab management is handled by [ItineraryNavigator].
class ItineraryViewer extends StatefulWidget {
  final DateTime itineraryDay;

  const ItineraryViewer({required this.itineraryDay, super.key});

  @override
  State<ItineraryViewer> createState() => _ItineraryViewerState();
}

class _ItineraryViewerState extends State<ItineraryViewer> {
  late TimelineRebuildHelper _rebuildHelper;

  @override
  void initState() {
    super.initState();
    _rebuildHelper = TimelineRebuildHelper(widget.itineraryDay);
  }

  @override
  void didUpdateWidget(covariant ItineraryViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.itineraryDay.isOnSameDayAs(widget.itineraryDay)) {
      _rebuildHelper = TimelineRebuildHelper(widget.itineraryDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _rebuildHelper.shouldRebuild,
      listener: (context, state) {},
      builder: (context, state) {
        final itinerary = context.activeTrip.itineraryCollection
            .getItineraryForDay(widget.itineraryDay);

        final eventFactory = TimelineEventFactory(
          context: context,
          itineraryDay: widget.itineraryDay,
        );
        final timelineEvents = eventFactory.collectTimelineEvents(itinerary);

        return StreamBuilder<bool>(
          stream: context.tripRepository.activeTrip!.isFullyLoaded,
          initialData: context.tripRepository.activeTrip!.isFullyLoadedValue,
          builder: (ctx, snap) {
            final isLoaded = snap.data ?? false;
            return _buildTimeline(timelineEvents, isLoaded);
          },
        );
      },
    );
  }

  Widget _buildTimeline(List<TimelineEvent> timelineEvents, bool isLoaded) {
    final isLight = context.isLightTheme;
    final accentColor =
        isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight;

    // Show shimmer skeleton while data is loading and no events yet arrived
    if (!isLoaded && timelineEvents.isEmpty) {
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(
          12,
          16,
          12,
          MediaQuery.of(context).padding.bottom,
        ),
        itemCount: 5,
        itemBuilder: (_, i) {
          final h = 72.0 + (i % 3) * 28.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline connector
                Column(
                  children: [
                    ShimmerPlaceholder(
                      width: 12,
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    if (i < 4)
                      Container(
                        width: 2,
                        height: h - 12,
                        color: accentColor.withValues(alpha: 0.15),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShimmerPlaceholder(
                    height: h,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (timelineEvents.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...timelineEvents.asMap().entries.map((entry) {
            final isLast = entry.key == timelineEvents.length - 1;
            final event = entry.value;

            Widget item;
            // Use TransitJourneyTimelineItem for connected transit legs
            if (event is TransitJourneyTimelineEvent) {
              item = TransitJourneyTimelineItem(
                event: event,
                isLastInTimeline: isLast,
              );
            } else {
              item = TimelineItem(
                event: event,
                isLast: isLast,
              );
            }

            return AnimatedListItem(
              index: entry.key,
              child: item,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeHelper = TimelineThemeHelper(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: themeHelper.getEmptyStateIconColor(),
            ),
            const SizedBox(height: 12),
            Text(
              context.localizations.noEventsScheduled,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeHelper.getEmptyStateTextColor(),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
