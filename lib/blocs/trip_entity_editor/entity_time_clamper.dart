import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_timeline_position.dart';
import 'package:wandrr/data/trip/models/services/time_range.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Pure logic for clamping entity times to resolve conflicts.
/// Contains no UI-specific code.
class EntityTimeClamper {
  /// Tries to clamp transit times around a conflict range.
  /// Returns null if the transit cannot be reasonably clamped.
  static TransitFacade? clampTransit(
    TransitFacade transit,
    TimeRange conflictRange,
    TripEntity tripEntity,
  ) {
    TransitFacade? clampedTransit;
    final depTime = transit.departureDateTime!;
    final arrTime = transit.arrivalDateTime!;
    DateTime? clampedDepartureDateTime, clampedArrivalDateTime;
    final transitTimeRange = TimeRange(start: depTime, end: arrTime);

    final position = transitTimeRange.analyzePosition(conflictRange);

    if (position == EntityTimelinePosition.exactBoundaryMatch) {
      if (depTime.isAtSameMomentAs(conflictRange.end)) {
        clampedDepartureDateTime = conflictRange.end.add(Duration(minutes: 1));
        if (!arrTime.isAfter(clampedDepartureDateTime)) {
          clampedArrivalDateTime = null;
        }
      } else if (arrTime.isAtSameMomentAs(conflictRange.start)) {
        clampedArrivalDateTime =
            conflictRange.start.subtract(Duration(minutes: 1));
        if (!depTime.isBefore(clampedArrivalDateTime)) {
          clampedDepartureDateTime = null;
        }
      }
    } else if (position == EntityTimelinePosition.startsDuringEndsAfter) {
      var oneMinuteAfterConflictEnd =
          conflictRange.end.add(Duration(minutes: 1));
      clampedDepartureDateTime = oneMinuteAfterConflictEnd;
      if (!arrTime.isAfter(oneMinuteAfterConflictEnd)) {
        clampedArrivalDateTime = null;
      }
    } else if (position == EntityTimelinePosition.startsBeforeEndsDuring) {
      var oneMinuteBeforeConflictStart =
          conflictRange.start.subtract(Duration(minutes: 1));
      clampedArrivalDateTime = oneMinuteBeforeConflictStart;
      if (!depTime.isBefore(oneMinuteBeforeConflictStart)) {
        clampedDepartureDateTime = null;
      }
    }

    if (clampedDepartureDateTime != null || clampedArrivalDateTime != null) {
      clampedTransit = transit.clone();
      if (clampedDepartureDateTime != null) {
        clampedTransit.departureDateTime = clampedDepartureDateTime;
      }
      if (clampedArrivalDateTime != null) {
        clampedTransit.arrivalDateTime = clampedArrivalDateTime;
      }
    }

    return clampedTransit;
  }

  /// Tries to clamp stay times around a conflict range.
  /// Returns null if the stay cannot be reasonably clamped.
  static LodgingFacade? clampStay(
      LodgingFacade stay, TimeRange conflictRange, TripEntity tripEntity) {
    if (stay.checkinDateTime == null || stay.checkoutDateTime == null) {
      return null;
    }

    final checkin = stay.checkinDateTime!;
    final checkout = stay.checkoutDateTime!;
    DateTime? clampedCheckin, clampedCheckout;
    final stayRange = TimeRange(start: checkin, end: checkout);
    final position = stayRange.analyzePosition(conflictRange);
    LodgingFacade? clampedStay;

    if (position == EntityTimelinePosition.exactBoundaryMatch) {
      if (checkin.isAtSameMomentAs(conflictRange.end)) {
        clampedCheckin = _roundOffTimeToNextHalfHour(conflictRange.end);
        if (!checkout.isAfter(clampedCheckin)) {
          clampedCheckout = null;
        }
      } else if (checkout.isAtSameMomentAs(conflictRange.start)) {
        clampedCheckout = _roundOffTimeToPreviousHalfHour(conflictRange.start);
        if (!checkin.isBefore(clampedCheckout)) {
          clampedCheckin = null;
        }
      }
    } else if (position == EntityTimelinePosition.startsDuringEndsAfter &&
        (tripEntity is TransitFacade || tripEntity is SightFacade)) {
      clampedCheckin = _roundOffTimeToNextHalfHour(conflictRange.end);
      if (!checkout.isAfter(clampedCheckin)) {
        clampedCheckout = null;
      }
    } else if (position == EntityTimelinePosition.startsBeforeEndsDuring &&
        (tripEntity is TransitFacade || tripEntity is SightFacade)) {
      clampedCheckout = _roundOffTimeToPreviousHalfHour(conflictRange.start);
      if (!checkin.isBefore(clampedCheckout)) {
        clampedCheckin = null;
      }
    }

    if (clampedCheckin != null || clampedCheckout != null) {
      clampedStay = stay.clone();
      if (clampedCheckin != null) {
        clampedStay.checkinDateTime = clampedCheckin;
      }
      if (clampedCheckout != null) {
        clampedStay.checkoutDateTime = clampedCheckout;
      }
    }

    return clampedStay;
  }

  /// Tries to clamp sight visit time around a conflict range.
  /// Returns null if the sight cannot be reasonably clamped.
  static SightFacade? clampSight(
      SightFacade sight, TimeRange conflictRange, TripEntity tripEntity) {
    if (sight.visitTime == null) {
      return null;
    }

    SightFacade? clampedSight;
    final visitStart = sight.visitTime!;
    final visitEnd = visitStart.add(Duration(minutes: 1));
    final visitTimeRange = TimeRange(start: visitStart, end: visitEnd);

    final position = visitTimeRange.analyzePosition(conflictRange);

    if (position == EntityTimelinePosition.exactBoundaryMatch) {
      if (visitStart.isAtSameMomentAs(conflictRange.end)) {
        clampedSight = sight.clone();
        clampedSight.visitTime = conflictRange.end.add(Duration(minutes: 1));
      } else if (visitEnd.isAtSameMomentAs(conflictRange.start)) {
        clampedSight = sight.clone();
        clampedSight.visitTime =
            conflictRange.start.subtract(Duration(minutes: 1));
      }
    }

    return clampedSight;
  }

  /// Clamps a stay to fit within a new trip date range.
  /// Used when trip dates change and stay falls outside new range.
  /// Returns null if the stay cannot be reasonably clamped.
  static LodgingFacade? clampStayToDateRange(
    LodgingFacade stay,
    TimeRange newTripRange,
  ) {
    final checkin = stay.checkinDateTime!;
    final checkout = stay.checkoutDateTime!;

    DateTime? clampedCheckin = checkin;
    DateTime? clampedCheckout = checkout;

    // Clamp checkin to be within range
    if (checkin.isBefore(newTripRange.start)) {
      clampedCheckin = DateTime(
        newTripRange.start.year,
        newTripRange.start.month,
        newTripRange.start.day,
        checkin.hour,
        checkin.minute,
      );
    } else if (checkin.isAfter(newTripRange.end)) {
      return null; // Checkin after trip ends - cannot clamp
    }

    // Clamp checkout to be within range
    if (checkout.isAfter(newTripRange.end)) {
      clampedCheckout = DateTime(
        newTripRange.end.year,
        newTripRange.end.month,
        newTripRange.end.day,
        checkout.hour,
        checkout.minute,
      );
    } else if (checkout.isBefore(newTripRange.start)) {
      return null; // Checkout before trip starts - cannot clamp
    }

    // Validate clamped dates are valid (checkin before checkout, different days)
    if (!clampedCheckin.isBefore(clampedCheckout)) {
      return null;
    }
    // Same day check-in/check-out is not valid for overnight stays
    if (clampedCheckin.year == clampedCheckout.year &&
        clampedCheckin.month == clampedCheckout.month &&
        clampedCheckin.day == clampedCheckout.day) {
      return null;
    }

    final cloned = stay.clone();
    cloned.checkinDateTime = clampedCheckin;
    cloned.checkoutDateTime = clampedCheckout;
    return cloned;
  }

  static DateTime _roundOffTimeToNextHalfHour(DateTime dt) {
    // Normalize the DateTime by setting seconds, milliseconds, and microseconds to 0
    // to ensure consistent clamping behavior irrespective of sub-minute precision.
    DateTime normalizedDt =
        dt.copyWith(second: 0, millisecond: 0, microsecond: 0);

    int minutes = normalizedDt.minute;

    if (minutes == 0) {
      // If it's exactly on the hour (e.g., 4:00), clamp to HH:30 (e.g., 4:30).
      return normalizedDt.copyWith(minute: 30);
    } else if (minutes > 0 && minutes < 30) {
      // If minutes are between 1 and 29 (e.g., 4:20), clamp to HH:30 (e.g., 4:30).
      return normalizedDt.copyWith(minute: 30);
    } else if (minutes == 30) {
      // If it's exactly on the half-hour (e.g., 4:30), clamp to the next hour:00 (e.g., 5:00).
      // Adding 30 minutes to a time ending in :30 will automatically roll over to the next hour.
      return normalizedDt.add(const Duration(minutes: 30));
    } else {
      // minutes > 30 (i.e., from 31 to 59)
      // If minutes are after the half-hour (e.g., 4:45), clamp to the next hour:00 (e.g., 5:00).
      // Add 1 hour and set minutes to 0.
      return normalizedDt.add(const Duration(hours: 1)).copyWith(minute: 0);
    }
  }

  static DateTime _roundOffTimeToPreviousHalfHour(DateTime dt) {
    // Normalize the DateTime by setting seconds, milliseconds, and microseconds to 0
    DateTime normalizedDt =
        dt.copyWith(second: 0, millisecond: 0, microsecond: 0);
    int minutes = normalizedDt.minute;

    if (minutes == 0) {
      // If it's exactly on the hour (e.g., 4:00), previous is HH-1:30 (e.g., 3:30).
      return normalizedDt.subtract(const Duration(minutes: 30));
    } else if (minutes > 0 && minutes <= 30) {
      // If minutes are between 1 and 30 (e.g., 4:20, 4:30), previous is HH:00 (e.g., 4:00).
      return normalizedDt.copyWith(minute: 0);
    } else {
      // minutes > 30 (i.e., from 31 to 59)
      // If minutes are after the half-hour (e.g., 4:45), previous is HH:30 (e.g., 4:30).
      return normalizedDt.copyWith(minute: 30);
    }
  }
}
