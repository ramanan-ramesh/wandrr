import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';

import 'time_range.dart';

/// Pure logic for clamping entity times to resolve conflicts.
/// Contains no UI-specific code.
class EntityTimeClamper {
  const EntityTimeClamper._();

  /// Minimum gap between transit times
  static const _transitGap = Duration(minutes: 1);

  /// Minimum gap between stay times
  static const _stayGap = Duration(hours: 1);

  /// Assumed sight visit duration
  static const _sightDuration = Duration(minutes: 1);

  /// Tries to clamp transit times around a conflict range.
  /// Returns null if the transit cannot be reasonably clamped.
  static TransitFacade? clampTransit(
    TransitFacade transit,
    TimeRange conflictRange,
  ) {
    if (transit.departureDateTime == null || transit.arrivalDateTime == null) {
      return null;
    }

    final depTime = transit.departureDateTime!;
    final arrTime = transit.arrivalDateTime!;

    // If transit is completely within the conflict range, it must be deleted
    if (depTime.isAfter(conflictRange.start) &&
        arrTime.isBefore(conflictRange.end)) {
      return null;
    }

    // If transit starts before conflict and ends during/after, clamp end to conflict start
    if (depTime.isBefore(conflictRange.start) &&
        arrTime.isAfter(conflictRange.start)) {
      final newArrival = conflictRange.start.subtract(_transitGap);
      if (newArrival.isAfter(depTime)) {
        final cloned = transit.clone();
        cloned.arrivalDateTime = newArrival;
        return cloned;
      }
      return null;
    }

    // If transit starts during conflict and ends after, clamp start to conflict end
    if (depTime.isBefore(conflictRange.end) &&
        arrTime.isAfter(conflictRange.end)) {
      final newDeparture = conflictRange.end.add(_transitGap);
      if (newDeparture.isBefore(arrTime)) {
        final cloned = transit.clone();
        cloned.departureDateTime = newDeparture;
        return cloned;
      }
      return null;
    }

    return null;
  }

  /// Tries to clamp stay times around a conflict range.
  /// Returns null if the stay cannot be reasonably clamped.
  static LodgingFacade? clampStay(
    LodgingFacade stay,
    TimeRange conflictRange,
  ) {
    if (stay.checkinDateTime == null || stay.checkoutDateTime == null) {
      return null;
    }

    final checkin = stay.checkinDateTime!;
    final checkout = stay.checkoutDateTime!;

    // If stay is completely within the conflict range, it must be deleted
    if (checkin.isAfter(conflictRange.start) &&
        checkout.isBefore(conflictRange.end)) {
      return null;
    }

    // If stay checkout falls during conflict, clamp checkout to before conflict
    if (checkin.isBefore(conflictRange.start) &&
        checkout.isAfter(conflictRange.start)) {
      final newCheckout = conflictRange.start.subtract(_stayGap);
      if (newCheckout.isAfter(checkin)) {
        final cloned = stay.clone();
        cloned.checkoutDateTime = newCheckout;
        return cloned;
      }
      return null;
    }

    // If stay checkin falls during conflict, clamp checkin to after conflict
    if (checkin.isBefore(conflictRange.end) &&
        checkout.isAfter(conflictRange.end)) {
      final newCheckin = conflictRange.end.add(_stayGap);
      if (newCheckin.isBefore(checkout)) {
        final cloned = stay.clone();
        cloned.checkinDateTime = newCheckin;
        return cloned;
      }
      return null;
    }

    return null;
  }

  /// Tries to clamp sight visit time around a conflict range.
  /// Returns null if the sight cannot be reasonably clamped.
  static SightFacade? clampSight(
    SightFacade sight,
    TimeRange conflictRange,
  ) {
    if (sight.visitTime == null) {
      return null;
    }

    final visitTime = sight.visitTime!;
    final visitEnd = visitTime.add(_sightDuration);

    // If sight visit is completely within the conflict range, cannot clamp
    if (visitTime.isAfter(conflictRange.start) &&
        visitEnd.isBefore(conflictRange.end)) {
      return null;
    }

    // If visit starts before conflict but ends during it, move visit earlier
    if (visitTime.isBefore(conflictRange.start) &&
        visitEnd.isAfter(conflictRange.start)) {
      final newVisitTime = conflictRange.start
          .subtract(_sightDuration + const Duration(minutes: 30));
      // Make sure it's still on the same day and reasonable time
      if (newVisitTime.day == visitTime.day && newVisitTime.hour >= 6) {
        final cloned = sight.clone();
        cloned.visitTime = newVisitTime;
        return cloned;
      }
      return null;
    }

    // If visit starts during conflict, move it to after conflict
    if (visitTime.isAfter(conflictRange.start) &&
        visitTime.isBefore(conflictRange.end)) {
      final newVisitTime = conflictRange.end.add(const Duration(minutes: 30));
      // Make sure it's still reasonable (before 10 PM)
      if (newVisitTime.hour < 22) {
        final cloned = sight.clone();
        cloned.visitTime = newVisitTime;
        return cloned;
      }
      return null;
    }

    return null;
  }

  /// Clamps a stay to fit within a new trip date range.
  /// Used when trip dates change and stay falls outside new range.
  /// Returns null if the stay cannot be reasonably clamped.
  static LodgingFacade? clampStayToDateRange(
    LodgingFacade stay,
    TimeRange newTripRange,
  ) {
    if (stay.checkinDateTime == null || stay.checkoutDateTime == null) {
      return null;
    }

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
}
