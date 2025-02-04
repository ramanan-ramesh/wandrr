import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

import 'airport_data_editor.dart';
import 'transit.dart';

class TransitEvent extends StatefulWidget {
  TransitFacade transitFacade;
  Function(TransitFacade) onUpdated;

  TransitEvent(
      {super.key, required this.transitFacade, required this.onUpdated});

  @override
  State<TransitEvent> createState() => _TransitEventState();
}

class _TransitEventState extends State<TransitEvent> {
  @override
  Widget build(BuildContext context) {
    var isBigLayout = context.isBigLayout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: _buildLocationDetails(context, false, isBigLayout),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: _buildLocationDetails(context, true, isBigLayout),
        )
      ],
    );
  }

  Widget _buildLocationDetails(
      BuildContext context, bool isArrival, bool isBigLayout) {
    var locationEditorWidget = _buildLocationEditor(isArrival);
    var tripMetadata = context.activeTrip.tripMetadata;
    var dateTimeEditorWidget = _buildDateTimePicker(isArrival, tripMetadata);
    return createTitleSubText(
      isArrival ? context.localizations.arrive : context.localizations.depart,
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isBigLayout)
            Expanded(
              child: locationEditorWidget,
            )
          else
            Flexible(
              child: locationEditorWidget,
            ),
          dateTimeEditorWidget
        ],
      ),
    );
  }

  Widget _buildDateTimePicker(bool isArrival, TripMetadataFacade tripMetadata) {
    return PlatformDateTimePicker(
      dateTimeUpdated: (updatedDateTime) {
        if (isArrival) {
          widget.transitFacade.arrivalDateTime = updatedDateTime;
        } else {
          widget.transitFacade.departureDateTime = updatedDateTime;
        }
        setState(() {});
        widget.onUpdated(widget.transitFacade);
      },
      startDateTime: isArrival
          ? (widget.transitFacade.departureDateTime
                ?..add(Duration(minutes: 1))) ??
              tripMetadata.startDate!
          : tripMetadata.startDate!,
      endDateTime: tripMetadata.endDate!,
      currentDateTime: isArrival
          ? widget.transitFacade.arrivalDateTime
          : widget.transitFacade.departureDateTime,
    );
  }

  Widget _buildLocationEditor(bool isArrival) {
    var locationToConsider = isArrival
        ? widget.transitFacade.arrivalLocation
        : widget.transitFacade.departureLocation;
    return widget.transitFacade.transitOption == TransitOption.Flight
        ? AirportsDataEditor(
            initialLocation: locationToConsider,
            onLocationSelected: (newLocation) {
              if (isArrival) {
                widget.transitFacade.arrivalLocation = newLocation;
              } else {
                widget.transitFacade.departureLocation = newLocation;
              }
              widget.onUpdated(widget.transitFacade);
            },
          )
        : PlatformGeoLocationAutoComplete(
            onLocationSelected: (newLocation) {
              if (isArrival) {
                widget.transitFacade.arrivalLocation = newLocation;
              } else {
                widget.transitFacade.departureLocation = newLocation;
              }
              widget.onUpdated(widget.transitFacade);
            },
            selectedLocation: locationToConsider,
          );
  }
}
