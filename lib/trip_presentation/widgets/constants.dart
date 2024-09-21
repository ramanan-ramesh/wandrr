import 'package:flutter/material.dart';
import 'package:wandrr/trip_data/models/location/location.dart';

class TripPresentationConstants {
  static const Map<LocationType, IconData?> locationTypesAndIcons = {
    LocationType.Place: Icons.place_rounded,
    LocationType.Attraction: Icons.attractions_rounded,
    LocationType.BusStop: Icons.directions_bus_rounded,
    LocationType.Airport: Icons.local_airport_rounded,
    LocationType.Lodging: Icons.hotel_rounded,
    LocationType.BusStation: Icons.directions_bus_rounded,
    LocationType.Restaurant: Icons.restaurant_rounded,
    LocationType.RailwayStation: Icons.directions_train_rounded,
  };
}
