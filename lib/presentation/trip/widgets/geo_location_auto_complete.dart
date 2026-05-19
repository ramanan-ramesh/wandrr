import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

/// Maps every [LocationType] to a representative [IconData].
const Map<LocationType, IconData> _locationTypeIcons = {
  LocationType.continent: Icons.public_rounded,
  LocationType.country: Icons.flag_rounded,
  LocationType.state: Icons.map_rounded,
  LocationType.city: Icons.location_city_rounded,
  LocationType.town: Icons.holiday_village_rounded,
  LocationType.place: Icons.place_rounded,
  LocationType.region: Icons.terrain_rounded,
  LocationType.railwayStation: Icons.directions_train_rounded,
  LocationType.airport: Icons.local_airport_rounded,
  LocationType.busStation: Icons.directions_bus_rounded,
  LocationType.busStop: Icons.directions_bus_filled_rounded,
  LocationType.restaurant: Icons.restaurant_rounded,
  LocationType.attraction: Icons.attractions_rounded,
  LocationType.lodging: Icons.hotel_rounded,
  LocationType.museum: Icons.museum_rounded,
};

class PlatformGeoLocationAutoComplete extends StatelessWidget {
  final Function(LocationFacade selectedLocation)? onLocationSelected;
  final bool shouldShowPrefix;
  final double? locationOptionsViewWidth;
  LocationFacade? selectedLocation;

  // Constructor
  PlatformGeoLocationAutoComplete({
    super.key,
    this.selectedLocation,
    this.onLocationSelected,
    this.locationOptionsViewWidth,
    this.shouldShowPrefix = false,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformAutoComplete<LocationFacade>(
      optionsViewWidth: locationOptionsViewWidth,
      selectedItem: selectedLocation,
      onSelected: (location) {
        selectedLocation = location;
        onLocationSelected?.call(location);
      },
      optionsBuilder: context.apiServicesRepository.geoLocator.queryData,
      customPrefix: shouldShowPrefix
          ? FittedBox(
              fit: BoxFit.cover,
              child: PlatformTextElements.createSubHeader(
                  context: context, text: context.localizations.destination),
            )
          : null,
      listItem: (location) {
        var geoLocationContext = location.context as GeoLocationApiContext;
        final isSelected = selectedLocation == location;
        final theme = Theme.of(context);
        final isLight = theme.brightness == Brightness.light;
        final iconData = _locationTypeIcons[location.context.locationType] ??
            Icons.place_rounded;
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
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      accentColor.withValues(alpha: isSelected ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      location.context.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? accentColor
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (geoLocationContext.address != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        geoLocationContext.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
