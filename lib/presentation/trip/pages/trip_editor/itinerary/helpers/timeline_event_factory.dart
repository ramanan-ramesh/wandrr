import 'package:flutter/material.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_event_formatter.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/timeline_event.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

/// Factory for creating timeline events from trip entities
class TimelineEventFactory {
  final BuildContext context;
  final DateTime itineraryDay;
  final TimelineEventFormatter _formatter;

  TimelineEventFactory({
    required this.context,
    required this.itineraryDay,
  }) : _formatter = TimelineEventFormatter(context);

  /// Collects all timeline events for the given itinerary
  List<TimelineEvent> collectTimelineEvents(ItineraryFacade itinerary) {
    final List<TimelineEvent> timelineEvents = [];
    timelineEvents.addAll(_createLodgingEvents(itinerary));
    timelineEvents.addAll(_createTransitEvents(itinerary.transits));
    timelineEvents.addAll(_createTimedSightEvents(itinerary.planData.sights));
    timelineEvents.sort((a, b) => a.time.compareTo(b.time));
    return timelineEvents;
  }

  /// Creates timeline events for lodging
  Iterable<TimelineEvent> _createLodgingEvents(
      ItineraryFacade itinerary) sync* {
    final fullDay = itinerary.fullDayLodging;
    final localizations = context.localizations;

    if (fullDay != null) {
      yield TimelineEvent<LodgingFacade>(
        time: fullDay.checkinDateTime!,
        title: localizations.allDayStay,
        subtitle: _formatter.getLodgingLocationDetail(fullDay),
        icon: Icons.hotel_rounded,
        iconColor: AppColors.brandPrimary,
        data: fullDay,
        notes: fullDay.notes,
        confirmationId: fullDay.confirmationId,
      );
      return;
    }

    final checkout = itinerary.checkOutLodging;
    if (checkout != null) {
      yield TimelineEvent<LodgingFacade>(
        time: checkout.checkoutDateTime!,
        title:
            '${localizations.checkOut} • ${checkout.checkoutDateTime!.hourMinuteAmPmFormat}',
        subtitle: _formatter.getLodgingLocationDetail(checkout),
        icon: Icons.logout,
        iconColor: AppColors.warning,
        data: checkout,
        notes: checkout.notes,
        confirmationId: checkout.confirmationId,
      );
    }

    final checkin = itinerary.checkInLodging;
    if (checkin != null) {
      yield TimelineEvent<LodgingFacade>(
        time: checkin.checkinDateTime!,
        title:
            '${localizations.checkIn} • ${checkin.checkinDateTime!.hourMinuteAmPmFormat}',
        subtitle: _formatter.getLodgingLocationDetail(checkin),
        icon: Icons.login,
        iconColor: AppColors.success,
        data: checkin,
        notes: checkin.notes,
        confirmationId: checkin.confirmationId,
      );
    }
  }

  /// Creates timeline events for transits
  Iterable<TimelineEvent> _createTransitEvents(
    Iterable<TransitFacade> transits,
  ) sync* {
    for (final transit in transits) {
      final metadata = context.activeTrip.transitOptionMetadatas.firstWhere(
        (e) => e.transitOption == transit.transitOption,
      );

      final transitEventData = _formatter.getTransitEventData(
        transit: transit,
        itineraryDay: itineraryDay,
        isBigLayout: context.isBigLayout,
      );

      yield TimelineEvent<TransitFacade>(
        time: transitEventData.eventTime,
        title: transitEventData.title,
        subtitle: _formatter.getTransitOperatorInfo(transit),
        icon: metadata.icon,
        iconColor: AppColors.info,
        data: transit,
        notes: transit.notes,
        confirmationId: transit.confirmationId,
      );
    }
  }

  /// Creates timeline events for sights with visit times
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
        subtitle: _formatter.getSightSubtitle(sight),
        icon: Icons.place_rounded,
        iconColor: AppColors.brandAccent,
        data: sight,
        notes: sight.description,
        tripManagementEventCreatorOnTap: (sight) {
          return EditItineraryPlanData(
            day: itineraryDay,
            planDataEditorConfig: UpdateItineraryPlanDataComponentConfig(
              planDataType: PlanDataType.sight,
              index: sightIndex,
            ),
          );
        },
        tripManagementEventCreatorOnDelete: (sight) {
          final itineraryPlanData = context.activeTrip.itineraryCollection
              .getItineraryForDay(itineraryDay)
              .planData;
          itineraryPlanData.sights.removeAt(sightIndex);
          return UpdateTripEntity<ItineraryPlanData>.update(
              tripEntity: itineraryPlanData);
        },
      );
    }
  }
}
