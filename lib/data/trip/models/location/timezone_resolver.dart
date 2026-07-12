import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import 'location.dart';

/// Single source of truth for resolving the IANA timezone identifier
/// (e.g. `Europe/Prague`) associated with a [LocationFacade].
///
/// Resolution order:
/// 1. The persisted [LocationFacade.timezoneId], when present — this is the
///    fast path and is the value written to Firestore by
///    `LocationModelImplementation` for any newly created location.
/// 2. Coordinate-based inference via `latLngToTimezoneString`, memoised per
///    coordinate pair so repeated lookups (e.g. across timeline/print
///    rebuilds for legacy locations without a persisted id) don't repeat the
///    underlying computation.
///
/// Centralising this here means every consumer (date/time conversion,
/// timezone indicator widgets, etc.) resolves a location's timezone the same
/// way, instead of each call site re-implementing the same
/// coordinate-inference + fallback logic.
class TimezoneResolver {
  TimezoneResolver._();

  static final Map<String, String> _coordinateCache = {};

  /// Resolves the IANA timezone id for [location]. Returns null when
  /// [location] is null.
  static String? resolveTimezoneId(LocationFacade? location) {
    if (location == null) {
      return null;
    }
    final persisted = location.timezoneId;
    if (persisted != null && persisted.isNotEmpty) {
      return persisted;
    }
    return _inferFromCoordinates(location.latitude, location.longitude);
  }

  /// Resolves the `timezone` package [tz.Location] for [location], used to
  /// perform actual date/time conversions. Returns null when [location] is
  /// null or the resolved id is unknown to the `timezone` database.
  static tz.Location? resolveLocation(LocationFacade? location) {
    final timezoneId = resolveTimezoneId(location);
    if (timezoneId == null) {
      return null;
    }
    try {
      return tz.getLocation(timezoneId);
    } on Exception {
      return null;
    }
  }

  static String _inferFromCoordinates(double latitude, double longitude) {
    final key = '$latitude,$longitude';
    return _coordinateCache.putIfAbsent(
      key,
      () => latLngToTimezoneString(latitude, longitude),
    );
  }
}
