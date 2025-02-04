import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';

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
      maxOptionWidgetWidth: context.isBigLayout ? 250 : null,
      hintText: context.localizations.airport,
      selectedItem: _location,
      customPrefix: Text(
        airportCode.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall,
      ),
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
      optionsBuilder:
          context.tripRepository.flightOperationsService.queryAirportsData,
      listItem: (airportData) {
        var airportLocationContext =
            airportData.context as AirportLocationContext;
        return ListTile(
          selected: airportData == _location,
          title: Wrap(
            children: [Text(airportLocationContext.name)],
          ),
          trailing: Text(
            airportLocationContext.airportCode,
          ),
          subtitle: Text(
            airportLocationContext.city,
          ),
        );
      },
    );
  }
}
