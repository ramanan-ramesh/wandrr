import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';

import 'constants.dart';

class JumpToListNavigationRail extends StatelessWidget {
  const JumpToListNavigationRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _createNavigationIcon(Icons.info_outline_rounded,
              NavigationSections.tripOverview, context),
          _createNavigationIcon(Icons.directions_bus_rounded,
              NavigationSections.transit, context),
          _createNavigationIcon(
              Icons.hotel_rounded, NavigationSections.lodging, context),
          _createNavigationIcon(
              Icons.date_range_rounded, NavigationSections.itinerary, context),
        ],
      ),
    );
  }

  Widget _createNavigationIcon(
      IconData icon, String section, BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 4.0, right: 4.0, top: 8.0, bottom: 8.0),
      child: InkWell(
        onTap: () {
          context.addTripManagementEvent(NavigateToSection(section: section));
        },
        child: CircleAvatar(child: Icon(icon)),
      ),
    );
  }
}
