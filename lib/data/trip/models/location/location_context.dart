import 'airport_location_context.dart';
import 'geo_location_api_context.dart';
import 'location.dart';

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
