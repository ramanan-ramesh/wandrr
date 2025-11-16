import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/plan_data_edit_context.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
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
  static const int _kNotesMaxLength = 150;

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
                      day: widget.itineraryDay,
                    ),
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
    return IntrinsicHeight(
      child: GestureDetector(
        onTap: () => event.onPressed(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineIconColumn(event, isLast),
            Expanded(child: _buildEventCard(event)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineIconColumn(TimelineEvent event, bool isLast) {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          _buildTimelineIcon(event),
          if (!isLast) _buildTimelineConnector(),
        ],
      ),
    );
  }

  Widget _buildTimelineIcon(TimelineEvent event) {
    return Container(
      width: _kTimelineIconContainerSize,
      height: _kTimelineIconContainerSize,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(event.iconColor),
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
    );
  }

  Widget _buildTimelineConnector() {
    return Expanded(
      child: Container(
        width: _kTimelineConnectorWidth,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: _getTimelineConnectorColor(),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildEventCard(TimelineEvent event) {
    return Container(
      margin: const EdgeInsets.only(left: 8, bottom: _kTimelineSpacing),
      padding: const EdgeInsets.all(_kTimelineCardPadding),
      decoration: BoxDecoration(
        color: _getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(_kTimelineCardRadius),
        border: Border.all(
          color: _getCardBorderColor(),
          width: _kTimelineCardBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: _getCardShadowColor(),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEventHeader(event),
          if (event.subtitle.isNotEmpty) _buildEventSubtitle(event.subtitle),
          if (event.confirmationId?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            _buildConfirmationChip(event.confirmationId!),
            const SizedBox(height: 8),
          ],
          if (event.notes?.isNotEmpty ?? false) _buildEventNotes(event.notes!),
        ],
      ),
    );
  }

  Widget _buildConfirmationChip(String confirmationId) {
    final isLightTheme = context.isLightTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: isLightTheme ? 0.12 : 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withValues(alpha: isLightTheme ? 0.4 : 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number_rounded,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              confirmationId,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventHeader(TimelineEvent event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            event.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getTextColor(),
                ),
          ),
        ),
        const SizedBox(width: 8),
        _buildDeleteButton(event),
      ],
    );
  }

  Widget _buildDeleteButton(TimelineEvent event) {
    return GestureDetector(
      onTap: () => event.onDelete(context),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _getDeleteButtonBackgroundColor(),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.delete_outline,
          size: 18,
          color: AppColors.error,
        ),
      ),
    );
  }

  Widget _buildEventSubtitle(String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _getSubtitleColor(),
            ),
      ),
    );
  }

  Widget _buildEventNotes(String notes) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getNotesBackgroundColor(),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _truncateNotes(notes),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getSubtitleColor(),
                fontStyle: FontStyle.italic,
              ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isLightTheme = context.isLightTheme;
    final iconColor =
        isLightTheme ? AppColors.neutral400 : AppColors.neutral600;
    final textColor =
        isLightTheme ? AppColors.neutral600 : AppColors.neutral400;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No events scheduled for this day',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
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
      _createTransitEvents(itinerary.transits),
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
        notes: fullDay.notes,
        confirmationId: fullDay.confirmationId,
      );
      return;
    }

    final LodgingFacade? checkout = itinerary.checkOutLodging;
    if (checkout != null) {
      yield TimelineEvent<LodgingFacade>(
        time: checkout.checkoutDateTime!,
        title:
            '${localizations.checkOut} • ${checkout.checkoutDateTime!.hourMinuteAmPmFormat}',
        subtitle: _getLodgingLocationDetail(checkout),
        icon: Icons.logout,
        iconColor: AppColors.warning,
        data: checkout,
        notes: checkout.notes,
        confirmationId: checkout.confirmationId,
      );
    }

    final LodgingFacade? checkin = itinerary.checkInLodging;
    if (checkin != null) {
      yield TimelineEvent<LodgingFacade>(
        time: checkin.checkinDateTime!,
        title:
            '${localizations.checkIn} • ${checkin.checkinDateTime!.hourMinuteAmPmFormat}',
        subtitle: _getLodgingLocationDetail(checkin),
        icon: Icons.login,
        iconColor: AppColors.success,
        data: checkin,
        notes: checkin.notes,
        confirmationId: checkin.confirmationId,
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

      final transitEventData = _getTransitEventData(transit);

      yield TimelineEvent<TransitFacade>(
        time: transitEventData.eventTime,
        title: transitEventData.title,
        subtitle: _getTransitOperatorInfo(transit),
        icon: metadata.icon,
        iconColor: AppColors.info,
        data: transit,
        notes: transit.notes,
        confirmationId: transit.confirmationId,
      );
    }
  }

  ({DateTime eventTime, String title}) _getTransitEventData(
      TransitFacade transit) {
    final departure = transit.departureDateTime!;
    final arrival = transit.arrivalDateTime!;
    final isDepartingToday = departure.isOnSameDayAs(widget.itineraryDay);
    final isArrivingToday = arrival.isOnSameDayAs(widget.itineraryDay);
    final localizations = context.localizations;

    if (isDepartingToday && isArrivingToday) {
      if (context.isBigLayout) {
        return (
          eventTime: departure,
          title:
              '${_getTransitLocationDetail(transit)} • ${departure.hourMinuteAmPmFormat} - ${arrival.hourMinuteAmPmFormat}',
        );
      } else {
        return (
          eventTime: departure,
          title:
              '${_getTransitLocationDetail(transit)}\n${departure.hourMinuteAmPmFormat} - ${arrival.hourMinuteAmPmFormat}',
        );
      }
    } else if (isDepartingToday) {
      return (
        eventTime: departure,
        title:
            '${localizations.departAt} ${departure.hourMinuteAmPmFormat} → ${_getDestinationName(transit)}',
      );
    } else {
      return (
        eventTime: arrival,
        title:
            '${localizations.arriveAt} ${arrival.hourMinuteAmPmFormat} from ${_getOriginName(transit)}',
      );
    }
  }

  Iterable<TimelineEvent> _createTimedSightEvents(
    List<SightFacade> sights,
  ) sync* {
    for (var sightIndex = 0; sightIndex < sights.length; sightIndex++) {
      final sight = sights[sightIndex];
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
          notes: sight.description,
          tripManagementEventCreatorOnTap: (sight) {
            return EditItineraryPlanData(
              day: widget.itineraryDay,
              planDataEditorConfig: UpdateItineraryPlanDataComponentConfig(
                planDataType: PlanDataType.sight,
                index: sightIndex,
              ),
            );
          },
          tripManagementEventCreatorOnDelete: (sight) {
            var itineraryPlanData = context.activeTrip.itineraryCollection
                .getItineraryForDay(widget.itineraryDay)
                .planData;
            itineraryPlanData.sights.removeAt(sightIndex);
            return UpdateTripEntity<ItineraryPlanData>.update(
                tripEntity: itineraryPlanData);
          });
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
        ? (transit.departureLocation!.context as AirportLocationContext)
            .airportCode
        : transit.departureLocation.toString();
    final arrivalLocation = transit.transitOption == TransitOption.flight
        ? (transit.arrivalLocation!.context as AirportLocationContext)
            .airportCode
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

  String _truncateNotes(String notes) {
    if (notes.length <= _kNotesMaxLength) {
      return notes;
    }
    return '${notes.substring(0, _kNotesMaxLength)}...';
  }

  Color _getIconBackgroundColor(Color iconColor) {
    final isLightTheme = context.isLightTheme;
    return isLightTheme
        ? iconColor.withValues(alpha: 0.15)
        : iconColor.withValues(alpha: 0.25);
  }

  Color _getCardBackgroundColor() {
    final isLightTheme = context.isLightTheme;
    return isLightTheme ? Colors.white : AppColors.darkSurface;
  }

  Color _getCardBorderColor() {
    final isLightTheme = context.isLightTheme;
    return isLightTheme ? AppColors.neutral400 : AppColors.neutral600;
  }

  Color _getTimelineConnectorColor() {
    final isLightTheme = context.isLightTheme;
    return isLightTheme
        ? AppColors.brandPrimary.withValues(alpha: 0.5)
        : AppColors.brandPrimaryLight.withValues(alpha: 0.3);
  }

  Color _getTextColor() {
    final isLightTheme = context.isLightTheme;
    return isLightTheme ? AppColors.brandSecondary : AppColors.neutral100;
  }

  Color _getSubtitleColor() {
    final isLightTheme = context.isLightTheme;
    return isLightTheme ? AppColors.neutral700 : AppColors.neutral400;
  }

  Color _getCardShadowColor() {
    final isLightTheme = context.isLightTheme;
    return (isLightTheme ? AppColors.brandPrimary : Colors.black)
        .withValues(alpha: 0.15);
  }

  Color _getNotesBackgroundColor() {
    final isLightTheme = context.isLightTheme;
    return isLightTheme ? AppColors.neutral300 : AppColors.neutral700;
  }

  Color _getDeleteButtonBackgroundColor() {
    final isLightTheme = context.isLightTheme;
    return isLightTheme
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.error.withValues(alpha: 0.2);
  }

  bool _shouldRebuild(
    TripManagementState previousState,
    TripManagementState currentState,
  ) {
    if (currentState.isTripEntityUpdated<LodgingFacade>()) {
      return _shouldRebuildForLodging(currentState);
    }
    if (currentState.isTripEntityUpdated<TransitFacade>()) {
      return _shouldRebuildForTransit(currentState);
    }
    if (currentState.isTripEntityUpdated<ItineraryPlanData>()) {
      return _shouldRebuildForSight(currentState);
    }
    return false;
  }

  bool _shouldRebuildForLodging(TripManagementState state) {
    final tripEntityUpdatedState = state as UpdatedTripEntity;
    final dataState = tripEntityUpdatedState.dataState;
    final modifiedCollectionItem = tripEntityUpdatedState
        .tripEntityModificationData.modifiedCollectionItem;

    if (dataState == DataState.create || dataState == DataState.delete) {
      final updatedTripEntity = modifiedCollectionItem as LodgingFacade;
      return _isLodgingOnItineraryDay(updatedTripEntity);
    } else if (dataState == DataState.update) {
      final collectionItemChangeset =
          modifiedCollectionItem as CollectionItemChangeSet<LodgingFacade>;
      return _isLodgingOnItineraryDay(collectionItemChangeset.beforeUpdate) ||
          _isLodgingOnItineraryDay(collectionItemChangeset.afterUpdate);
    }
    return false;
  }

  bool _shouldRebuildForTransit(TripManagementState state) {
    final tripEntityUpdatedState = state as UpdatedTripEntity;
    final dataState = tripEntityUpdatedState.dataState;
    final modifiedCollectionItem = tripEntityUpdatedState
        .tripEntityModificationData.modifiedCollectionItem;

    if (dataState == DataState.create || dataState == DataState.delete) {
      final updatedTripEntity = modifiedCollectionItem as TransitFacade;
      return _isTransitOnItineraryDay(updatedTripEntity);
    } else if (dataState == DataState.update) {
      final collectionItemChangeset =
          modifiedCollectionItem as CollectionItemChangeSet<TransitFacade>;
      return _isTransitOnItineraryDay(collectionItemChangeset.beforeUpdate) ||
          _isTransitOnItineraryDay(collectionItemChangeset.afterUpdate);
    }
    return false;
  }

  bool _shouldRebuildForSight(TripManagementState state) {
    final tripEntityUpdatedState = state as UpdatedTripEntity;
    final dataState = tripEntityUpdatedState.dataState;
    final modifiedCollectionItem = tripEntityUpdatedState
        .tripEntityModificationData.modifiedCollectionItem;

    if (dataState == DataState.update) {
      final collectionItemChangeset =
          modifiedCollectionItem as CollectionItemChangeSet<ItineraryPlanData>;
      var itineraryPlanDataAfterUpdate = collectionItemChangeset.afterUpdate;
      var isItineraryPlanDataUpdated = collectionItemChangeset.beforeUpdate.day
              .isOnSameDayAs(widget.itineraryDay) ||
          itineraryPlanDataAfterUpdate.day.isOnSameDayAs(widget.itineraryDay);
      if (isItineraryPlanDataUpdated) {
        var sightsBeforeUpdate = collectionItemChangeset.beforeUpdate.sights;
        var sightsAfterUpdate = collectionItemChangeset.afterUpdate.sights;
        return !listEquals(sightsBeforeUpdate, sightsAfterUpdate);
      }
    }
    return false;
  }

  bool _isLodgingOnItineraryDay(LodgingFacade lodging) {
    return lodging.checkinDateTime!.isOnSameDayAs(widget.itineraryDay) ||
        lodging.checkoutDateTime!.isOnSameDayAs(widget.itineraryDay);
  }

  bool _isTransitOnItineraryDay(TransitFacade transit) {
    return transit.arrivalDateTime!.isOnSameDayAs(widget.itineraryDay) ||
        transit.departureDateTime!.isOnSameDayAs(widget.itineraryDay);
  }
}
