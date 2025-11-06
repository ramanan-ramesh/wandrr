import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/checklists.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/notes.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/chrome_tab.dart';

import 'timeline_event.dart';
import 'viewer/sights.dart';

class ItineraryViewer extends StatefulWidget {
  final DateTime itineraryDay;

  const ItineraryViewer({required this.itineraryDay, super.key});

  @override
  State<ItineraryViewer> createState() => _ItineraryViewerState();
}

class _ItineraryViewerState extends State<ItineraryViewer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const double _kTimelineIconSize = 24;
  static const double _kTimelineIconContainerSize = 48;
  static const double _kTimelineConnectorWidth = 4;
  static const double _kTimelineCardBorderWidth = 1.5;
  static const double _kTimelineCardRadius = 16;
  static const double _kTimelineCardPadding = 16;
  static const double _kTimelineSpacing = 16;

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
    final isLightTheme = context.isLightTheme;

    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldRebuild,
      listener: (BuildContext context, TripManagementState state) {},
      builder: (BuildContext context, TripManagementState state) {
        final itinerary = context.activeTrip.itineraryCollection
            .getItineraryForDay(widget.itineraryDay);

        final timelineEvents = _collectTimelineEvents(itinerary);

        var itineraryPlanData = itinerary.planData;
        return Column(
          children: [
            _createTabIndicators(),
            Expanded(
              child: ColoredBox(
                color:
                    isLightTheme ? Colors.white : AppColors.darkSurfaceVariant,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTimeline(timelineEvents),
                    ItineraryNotesViewer(
                      notes: itineraryPlanData.notes,
                      day: widget.itineraryDay,
                    ),
                    ItineraryChecklistTab(
                      checklists: itineraryPlanData.checkLists,
                      onChanged: () {},
                      day: widget.itineraryDay,
                    ),
                    ItinerarySightsViewer(
                      sights: itineraryPlanData.sights,
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

  Widget _createTabIndicators() {
    return ChromeTabBar(
      iconsAndTitles: {
        Icons.timeline: 'Timeline',
        Icons.note_outlined: 'Notes',
        Icons.checklist_outlined: 'Checklists',
        Icons.place_outlined: 'Places',
      },
      tabController: _tabController,
    );
  }

  //TODO: If there is no activity to display in the timeline, provide options to add a transit/lodging/sight.
  Widget _buildTimeline(
    List<TimelineEvent> timelineEvents,
  ) {
    if (timelineEvents.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: _kTimelineSpacing),
          ...timelineEvents.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final isLast = index == timelineEvents.length - 1;
            return _buildTimelineItem(
              event,
              isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    TimelineEvent event,
    bool isLast,
  ) {
    final isLightTheme = context.isLightTheme;
    final Color iconBgColor = isLightTheme
        ? event.iconColor.withValues(alpha: 0.15)
        : event.iconColor.withValues(alpha: 0.25);
    final Color cardBgColor =
        isLightTheme ? Colors.white : AppColors.darkSurface;
    final Color timelineColor = isLightTheme
        ? AppColors.brandPrimary.withValues(alpha: 0.5)
        : AppColors.brandPrimaryLight.withValues(alpha: 0.3);
    final Color textColor =
        isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;
    final Color subtitleColor =
        isLightTheme ? AppColors.neutral700 : AppColors.neutral400;

    return IntrinsicHeight(
      child: GestureDetector(
        onTap: () => event.onPressed(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Container(
                    width: _kTimelineIconContainerSize,
                    height: _kTimelineIconContainerSize,
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
                      size: _kTimelineIconSize,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: _kTimelineConnectorWidth,
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
            Expanded(
              child: Container(
                margin:
                    const EdgeInsets.only(left: 8, bottom: _kTimelineSpacing),
                padding: const EdgeInsets.all(_kTimelineCardPadding),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(_kTimelineCardRadius),
                  border: Border.all(
                    color: isLightTheme
                        ? AppColors.neutral400
                        : AppColors.neutral600,
                    width: _kTimelineCardBorderWidth,
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

  Widget _buildEmptyState() {
    final bool isLightTheme = context.isLightTheme;
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

  List<TimelineEvent> _collectTimelineEvents(ItineraryFacade itinerary) {
    final List<TimelineEvent> timelineEvents = [];
    timelineEvents.addAll(_createLodgingEvents(itinerary));
    timelineEvents.addAll(
      _createTransitEvents(
        itinerary.transits.toList(),
      ),
    );
    timelineEvents.addAll(_createTimedSightEvents(itinerary.planData.sights));
    timelineEvents
        .sort((TimelineEvent a, TimelineEvent b) => a.time.compareTo(b.time));
    return timelineEvents;
  }

  Iterable<TimelineEvent> _createLodgingEvents(
    ItineraryFacade itinerary,
  ) sync* {
    final LodgingFacade? fullDay = itinerary.fullDayLodging;
    var localizations = context.localizations;
    if (fullDay != null) {
      yield TimelineEvent<LodgingFacade>(
        time: fullDay.checkinDateTime!,
        title: localizations.allDayStay,
        subtitle: _getLodgingLocationDetail(fullDay),
        icon: Icons.hotel_rounded,
        iconColor: AppColors.brandPrimary,
        data: fullDay,
      );
      return;
    }

    final LodgingFacade? checkout = itinerary.checkoutLodging;
    if (checkout != null) {
      yield TimelineEvent<LodgingFacade>(
        time: checkout.checkoutDateTime!,
        title:
            '${localizations.checkOut} • ${checkout.checkoutDateTime!.hourMinuteAmPmFormat}',
        subtitle: _getLodgingLocationDetail(checkout),
        icon: Icons.logout,
        iconColor: AppColors.warning,
        data: checkout,
      );
    }

    final LodgingFacade? checkin = itinerary.checkinLodging;
    if (checkin != null) {
      yield TimelineEvent<LodgingFacade>(
        time: checkin.checkinDateTime!,
        title:
            '${localizations.checkIn} • ${checkin.checkinDateTime!.hourMinuteAmPmFormat}',
        subtitle: _getLodgingLocationDetail(checkin),
        icon: Icons.login,
        iconColor: AppColors.success,
        data: checkin,
      );
    }
  }

  Iterable<TimelineEvent> _createTransitEvents(
    Iterable<TransitFacade> transits,
  ) sync* {
    for (final transit in transits) {
      final metadata = context.activeTrip.transitOptionMetadatas.firstWhere(
        (e) => e.transitOption == transit.transitOption,
      );
      final departure = transit.departureDateTime!;
      final arrival = transit.arrivalDateTime!;
      final isDepartingToday = departure.isOnSameDayAs(widget.itineraryDay);
      final isArrivingToday = arrival.isOnSameDayAs(widget.itineraryDay);
      final localizations = context.localizations;

      String title;
      DateTime eventTime;
      if (isDepartingToday && isArrivingToday) {
        title =
            '${_getTransitLocationDetail(transit)} • ${departure.hourMinuteAmPmFormat} - ${arrival.hourMinuteAmPmFormat}';
        eventTime = departure;
      } else if (isDepartingToday) {
        title =
            '${localizations.departAt} ${departure.hourMinuteAmPmFormat} → ${_getDestinationName(transit)}';
        eventTime = departure;
      } else {
        title =
            '${localizations.arriveAt} ${arrival.hourMinuteAmPmFormat} from ${_getOriginName(transit)}';
        eventTime = arrival;
      }

      yield TimelineEvent<TransitFacade>(
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
  ) sync* {
    for (final sight in sights) {
      final visitTime = sight.visitTime;
      if (visitTime == null) {
        continue;
      }

      yield TimelineEvent<SightFacade>(
        time: visitTime,
        title: '${sight.name} • ${visitTime.hourMinuteAmPmFormat}',
        subtitle: _getSightSubtitle(sight),
        icon: Icons.place_rounded,
        iconColor: AppColors.brandAccent,
        data: sight,
      );
    }
  }

  String _getLodgingLocationDetail(LodgingFacade lodging) {
    final locationDetail = lodging.location!.context.name;
    final lodgingCity = lodging.location!.context.city;
    return (lodgingCity != null && lodgingCity != locationDetail)
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

  String _getOriginName(TransitFacade transit) =>
      transit.transitOption == TransitOption.flight
          ? (transit.departureLocation!.context as AirportLocationContext).city
          : transit.departureLocation.toString();

  String _getDestinationName(TransitFacade transit) =>
      transit.transitOption == TransitOption.flight
          ? (transit.arrivalLocation!.context as AirportLocationContext).city
          : transit.arrivalLocation.toString();

  String _getTransitOperatorInfo(TransitFacade transit) =>
      transit.operator ?? '';

  String _getSightSubtitle(SightFacade sight) {
    final parts = <String>[];
    final location = sight.location?.context;
    if (location != null) {
      final locationName = location.name;
      final locationCity = location.city;
      parts.add(
          locationCity != null ? '$locationName, $locationCity' : locationName);
    }
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
      return !_isCrudChange(currentState as UpdatedTripEntity);
    }
    if (currentState.isTripEntityUpdated<TransitFacade>()) {
      return !_isCrudChange(currentState as UpdatedTripEntity);
    }
    if (currentState.isTripEntityUpdated<SightFacade>()) {
      return !_isCrudChange(currentState as UpdatedTripEntity);
    }
    return false;
  }

  bool _isCrudChange(UpdatedTripEntity state) =>
      state.dataState == DataState.create ||
      state.dataState == DataState.delete ||
      state.dataState == DataState.update;
}
