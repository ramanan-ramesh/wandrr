import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wandrr/data/trip/models/core/model_types.dart';

import 'airport_location_context.dart';
import 'location_context.dart';

part 'location.freezed.dart';

/// Represents a geographic location.
/// Location always has valid lat/lng and context, so no draft needed.
@freezed
class Location with _$Location implements TripEntity<Location> {
  const Location._();

  const factory Location({
    required double latitude,
    required double longitude,
    required LocationContext context,
    String? id,
  }) = _Location;

  @override
  Location clone() => copyWith();

  @override
  bool validate() => true;

  @override
  String toString() {
    if (context is AirportLocationContext) {
      return context.city!;
    }
    return context.name;
  }
}

/// Location types for categorizing places
enum LocationType {
  continent,
  country,
  state,
  city,
  town,
  place,
  region,
  railwayStation,
  airport,
  busStation,
  restaurant,
  attraction,
  lodging,
  busStop,
  museum
}

// Legacy alias for backward compatibility
typedef LocationFacade = Location;
