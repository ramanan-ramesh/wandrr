import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/location/location_timezone_date_time.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';

/// Helper class for formatting itinerary timeline event details
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

  /// Formats transit location detail.
  /// If departure and arrival are in the same city, shows place names with
  /// city mentioned once: "Station A → Station B (City)".
  /// Otherwise shows "City A → City B".
  String getTransitLocationDetail(TransitFacade transit) {
    if (transit.transitOption == TransitOption.flight) {
      final depCode =
          (transit.departureLocation!.context as AirportLocationContext)
              .airportCode;
      final arrCode =
          (transit.arrivalLocation!.context as AirportLocationContext)
              .airportCode;
      return '$depCode → $arrCode';
    }

    final depName = transit.departureLocation!.context.name;
    final arrName = transit.arrivalLocation!.context.name;
    final depCity = transit.departureLocation!.context.city;
    final arrCity = transit.arrivalLocation!.context.city;

    // Same city: show place names with city mentioned once
    if (depCity != null && arrCity != null && depCity == arrCity) {
      final isDepNameCity = depName.isEmpty || depName == depCity;
      final isArrNameCity = arrName.isEmpty || arrName == arrCity;

      if (isDepNameCity && isArrNameCity) {
        return depCity;
      } else if (isArrNameCity) {
        return '$depName ($depCity)';
      } else if (isDepNameCity) {
        return '$arrName ($depCity)';
      } else if (depName == arrName) {
        return '$depName ($depCity)';
      }
      return '$depName → $arrName ($depCity)';
    }

    // Different cities: prefer city names, fall back to place names
    final depLabel = (depCity != null && depCity.isNotEmpty)
        ? depCity
        : (depName.isEmpty ? '?' : depName);
    final arrLabel = (arrCity != null && arrCity.isNotEmpty)
        ? arrCity
        : (arrName.isEmpty ? '?' : arrName);

    if (depLabel == arrLabel) {
      return depLabel;
    }
    return '$depLabel → $arrLabel';
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

  /// Gets transit event data (time, title, and subtitle)
  ({DateTime eventTime, String title, String subtitle}) getTransitEventData(
      {required TransitFacade transit, required DateTime itineraryDay}) {
    final departure = transit.departureDateTime!;
    final arrival = transit.arrivalDateTime!;
    final isDepartingToday = LocationTimezoneDateTime.isOnSameDay(
      storedDateTime: departure,
      day: itineraryDay,
      location: transit.departureLocation,
    );
    final isArrivingToday = LocationTimezoneDateTime.isOnSameDay(
      storedDateTime: arrival,
      day: itineraryDay,
      location: transit.arrivalLocation,
    );
    final localizations = context.localizations;

    if (isDepartingToday && isArrivingToday) {
      final operatorInfo = getTransitOperatorInfo(transit);
      return (
        eventTime: departure,
        title: getTransitLocationDetail(transit),
        subtitle: operatorInfo,
      );
    } else if (isDepartingToday) {
      final depName = _getOriginName(transit);
      final destName = _getDestinationName(transit);
      return (
        eventTime: departure,
        title: '${localizations.depart} $depName → $destName',
        subtitle: getTransitOperatorInfo(transit),
      );
    } else {
      final originName = _getOriginName(transit);
      final destName = _getDestinationName(transit);
      return (
        eventTime: arrival,
        title: '${localizations.arrive} $originName → $destName',
        subtitle: getTransitOperatorInfo(transit),
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

