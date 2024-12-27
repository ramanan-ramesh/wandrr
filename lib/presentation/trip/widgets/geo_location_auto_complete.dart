import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/implementations/api_services/geo_locator.dart';
import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/widgets/constants.dart';

class PlatformGeoLocationAutoComplete extends StatelessWidget {
  final String? initialText;
  final Function(LocationFacade selectedLocation)? onLocationSelected;
  final bool shouldShowPrefix;
  final GeoLocator? geoLocator;

  const PlatformGeoLocationAutoComplete(
      {super.key,
      required this.initialText,
      this.geoLocator,
      this.onLocationSelected,
      this.shouldShowPrefix = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: PlatformAutoComplete<LocationFacade>(
        text: initialText,
        onSelected: onLocationSelected,
        optionsBuilder: geoLocator?.performQuery ??
            context.tripRepository.geoLocator.performQuery,
        customPrefix: shouldShowPrefix
            ? FittedBox(
                fit: BoxFit.cover,
                child: PlatformTextElements.createSubHeader(
                    context: context, text: context.localizations.destination),
              )
            : null,
        listItem: (location) {
          var geoLocationContext = location.context as GeoLocationApiContext;
          return Material(
            child: Container(
              color: Colors.black12,
              child: ListTile(
                leading: Icon(TripPresentationConstants
                    .locationTypesAndIcons[location.context.locationType]),
                title: Text(location.context.name,
                    style: const TextStyle(color: Colors.white)),
                trailing: Text(geoLocationContext.locationType.name,
                    style: const TextStyle(color: Colors.white)),
                subtitle: geoLocationContext.address != null
                    ? Text(
                        geoLocationContext.address!,
                        style: TextStyle(color: Colors.white),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
