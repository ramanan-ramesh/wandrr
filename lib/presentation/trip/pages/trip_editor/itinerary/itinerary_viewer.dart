import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_event_factory.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_rebuild_helper.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_theme_helper.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/checklists.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/notes.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/sights.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/widgets/timeline_item_widget.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/chrome_tab.dart';

import 'timeline_event.dart';

/// Main widget for displaying and managing the itinerary for a specific day
class ItineraryViewer extends StatefulWidget {
  final DateTime itineraryDay;

  const ItineraryViewer({required this.itineraryDay, super.key});

  @override
  State<ItineraryViewer> createState() => _ItineraryViewerState();
}

class _ItineraryViewerState extends State<ItineraryViewer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late TimelineRebuildHelper _rebuildHelper;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _rebuildHelper = TimelineRebuildHelper(widget.itineraryDay);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

        return Column(
          children: [
            _buildTabIndicators(),
            Expanded(
              child: ColoredBox(
                color: context.isLightTheme
                    ? Colors.white
                    : AppColors.darkSurfaceVariant,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTimeline(timelineEvents),
                    ItineraryNotesViewer(day: widget.itineraryDay),
                    ItineraryChecklistTab(
                      onChanged: () {},
                      day: widget.itineraryDay,
                    ),
                    ItinerarySightsViewer(
                      tripId: context.activeTripId,
                      day: widget.itineraryDay,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabIndicators() {
    return ChromeTabBar(
      iconsAndTitles: {
        Icons.timeline: context.localizations.timeline,
        Icons.note_outlined: context.localizations.notes,
        Icons.checklist_outlined: context.localizations.checklists,
        Icons.place_outlined: context.localizations.places,
      },
      tabController: _tabController,
    );
  }

  Widget _buildTimeline(List<TimelineEvent> timelineEvents) {
    if (timelineEvents.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ...timelineEvents.asMap().entries.map((entry) {
            final isLast = entry.key == timelineEvents.length - 1;
            return TimelineItemWidget(
              event: entry.value,
              isLast: isLast,
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
              size: 80,
              color: themeHelper.getEmptyStateIconColor(),
            ),
            const SizedBox(height: 16),
            Text(
              'No events scheduled for this day',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: themeHelper.getEmptyStateTextColor(),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
