import 'package:flutter/material.dart';
import 'package:wandrr/api_services/implementations/geo_locator.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/auto_complete.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/models/location.dart';
import 'package:wandrr/trip_presentation/widgets/constants.dart';

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
            context.getPlatformDataRepository().geoLocator.performQuery,
        customPrefix: shouldShowPrefix
            ? FittedBox(
                fit: BoxFit.cover,
                child: PlatformTextElements.createSubHeader(
                    context: context, text: context.withLocale().destination),
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
