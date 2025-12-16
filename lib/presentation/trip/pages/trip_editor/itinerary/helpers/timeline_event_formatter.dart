import 'package:flutter/material.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';

/// Helper class for formatting timeline event details
class TimelineEventFormatter {
  final BuildContext context;

  const TimelineEventFormatter(this.context);

  /// Formats lodging location detail
  String getLodgingLocationDetail(LodgingFacade lodging) {
    final locationDetail = lodging.location!.context.name;
    final lodgingCity = lodging.location!.context.city;
    return (lodgingCity != null && lodgingCity != locationDetail)
        ? '$locationDetail, $lodgingCity'
        : locationDetail;
  }

  /// Formats transit location detail
  String getTransitLocationDetail(TransitFacade transit) {
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

  /// Gets the transit operator info
  String getTransitOperatorInfo(TransitFacade transit) =>
      transit.operator ?? '';

  /// Formats sight subtitle
  String getSightSubtitle(SightFacade sight) {
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

  /// Gets transit event data (time and title)
  ({DateTime eventTime, String title}) getTransitEventData({
    required TransitFacade transit,
    required DateTime itineraryDay,
    required bool isBigLayout,
  }) {
    final departure = transit.departureDateTime!;
    final arrival = transit.arrivalDateTime!;
    final isDepartingToday = departure.isOnSameDayAs(itineraryDay);
    final isArrivingToday = arrival.isOnSameDayAs(itineraryDay);
    final localizations = context.localizations;
    final departureTimezone = latLngToTimezoneString(
        transit.departureLocation!.latitude,
        transit.departureLocation!.longitude);
    final arrivalTimezone = latLngToTimezoneString(
        transit.arrivalLocation!.latitude, transit.arrivalLocation!.longitude);

    if (isDepartingToday && isArrivingToday) {
      final areTimezonesEqual = departureTimezone == arrivalTimezone;
      String dateTimeText;
      if (areTimezonesEqual) {
        dateTimeText =
            '${departure.hourMinuteAmPmFormat} - ${arrival.hourMinuteAmPmFormat} ($departureTimezone)';
      } else {
        dateTimeText =
            '${departure.hourMinuteAmPmFormat} - ${arrival.hourMinuteAmPmFormat}\n$departureTimezone - $arrivalTimezone';
      }
      return (
        eventTime: departure,
        title: '${getTransitLocationDetail(transit)}\n$dateTimeText',
      );
    } else if (isDepartingToday) {
      return (
        eventTime: departure,
        title:
            '${localizations.departAt} ${departure.hourMinuteAmPmFormat} ($departureTimezone) → ${_getDestinationName(transit)}',
      );
    } else {
      return (
        eventTime: arrival,
        title:
            '${localizations.arriveAt} ${arrival.hourMinuteAmPmFormat} ($arrivalTimezone) from ${_getOriginName(transit)}',
      );
    }
  }

  /// Gets the origin name for transit
  String _getOriginName(TransitFacade transit) =>
      transit.transitOption == TransitOption.flight
          ? (transit.departureLocation!.context as AirportLocationContext).city
          : transit.departureLocation.toString();

  /// Gets the destination name for transit
  String _getDestinationName(TransitFacade transit) =>
      transit.transitOption == TransitOption.flight
          ? (transit.arrivalLocation!.context as AirportLocationContext).city
          : transit.arrivalLocation.toString();
}
