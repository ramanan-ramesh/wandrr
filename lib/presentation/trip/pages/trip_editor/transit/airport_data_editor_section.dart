import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/location/airport_location_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
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
  static const EdgeInsets _kContentPadding = EdgeInsets.symmetric(
      horizontal: _kListTileHorizontalPadding,
      vertical: _kListTileVerticalPadding);

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
          setState(() => _location = newAirport);
          widget.onLocationSelected?.call(newAirport);
        }
      },
      optionsBuilder:
          context.apiServicesRepository.airportsDataService.queryData,
      listItem: _buildAirportTile,
    );
  }

  Widget _buildAirportTile(LocationFacade airportData) {
    final airport = airportData.context as AirportLocationContext;
    final isSelected = _location == airportData;
    final isLightTheme = context.isLightTheme;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Background color only for selected to keep list layout unchanged.
    final Color? backgroundColor = isSelected
        ? (isLightTheme ? AppColors.neutral200 : AppColors.darkSurfaceHeader)
        : null;

    // Code & city row styled similarly to ListTile's title/subtitle layout.
    return Container(
      padding: _kContentPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_kListTileBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  airport.airportCode,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    airport.city,
                    style: textTheme.titleMedium,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: isLightTheme
                      ? theme.colorScheme.primary
                      : AppColors.brandPrimaryLight,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              airport.name,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
