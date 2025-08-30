import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'airport_location_context.dart';
import 'location_context.dart';

// ignore: must_be_immutable
class LocationFacade extends Equatable implements TripEntity {
  final String tripId;

  final double latitude;
  final double longitude;

  final LocationContext context;

  @override
  String? id;

  LocationFacade(
      {required this.latitude,
      required this.longitude,
      required this.context,
      required this.tripId,
      this.id});

  LocationFacade clone() => LocationFacade(
      latitude: latitude,
      longitude: longitude,
      context: context,
      tripId: tripId,
      id: id);

  @override
  String toString() {
    if (context is AirportLocationContext) {
      return context.city!;
    }
    return context.name;
  }

  @override
  List<Object?> get props => [tripId, id, latitude, longitude, context, id];
}

enum LocationType {
  continent,
  country,
  state,
  city,
  place,
  region,
  railwayStation,
  airport,
  busStation,
  restaurant,
  attraction,
  lodging,
  busStop
}
