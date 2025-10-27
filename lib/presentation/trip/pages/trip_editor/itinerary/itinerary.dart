import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'tab_indicator.dart';
import 'timeline_event.dart';

class Itinerary extends StatefulWidget {
  final DateTime itineraryDay;

  const Itinerary({required this.itineraryDay, super.key});

  @override
  State<Itinerary> createState() => _ItineraryState();
}

class _ItineraryState extends State<Itinerary>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transitOptionMetadatas = context.activeTrip.transitOptionMetadatas;
    final appLocalizations = context.localizations;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        final itinerary = context.activeTrip.itineraryCollection
            .getItineraryForDay(widget.itineraryDay);

        // Collect all events
        final timelineEvents = <TimelineEvent>[];

        // Add lodging events
        timelineEvents
            .addAll(_createLodgingEvents(itinerary, appLocalizations));

        // Add transit events
        timelineEvents.addAll(_createTransitEvents(itinerary.transits.toList(),
            transitOptionMetadatas, appLocalizations));

        // Add only timed sight events to timeline
        timelineEvents.addAll(_createTimedSightEvents(
            itinerary.planData.sights, appLocalizations));

        // Sort timeline events by time
        timelineEvents.sort((a, b) {
          if (a.time == null && b.time == null) return 0;
          if (a.time == null) return 1;
          if (b.time == null) return -1;
          return a.time!.compareTo(b.time!);
        });

        return Column(
          children: [
            _createTabIndicators(context, isLightTheme, itinerary),
            Expanded(
              child: ColoredBox(
                color:
                    isLightTheme ? Colors.white : AppColors.darkSurfaceVariant,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildModernTimeline(
                      context,
                      timelineEvents,
                      appLocalizations,
                    ),
                    _buildNotesTab(context, itinerary, isLightTheme),
                    _buildChecklistsTab(context, itinerary, isLightTheme),
                    _buildPlacesTab(
                        context, itinerary.planData.sights, isLightTheme),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      buildWhen: _shouldRebuild,
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _createTabIndicators(
    BuildContext context,
    bool isLightTheme,
    itinerary,
  ) {
    final selectedColor =
        isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight;
    final unselectedColor =
        isLightTheme ? AppColors.neutral600 : AppColors.neutral400;
    final tabBgColor =
        isLightTheme ? AppColors.neutral200 : AppColors.darkSurface;
    final contentBgColor =
        isLightTheme ? Colors.white : AppColors.darkSurfaceVariant;
    final sideBorderColor =
        isLightTheme ? AppColors.neutral400 : AppColors.neutral600;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tabBgColor,
        border: Border(
          bottom: BorderSide(
            color: isLightTheme ? AppColors.neutral300 : AppColors.neutral700,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: selectedColor,
        unselectedLabelColor: unselectedColor,
        indicator: ItineraryTabIndicator(
          backgroundColor: contentBgColor,
          topBorderColor: selectedColor,
          sideBorderColor: sideBorderColor,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor:
            isLightTheme ? AppColors.neutral300 : AppColors.neutral700,
        dividerHeight: 1,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        labelPadding: EdgeInsets.zero,
        tabs: const [
          Tab(
            icon: Icon(Icons.timeline, size: 20),
            text: 'Timeline',
            height: 72,
          ),
          Tab(
            icon: Icon(Icons.note_outlined, size: 20),
            text: 'Notes',
            height: 72,
          ),
          Tab(
            icon: Icon(Icons.checklist_outlined, size: 20),
            text: 'Checklists',
            height: 72,
          ),
          Tab(
            icon: Icon(Icons.place_outlined, size: 20),
            text: 'Places',
            height: 72,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(
    BuildContext context,
    itinerary,
    bool isLightTheme,
  ) {
    final notes = itinerary.planData.notes;

    if (notes.isEmpty) {
      return _buildEmptyTabState(
        context,
        Icons.note_outlined,
        'No notes for this day',
        'Add notes to remember important details',
        isLightTheme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteCard(context, note, isLightTheme);
      },
    );
  }

  Widget _buildChecklistsTab(
    BuildContext context,
    itinerary,
    bool isLightTheme,
  ) {
    final checkLists = itinerary.planData.checkLists;

    if (checkLists.isEmpty) {
      return _buildEmptyTabState(
        context,
        Icons.checklist_outlined,
        'No checklists for this day',
        'Create checklists to stay organized',
        isLightTheme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: checkLists.length,
      itemBuilder: (context, index) {
        final checkList = checkLists[index];
        return _buildChecklistCard(context, checkList, isLightTheme);
      },
    );
  }

  Widget _buildPlacesTab(
    BuildContext context,
    List<SightFacade> sights,
    bool isLightTheme,
  ) {
    if (sights.isEmpty) {
      return _buildEmptyTabState(
        context,
        Icons.place_outlined,
        'No places for this day',
        'Add places you want to visit',
        isLightTheme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sights.length,
      itemBuilder: (context, index) {
        final sight = sights[index];
        return _buildPlaceCard(context, sight, isLightTheme);
      },
    );
  }

  Widget _buildEmptyTabState(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isLightTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: isLightTheme ? AppColors.neutral400 : AppColors.neutral600,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isLightTheme
                        ? AppColors.neutral600
                        : AppColors.neutral400,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isLightTheme
                        ? AppColors.neutral500
                        : AppColors.neutral500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, note, bool isLightTheme) {
    final cardBgColor =
        isLightTheme ? AppColors.lightSurface : AppColors.darkSurface;
    final textColor =
        isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;
    final subtitleColor =
        isLightTheme ? AppColors.neutral600 : AppColors.neutral400;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLightTheme ? AppColors.neutral300 : AppColors.neutral600,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLightTheme ? AppColors.brandPrimary : Colors.black)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.note_outlined,
              color: AppColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.title != null && note.title.isNotEmpty) ...[
                  Text(
                    note.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  note.description ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(
    BuildContext context,
    checkList,
    bool isLightTheme,
  ) {
    final cardBgColor =
        isLightTheme ? AppColors.lightSurface : AppColors.darkSurface;
    final textColor =
        isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLightTheme ? AppColors.neutral300 : AppColors.neutral600,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLightTheme ? AppColors.brandPrimary : Colors.black)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.checklist_outlined,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  checkList.title ?? 'Checklist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...checkList.items.map((item) => _buildChecklistItem(
                context,
                item,
                isLightTheme,
              )),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    BuildContext context,
    item,
    bool isLightTheme,
  ) {
    final textColor =
        isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            item.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: item.isCompleted ? AppColors.success : AppColors.neutral400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.description ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    decoration:
                        item.isCompleted ? TextDecoration.lineThrough : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(
    BuildContext context,
    SightFacade sight,
    bool isLightTheme,
  ) {
    final cardBgColor =
        isLightTheme ? AppColors.lightSurface : AppColors.darkSurface;
    final textColor =
        isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;
    final subtitleColor =
        isLightTheme ? AppColors.neutral600 : AppColors.neutral400;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandAccent.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.place_rounded,
                  color: AppColors.brandAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sight.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                    ),
                    if (sight.visitTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: subtitleColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(sight.visitTime),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: subtitleColor,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_getSightSubtitle(sight).isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: subtitleColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSightSubtitle(sight),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: subtitleColor,
                        ),
                  ),
                ),
              ],
            ),
          ],
          if (sight.description != null && sight.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              sight.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: subtitleColor,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Iterable<TimelineEvent> _createLodgingEvents(
    ItineraryFacade itinerary,
    AppLocalizations appLocalizations,
  ) sync* {
    if (itinerary.fullDayLodging != null) {
      final lodging = itinerary.fullDayLodging!;
      yield TimelineEvent(
        type: ItineraryEventType.lodging,
        time: lodging.checkinDateTime,
        title: appLocalizations.allDayStay,
        subtitle: _getLodgingLocation(lodging),
        icon: Icons.hotel_rounded,
        iconColor: AppColors.brandPrimary,
        data: lodging,
      );
    } else {
      if (itinerary.checkoutLodging != null) {
        final lodging = itinerary.checkoutLodging!;
        yield TimelineEvent(
          type: ItineraryEventType.lodging,
          time: lodging.checkoutDateTime,
          title:
              '${appLocalizations.checkOut} • ${_formatTime(lodging.checkoutDateTime)}',
          subtitle: _getLodgingLocation(lodging),
          icon: Icons.logout,
          iconColor: AppColors.warning,
          data: lodging,
        );
      }

      if (itinerary.checkinLodging != null) {
        final lodging = itinerary.checkinLodging!;
        yield TimelineEvent(
          type: ItineraryEventType.lodging,
          time: lodging.checkinDateTime,
          title:
              '${appLocalizations.checkIn} • ${_formatTime(lodging.checkinDateTime)}',
          subtitle: _getLodgingLocation(lodging),
          icon: Icons.login,
          iconColor: AppColors.success,
          data: lodging,
        );
      }
    }
  }

  Iterable<TimelineEvent> _createTransitEvents(
    List<TransitFacade> transits,
    Iterable<TransitOptionMetadata> transitOptionMetadatas,
    AppLocalizations appLocalizations,
  ) sync* {
    for (final transit in transits) {
      final metadata = transitOptionMetadatas.firstWhere(
        (e) => e.transitOption == transit.transitOption,
      );

      final departureDateTime = transit.departureDateTime!;
      final arrivalDateTime = transit.arrivalDateTime!;
      final isDepartingToday =
          departureDateTime.isOnSameDayAs(widget.itineraryDay);
      final isArrivingToday =
          arrivalDateTime.isOnSameDayAs(widget.itineraryDay);

      String title;
      DateTime eventTime;

      if (isDepartingToday && isArrivingToday) {
        // Same day journey
        title =
            '${_getTransitLocationDetail(transit)} • ${_formatTime(departureDateTime)} - ${_formatTime(arrivalDateTime)}';
        eventTime = departureDateTime;
      } else if (isDepartingToday && !isArrivingToday) {
        // Overnight journey departing today
        title =
            '${appLocalizations.departAt} ${_formatTime(departureDateTime)} → ${_getDestinationName(transit)}';
        eventTime = departureDateTime;
      } else {
        // Overnight journey arriving today
        title =
            '${appLocalizations.arriveAt} ${_formatTime(arrivalDateTime)} from ${_getOriginName(transit)}';
        eventTime = arrivalDateTime;
      }

      yield TimelineEvent(
        type: ItineraryEventType.transit,
        time: eventTime,
        title: title,
        subtitle: _getTransitOperatorInfo(transit),
        icon: metadata.icon,
        iconColor: AppColors.info,
        data: transit,
      );
    }
  }

  Iterable<TimelineEvent> _createTimedSightEvents(
    List<SightFacade> sights,
    AppLocalizations appLocalizations,
  ) sync* {
    for (final sight in sights) {
      // Only add sights that have a visit time to the timeline
      if (sight.visitTime != null) {
        final subtitle = _getSightSubtitle(sight);

        final event = TimelineEvent(
          type: ItineraryEventType.sight,
          time: sight.visitTime,
          title: '${sight.name} • ${_formatTime(sight.visitTime)}',
          subtitle: subtitle,
          icon: Icons.place_rounded,
          iconColor: AppColors.brandAccent,
          data: sight,
        );

        yield event;
      }
    }
  }

  Widget _buildModernTimeline(
    BuildContext context,
    List<TimelineEvent> timelineEvents,
    AppLocalizations appLocalizations,
  ) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    if (timelineEvents.isEmpty) {
      return _buildEmptyState(context, appLocalizations);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline events
          const SizedBox(height: 16),
          ...timelineEvents.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final isLast = index == timelineEvents.length - 1;
            return _buildTimelineItem(context, event, isLast, isLightTheme);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    TimelineEvent event,
    bool isLast,
    bool isLightTheme,
  ) {
    final iconBgColor = isLightTheme
        ? event.iconColor.withValues(alpha: 0.15)
        : event.iconColor.withValues(alpha: 0.25);
    final cardBgColor = isLightTheme ? Colors.white : AppColors.darkSurface;
    final timelineColor = isLightTheme
        ? AppColors.brandPrimary.withValues(alpha: 0.5)
        : AppColors.brandPrimaryLight.withValues(alpha: 0.3);
    final textColor =
        isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;
    final subtitleColor =
        isLightTheme ? AppColors.neutral700 : AppColors.neutral400;

    return IntrinsicHeight(
      child: GestureDetector(
        onTap: () => event.onPressed(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline connector
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: event.iconColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: event.iconColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      event.icon,
                      color: event.iconColor,
                      size: 24,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: isLightTheme ? 4 : 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: timelineColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Event card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8, bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLightTheme
                        ? AppColors.neutral400
                        : AppColors.neutral600,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isLightTheme ? AppColors.brandPrimary : Colors.black)
                              .withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                    ),
                    if (event.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        event.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: subtitleColor,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, AppLocalizations appLocalizations) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: isLightTheme ? AppColors.neutral400 : AppColors.neutral600,
            ),
            const SizedBox(height: 16),
            Text(
              'No events scheduled for this day',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isLightTheme
                        ? AppColors.neutral600
                        : AppColors.neutral400,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return dateTime.hourMinuteAmPmFormat;
  }

  String _getLodgingLocation(LodgingFacade lodging) {
    final locationDetail = lodging.location!.context.name;
    final lodgingCity = lodging.location!.context.city;
    return lodgingCity != null
        ? '$locationDetail, $lodgingCity'
        : locationDetail;
  }

  String _getTransitLocationDetail(TransitFacade transit) {
    final departureLocation = transit.transitOption == TransitOption.flight
        ? (transit.departureLocation!.context as AirportLocationContext).city
        : transit.departureLocation.toString();
    final arrivalLocation = transit.transitOption == TransitOption.flight
        ? (transit.arrivalLocation!.context as AirportLocationContext).city
        : transit.arrivalLocation.toString();
    return '$departureLocation → $arrivalLocation';
  }

  String _getOriginName(TransitFacade transit) {
    return transit.transitOption == TransitOption.flight
        ? (transit.departureLocation!.context as AirportLocationContext).city
        : transit.departureLocation.toString();
  }

  String _getDestinationName(TransitFacade transit) {
    return transit.transitOption == TransitOption.flight
        ? (transit.arrivalLocation!.context as AirportLocationContext).city
        : transit.arrivalLocation.toString();
  }

  String _getTransitOperatorInfo(TransitFacade transit) {
    return transit.operator ?? '';
  }

  String _getSightSubtitle(SightFacade sight) {
    final parts = <String>[];

    // Add location if available
    if (sight.location != null) {
      final locationName = sight.location!.context.name;
      final locationCity = sight.location!.context.city;
      if (locationCity != null) {
        parts.add('$locationName, $locationCity');
      } else {
        parts.add(locationName);
      }
    }

    // Add expense if available
    if (sight.expense.totalExpense.amount > 0) {
      parts.add(sight.expense.totalExpense.toString());
    }

    return parts.join(' • ');
  }

  bool _shouldRebuild(
    TripManagementState previousState,
    TripManagementState currentState,
  ) {
    if (currentState.isTripEntityUpdated<LodgingFacade>()) {
      final currentLodgingState = currentState as UpdatedTripEntity;
      final updatedLodging = currentLodgingState
          .tripEntityModificationData.modifiedCollectionItem as LodgingFacade;

      if (currentLodgingState.dataState == DataState.create ||
          currentLodgingState.dataState == DataState.delete ||
          currentLodgingState.dataState == DataState.update) {
        return updatedLodging.checkinDateTime!
                .isOnSameDayAs(widget.itineraryDay) ||
            updatedLodging.checkoutDateTime!.isOnSameDayAs(widget.itineraryDay);
      }
    }

    if (currentState.isTripEntityUpdated<TransitFacade>()) {
      final currentTransitState = currentState as UpdatedTripEntity;
      final updatedTransit = currentTransitState
          .tripEntityModificationData.modifiedCollectionItem as TransitFacade;

      if (currentTransitState.dataState == DataState.create ||
          currentTransitState.dataState == DataState.delete ||
          currentTransitState.dataState == DataState.update) {
        final isItineraryDayOnOrAfterDeparture = widget.itineraryDay
                .isAtSameMomentAs(updatedTransit.departureDateTime!) ||
            widget.itineraryDay.isAfter(updatedTransit.departureDateTime!);
        final isItineraryDayOnOrBeforeArrival = widget.itineraryDay
                .isAtSameMomentAs(updatedTransit.arrivalDateTime!) ||
            widget.itineraryDay.isBefore(updatedTransit.arrivalDateTime!);
        return isItineraryDayOnOrAfterDeparture &&
            isItineraryDayOnOrBeforeArrival;
      }
    }

    if (currentState.isTripEntityUpdated<SightFacade>()) {
      final currentSightState = currentState as UpdatedTripEntity;
      final updatedSight = currentSightState
          .tripEntityModificationData.modifiedCollectionItem as SightFacade;

      if (currentSightState.dataState == DataState.create ||
          currentSightState.dataState == DataState.delete ||
          currentSightState.dataState == DataState.update) {
        // Rebuild if the sight is for this day
        return updatedSight.day.isOnSameDayAs(widget.itineraryDay);
      }
    }

    return false;
  }
}
