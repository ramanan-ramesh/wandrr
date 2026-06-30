import 'package:intl/intl.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import 'location.dart';

/// Converts wall-clock times between storage (UTC) and location timezone views.
class LocationTimezoneDateTime {
  static DateTime encodeWallClockToUtc({
    required DateTime wallClock,
    required LocationFacade? location,
  }) {
    if (location == null) {
      return _asUtcWithSameClock(wallClock);
    }

    final tzLocation = _resolveLocation(location);
    if (tzLocation == null) {
      return _asUtcWithSameClock(wallClock);
    }

    final zonedDateTime = tz.TZDateTime(
      tzLocation,
      wallClock.year,
      wallClock.month,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
      wallClock.second,
      wallClock.millisecond,
      wallClock.microsecond,
    );

    return zonedDateTime.toUtc();
  }

  static DateTime decodeUtcToWallClock({
    required DateTime storedDateTime,
    required LocationFacade? location,
  }) {
    final utcDateTime =
        storedDateTime.isUtc ? storedDateTime : storedDateTime.toUtc();
    final tzLocation = location == null ? null : _resolveLocation(location);
    if (tzLocation == null) {
      return DateTime(
        utcDateTime.year,
        utcDateTime.month,
        utcDateTime.day,
        utcDateTime.hour,
        utcDateTime.minute,
        utcDateTime.second,
        utcDateTime.millisecond,
        utcDateTime.microsecond,
      );
    }

    final zoned = tz.TZDateTime.from(utcDateTime, tzLocation);
    return DateTime(
      zoned.year,
      zoned.month,
      zoned.day,
      zoned.hour,
      zoned.minute,
      zoned.second,
      zoned.millisecond,
      zoned.microsecond,
    );
  }

  static DateTime retargetStoredDateTime({
    required DateTime storedDateTime,
    required LocationFacade? oldLocation,
    required LocationFacade? newLocation,
  }) {
    final wallClock = decodeUtcToWallClock(
      storedDateTime: storedDateTime,
      location: oldLocation,
    );
    return encodeWallClockToUtc(
      wallClock: wallClock,
      location: newLocation,
    );
  }

  static bool isOnSameDay({
    required DateTime storedDateTime,
    required DateTime day,
    required LocationFacade? location,
  }) {
    final localDateTime = decodeUtcToWallClock(
      storedDateTime: storedDateTime,
      location: location,
    );
    return localDateTime.year == day.year &&
        localDateTime.month == day.month &&
        localDateTime.day == day.day;
  }

  static String formatHourMinuteAmPm({
    required DateTime storedDateTime,
    required LocationFacade? location,
  }) {
    final localDateTime = decodeUtcToWallClock(
      storedDateTime: storedDateTime,
      location: location,
    );
    return DateFormat('h:mm a').format(localDateTime);
  }

  static DateTime _asUtcWithSameClock(DateTime dateTime) => DateTime.utc(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond,
      );

  static tz.Location? _resolveLocation(LocationFacade location) {
    final timezoneId =
        latLngToTimezoneString(location.latitude, location.longitude);
    try {
      return tz.getLocation(timezoneId);
    } on Exception catch (_) {
      return null;
    }
  }
}
