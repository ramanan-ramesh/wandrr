import 'package:flutter/material.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/transit_journey_service.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_journey.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_event_formatter.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/timeline_event.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/transit_journey_timeline_event.dart';
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
  /// Groups connected legs by journeyId and marks their position
  Iterable<TimelineEvent> _createTransitEvents(
    Iterable<TransitFacade> transits,
  ) sync* {
    // Create journey service to group transits
    final journeyService =
        TransitJourneyServiceFacade(context.activeTrip.transitCollection);

    // Group transits by journeyId
    final standaloneTransits = <TransitFacade>[];
    final journeyTransits = <String, List<TransitFacade>>{};

    for (final transit in transits) {
      if (transit.journeyId == null) {
        standaloneTransits.add(transit);
      } else {
        journeyTransits.putIfAbsent(transit.journeyId!, () => []).add(transit);
      }
    }

    // Process standalone transits
    for (final transit in standaloneTransits) {
      yield _createSingleTransitEvent(
          transit, TravelLegConnectionPosition.standalone);
    }

    // Process journey transits (grouped and sorted)
    for (final entry in journeyTransits.entries) {
      final journey = journeyService.getJourney(entry.key);
      if (journey == null) continue;

      // Filter to only legs that appear on this itinerary day
      final legsOnThisDay = entry.value.toList()
        ..sort((a, b) => (a.departureDateTime ?? DateTime(0))
            .compareTo(b.departureDateTime ?? DateTime(0)));

      for (var i = 0; i < legsOnThisDay.length; i++) {
        final leg = legsOnThisDay[i];
        final legIndexInJourney = journey.legs.indexOf(leg);
        final isFirst = legIndexInJourney == 0;
        final isLast = legIndexInJourney == journey.legs.length - 1;

        TravelLegConnectionPosition position;
        if (journey.legs.length == 1) {
          position = TravelLegConnectionPosition.standalone;
        } else if (isFirst) {
          position = TravelLegConnectionPosition.start;
        } else if (isLast) {
          position = TravelLegConnectionPosition.end;
        } else {
          position = TravelLegConnectionPosition.middle;
        }

        // Calculate layover from previous leg
        String? layoverDuration;
        if (legIndexInJourney > 0) {
          final prevLeg = journey.legs[legIndexInJourney - 1];
          layoverDuration = _calculateLayoverString(
            prevLeg.arrivalDateTime,
            leg.departureDateTime,
          );
        }

        yield _createConnectedTransitEvent(
          transit: leg,
          position: position,
          journeyId: entry.key,
          layoverDuration: layoverDuration,
          journey: journey,
        );
      }
    }
  }

  /// Creates a single transit event (standalone)
  TimelineEvent<TransitFacade> _createSingleTransitEvent(
    TransitFacade transit,
    TravelLegConnectionPosition position,
  ) {
    final metadata = context.activeTrip.transitOptionMetadatas.firstWhere(
      (e) => e.transitOption == transit.transitOption,
    );

    final transitEventData = _formatter.getTransitEventData(
      transit: transit,
      itineraryDay: itineraryDay,
      isBigLayout: context.isBigLayout,
    );

    return TimelineEvent<TransitFacade>(
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

  /// Creates a connected transit event (part of a journey)
  TransitJourneyTimelineEvent _createConnectedTransitEvent({
    required TransitFacade transit,
    required TravelLegConnectionPosition position,
    required String journeyId,
    required TransitJourneyFacade journey,
    String? layoverDuration,
  }) {
    final metadata = context.activeTrip.transitOptionMetadatas.firstWhere(
      (e) => e.transitOption == transit.transitOption,
    );

    // Use city names for compact display
    final depCity = _getCityName(transit.departureLocation);
    final arrCity = _getCityName(transit.arrivalLocation);
    final title = '$depCity → $arrCity';

    // Format time range
    final depTime = transit.departureDateTime?.hourMinuteAmPmFormat ?? '--:--';
    final arrTime = transit.arrivalDateTime?.hourMinuteAmPmFormat ?? '--:--';
    final operatorInfo = _formatter.getTransitOperatorInfo(transit);
    final subtitle =
        '$depTime → $arrTime${operatorInfo.isNotEmpty ? ' • $operatorInfo' : ''}';

    return TransitJourneyTimelineEvent(
      time: transit.departureDateTime ?? DateTime.now(),
      title: title,
      subtitle: subtitle,
      icon: metadata.icon,
      iconColor: AppColors.info,
      data: transit,
      journeyId: journeyId,
      position: position,
      layoverDuration: layoverDuration,
      journey: journey,
      notes: transit.notes,
      confirmationId: transit.confirmationId,
    );
  }

  /// Get city name from location, preferring city over full name
  String _getCityName(dynamic location) {
    if (location == null) return '?';
    if (location is LocationFacade) {
      // Try to get city first, then name from context
      final city = location.context.city;
      if (city != null && city.isNotEmpty) return city;
      final name = location.context.name;
      if (name.isNotEmpty) return name;
      return '?';
    }
    return '?';
  }

  /// Calculate layover duration string
  String? _calculateLayoverString(DateTime? arrival, DateTime? departure) {
    if (arrival == null || departure == null) return null;
    final duration = departure.difference(arrival);
    if (duration.isNegative) return null;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
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

      String dateTimeDetails;
      if (sight.location != null) {
        var timezoneString = latLngToTimezoneString(
            sight.location!.latitude, sight.location!.longitude);
        dateTimeDetails = '${visitTime.hourMinuteAmPmFormat} ($timezoneString)';
      } else {
        dateTimeDetails = visitTime.hourMinuteAmPmFormat;
      }
      yield TimelineEvent<SightFacade>(
        time: visitTime,
        title: '${sight.name} • $dateTimeDetails',
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
