import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class AirportsDataEditorSection extends StatefulWidget {
  final LocationFacade? initialLocation;
  final double? locationOptionsViewWidth;
  final Function(LocationFacade selectedLocation)? onLocationSelected;

  const AirportsDataEditorSection(
      {super.key,
      this.initialLocation,
      this.onLocationSelected,
      this.locationOptionsViewWidth});

  @override
  State<AirportsDataEditorSection> createState() =>
      _AirportsDataEditorSectionState();
}

class _AirportsDataEditorSectionState extends State<AirportsDataEditorSection> {
  static const double _kListTileBorderRadius = 6.0;
  static const double _kListTileHorizontalPadding = 8.0;
  static const double _kListTileVerticalPadding = 4.0;

  LocationFacade? _location;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation?.clone();
  }

  @override
  void didUpdateWidget(covariant AirportsDataEditorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLocation != widget.initialLocation) {
      _location = widget.initialLocation?.clone();
    }
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
          widget.onLocationSelected?.call(newAirport);
        }
      },
      optionsBuilder:
          context.apiServicesRepository.airportsDataService.queryData,
      listItem: (airportData) => _createAirportListItem(
          context, airportData.context as AirportLocationContext),
    );
  }

  Widget _createAirportListItem(
      BuildContext context, AirportLocationContext airport) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _kListTileHorizontalPadding,
          vertical: _kListTileVerticalPadding,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kListTileBorderRadius),
        ),
        child: Text(
          airport.airportCode,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      title: Wrap(
        children: [Text(airport.name)],
      ),
      subtitle: Text(
        airport.city,
      ),
    );
  }
}
