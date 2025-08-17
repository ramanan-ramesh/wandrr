import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/constants.dart';

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
        if (onLocationSelected != null) {
          onLocationSelected!(location);
        }
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
        return ListTile(
          leading: Icon(TripPresentationConstants
              .locationTypesAndIcons[location.context.locationType]),
          selected: selectedLocation == location,
          title: Wrap(
            children: [
              Text(
                location.context.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          subtitle: geoLocationContext.address != null
              ? Wrap(
                  children: [
                    Text(
                      geoLocationContext.address!,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
