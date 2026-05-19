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
    final theme = Theme.of(context);
    final isLight = context.isLightTheme;
    final accentColor =
        isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight;
    final selectedBg = accentColor.withValues(alpha: 0.10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? selectedBg : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isSelected ? accentColor : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      padding: _kContentPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Airport code badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isSelected ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              airport.airportCode,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // City + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  airport.city,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color:
                        isSelected ? accentColor : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  airport.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
