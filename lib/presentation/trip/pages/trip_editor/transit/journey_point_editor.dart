import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';
import 'package:wandrr/presentation/trip/widgets/time_zone_indicator.dart';

import 'airport_data_editor_section.dart';

class JourneyPointEditor extends StatelessWidget {
  final TransitFacade transitFacade;
  final bool isDeparture;
  final ValueChanged<LocationFacade?> onLocationChanged;
  final ValueChanged<DateTime> onDateTimeChanged;

  const JourneyPointEditor({
    Key? key,
    required this.transitFacade,
    required this.isDeparture,
    required this.onLocationChanged,
    required this.onDateTimeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var color = isDeparture ? AppColors.info : AppColors.success;
    final tripMetadata = context.activeTrip.tripMetadata;
    final isFlightTransit = transitFacade.transitOption == TransitOption.flight;
    final location = isDeparture
        ? transitFacade.departureLocation
        : transitFacade.arrivalLocation;
    final startDateTime = isDeparture
        ? tripMetadata.startDate!
        : _getStartDateTime(true, tripMetadata.startDate!);
    final endDateTime = _getEndDateTime(tripMetadata.endDate!);
    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDeparture ? Icons.flight_takeoff : Icons.flight_land,
                color: color,
                size: EditorTheme.iconSize,
              ),
              const SizedBox(width: 8),
              Text(
                isDeparture
                    ? context.localizations.depart
                    : context.localizations.arrive,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 4),
              _createJourneyCityName(color),
            ],
          ),
          const SizedBox(height: 12),
          isFlightTransit
              ? AirportsDataEditorSection(
                  initialLocation: location,
                  onLocationSelected: onLocationChanged,
                )
              : PlatformGeoLocationAutoComplete(
                  selectedLocation: location,
                  onLocationSelected: onLocationChanged,
                ),
          const SizedBox(height: 12),
          _createDateTimeDetails(startDateTime, endDateTime, location),
        ],
      ),
    );
  }

  Widget _createDateTimeDetails(
      DateTime startDateTime, DateTime endDateTime, LocationFacade? location) {
    return Row(
      children: [
        PlatformDateTimePicker(
          dateTimeUpdated: onDateTimeChanged,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          currentDateTime: isDeparture
              ? transitFacade.departureDateTime
              : transitFacade.arrivalDateTime,
        ),
        if (location != null) const SizedBox(width: 12),
        if (location != null) TimezoneIndicator(location: location)
      ],
    );
  }

  Widget _createJourneyCityName(Color color) {
    String? cityName;
    final isFlightTransit = transitFacade.transitOption == TransitOption.flight;
    final location = isDeparture
        ? transitFacade.departureLocation
        : transitFacade.arrivalLocation;
    if (isFlightTransit) {
      if (location != null) {
        cityName = (location.context as AirportLocationContext).airportCode;
      }
    } else {
      if (location != null) {
        cityName = (location.context as GeoLocationApiContext).city;
      }
    }
    return JourneyCityName(
      cityName: cityName,
      color: color,
    );
  }

  DateTime _getStartDateTime(bool isArrival, DateTime tripStartDate) {
    if (isArrival) {
      final departureTime = transitFacade.departureDateTime;
      if (departureTime != null) {
        return departureTime.add(const Duration(minutes: 1));
      }
    }
    return tripStartDate;
  }

  DateTime _getEndDateTime(DateTime tripEndDate) {
    return DateTime(
        tripEndDate.year, tripEndDate.month, tripEndDate.day, 23, 59);
  }
}

class JourneyCityName extends StatelessWidget {
  final String? cityName;
  final Color color;

  const JourneyCityName({
    Key? key,
    required this.cityName,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: (cityName != null && cityName!.isNotEmpty)
          ? Text(
              cityName!,
              key: ValueKey<String>(cityName!),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              overflow: TextOverflow.ellipsis,
            )
          : const SizedBox.shrink(key: ValueKey<String>('empty')),
    );
  }
}
