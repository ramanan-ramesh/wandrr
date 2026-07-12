import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'airport_location_context.dart';
import 'location_context.dart';

// ignore: must_be_immutable
class LocationFacade extends Equatable implements TripEntity<Never> {
  final double latitude;
  final double longitude;

  final LocationContext context;

  /// IANA timezone identifier (e.g. `Europe/Prague`), resolved once when a
  /// location is first persisted (see `LocationModelImplementation`) so that
  /// later date/time conversions don't need to re-infer it from coordinates.
  ///
  /// Null for locations that haven't been resolved yet, or that were
  /// persisted before this field existed. Callers should resolve via
  /// `TimezoneResolver` rather than reading this directly, since that class
  /// transparently falls back to coordinate-based inference.
  ///
  /// Excluded from [props] intentionally: it is derived data, not part of a
  /// location's semantic identity, so two locations with the same
  /// coordinates/context/id must stay equal regardless of whether this has
  /// been resolved yet.
  final String? timezoneId;

  @override
  String? id;

  LocationFacade(
      {required this.latitude,
      required this.longitude,
      required this.context,
      this.id,
      this.timezoneId});

  @override
  LocationFacade clone() => LocationFacade(
      latitude: latitude,
      longitude: longitude,
      context: context,
      id: id,
      timezoneId: timezoneId);

  @override
  String toString() {
    if (context is AirportLocationContext) {
      return context.city!;
    }
    return context.name;
  }

  @override
  Iterable<Never> getValidationErrors() => const [];

  @override
  List<Object?> get props => [latitude, longitude, context, id];
}

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
