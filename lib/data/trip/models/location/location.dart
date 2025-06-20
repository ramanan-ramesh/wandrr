import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'airport_location_context.dart';
import 'geo_location_api_context.dart';

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

  LocationFacade clone() {
    return LocationFacade(
        latitude: latitude,
        longitude: longitude,
        context: context,
        tripId: tripId,
        id: id);
  }

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

abstract class LocationContext {
  LocationType get locationType;

  String? get city;

  String get name;

  Map<String, dynamic> toJson();

  LocationContext clone();

  static LocationContext createInstance({required Map<String, dynamic> json}) {
    if (json['type'] == LocationType.airport.name) {
      return AirportLocationContext.fromDocument(json);
    }

    return GeoLocationApiContext.fromDocument(json);
  }
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
