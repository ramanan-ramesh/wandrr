import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

class TripPresentationConstants {
  static const Map<LocationType, IconData?> locationTypesAndIcons = {
    LocationType.place: Icons.place_rounded,
    LocationType.attraction: Icons.attractions_rounded,
    LocationType.busStop: Icons.directions_bus_rounded,
    LocationType.airport: Icons.local_airport_rounded,
    LocationType.lodging: Icons.hotel_rounded,
    LocationType.busStation: Icons.directions_bus_rounded,
    LocationType.restaurant: Icons.restaurant_rounded,
    LocationType.railwayStation: Icons.directions_train_rounded,
  };
}
