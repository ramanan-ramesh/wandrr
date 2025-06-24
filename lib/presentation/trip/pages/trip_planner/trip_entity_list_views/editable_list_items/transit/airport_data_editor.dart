import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';

class AirportsDataEditor extends StatefulWidget {
  final LocationFacade? initialLocation;
  final double? locationOptionsViewWidth;
  final Function(LocationFacade selectedLocation)? onLocationSelected;

  const AirportsDataEditor(
      {super.key,
      this.initialLocation,
      this.onLocationSelected,
      this.locationOptionsViewWidth});

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
    return PlatformAutoComplete<LocationFacade>(
      optionsViewWidth: widget.locationOptionsViewWidth,
      hintText: context.localizations.airport,
      selectedItem: _location,
      displayTextCreator: (location) =>
          (location.context as AirportLocationContext).name,
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
      optionsBuilder: context.tripRepository.airportsDataService.queryData,
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
