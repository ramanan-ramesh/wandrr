import 'package:flutter/material.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/auto_complete.dart';
import 'package:wandrr/trip_data/models/location/airport_location_context.dart';
import 'package:wandrr/trip_data/models/location/location.dart';
import 'package:wandrr/trip_presentation/widgets/constants.dart';

class AirportsDataEditor extends StatefulWidget {
  final LocationFacade? initialLocation;
  final Function(LocationFacade selectedLocation)? onLocationSelected;

  AirportsDataEditor(
      {super.key, this.initialLocation, this.onLocationSelected});

  @override
  State<AirportsDataEditor> createState() => _AirportsDataEditorState();
}

class _AirportsDataEditorState extends State<AirportsDataEditor> {
  LocationFacade? _location;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation?.clone();
  }

  @override
  Widget build(BuildContext context) {
    var airportCode =
        (_location?.context as AirportLocationContext?)?.airportCode ?? '   ';
    return PlatformAutoComplete<LocationFacade>(
      maxOptionWidgetWidth: context.isBigLayout() ? 250 : null,
      hintText: context.withLocale().airport,
      text: _location?.toString(),
      customPrefix: Text(airportCode),
      onSelected: (newAirport) {
        if (newAirport != _location) {
          setState(() {
            _location = newAirport;
          });
          if (widget.onLocationSelected != null) {
            widget.onLocationSelected!(newAirport);
          }
        }
      },
      optionsBuilder: context
          .getPlatformDataRepository()
          .flightOperationsService
          .queryAirportsData,
      listItem: (airportData) {
        var airportLocationContext =
            airportData.context as AirportLocationContext;
        return Material(
          child: ListTile(
            leading: Icon(TripPresentationConstants
                .locationTypesAndIcons[airportLocationContext.locationType]),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(airportLocationContext.name,
                  style: const TextStyle(color: Colors.white)),
            ),
            trailing: Text(airportLocationContext.airportCode,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text(airportLocationContext.city,
                style: const TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }
}
