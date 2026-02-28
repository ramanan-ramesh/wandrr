import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_timeline_position.dart';
import 'package:wandrr/data/trip/models/services/time_range.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

// =============================================================================
// TIME CLAMPING STRATEGIES - Strategy Pattern for entity-specific clamping
// =============================================================================

/// Base interface for entity time clamping strategies.
/// Each entity type has different clamping semantics.
abstract class EntityClampingStrategy<T extends TripEntity> {
  /// Attempts to clamp the entity to avoid the conflict range.
  /// Returns null if clamping is not possible.
  T? clamp(T entity, TimeRange conflictRange, EntityTimelinePosition position);
}

/// Clamping strategy for Transit entities.
class TransitClampingStrategy implements EntityClampingStrategy<TransitFacade> {
  const TransitClampingStrategy();

  @override
  TransitFacade? clamp(
    TransitFacade transit,
    TimeRange conflictRange,
    EntityTimelinePosition position,
  ) {
    final depTime = transit.departureDateTime;
    final arrTime = transit.arrivalDateTime;
    if (depTime == null || arrTime == null) return null;

    DateTime? clampedDep, clampedArr;

    switch (position) {
      case EntityTimelinePosition.exactBoundaryMatch:
        if (depTime.isAtSameMomentAs(conflictRange.end)) {
          clampedDep = conflictRange.end.add(const Duration(minutes: 1));
          if (!arrTime.isAfter(clampedDep)) return null;
        } else if (arrTime.isAtSameMomentAs(conflictRange.start)) {
          clampedArr = conflictRange.start.subtract(const Duration(minutes: 1));
          if (!depTime.isBefore(clampedArr)) return null;
        }

      case EntityTimelinePosition.startsDuringEndsAfter:
        clampedDep = conflictRange.end.add(const Duration(minutes: 1));
        if (!arrTime.isAfter(clampedDep)) return null;

      case EntityTimelinePosition.startsBeforeEndsDuring:
        clampedArr = conflictRange.start.subtract(const Duration(minutes: 1));
        if (!depTime.isBefore(clampedArr)) return null;

      default:
        // Contains, containedIn - cannot clamp
        return null;
    }

    if (clampedDep == null && clampedArr == null) return null;

    final clamped = transit.clone();
    if (clampedDep != null) clamped.departureDateTime = clampedDep;
    if (clampedArr != null) clamped.arrivalDateTime = clampedArr;
    return clamped;
  }
}

/// Clamping strategy for Stay/Lodging entities.
class StayClampingStrategy implements EntityClampingStrategy<LodgingFacade> {
  const StayClampingStrategy();

  @override
  LodgingFacade? clamp(
    LodgingFacade stay,
    TimeRange conflictRange,
    EntityTimelinePosition position,
  ) {
    final checkin = stay.checkinDateTime;
    final checkout = stay.checkoutDateTime;
    if (checkin == null || checkout == null) return null;

    DateTime? clampedCheckin, clampedCheckout;

    switch (position) {
      case EntityTimelinePosition.exactBoundaryMatch:
        if (checkin.isAtSameMomentAs(conflictRange.end)) {
          clampedCheckin = _roundToNextHalfHour(conflictRange.end);
          if (!checkout.isAfter(clampedCheckin)) return null;
        } else if (checkout.isAtSameMomentAs(conflictRange.start)) {
          clampedCheckout = _roundToPreviousHalfHour(conflictRange.start);
          if (!checkin.isBefore(clampedCheckout)) return null;
        }

      case EntityTimelinePosition.startsDuringEndsAfter:
        clampedCheckin = _roundToNextHalfHour(conflictRange.end);
        if (!checkout.isAfter(clampedCheckin)) return null;

      case EntityTimelinePosition.startsBeforeEndsDuring:
        clampedCheckout = _roundToPreviousHalfHour(conflictRange.start);
        if (!checkin.isBefore(clampedCheckout)) return null;

      default:
        return null;
    }

    if (clampedCheckin == null && clampedCheckout == null) return null;

    final clamped = stay.clone();
    if (clampedCheckin != null) clamped.checkinDateTime = clampedCheckin;
    if (clampedCheckout != null) clamped.checkoutDateTime = clampedCheckout;
    return clamped;
  }

  DateTime _roundToNextHalfHour(DateTime dt) {
    final normalized = dt.copyWith(second: 0, millisecond: 0, microsecond: 0);
    final minutes = normalized.minute;

    if (minutes == 0 || (minutes > 0 && minutes < 30)) {
      return normalized.copyWith(minute: 30);
    } else if (minutes == 30) {
      return normalized.add(const Duration(minutes: 30));
    } else {
      return normalized.add(const Duration(hours: 1)).copyWith(minute: 0);
    }
  }

  DateTime _roundToPreviousHalfHour(DateTime dt) {
    final normalized = dt.copyWith(second: 0, millisecond: 0, microsecond: 0);
    final minutes = normalized.minute;

    if (minutes == 0) {
      return normalized.subtract(const Duration(minutes: 30));
    } else if (minutes > 0 && minutes <= 30) {
      return normalized.copyWith(minute: 0);
    } else {
      return normalized.copyWith(minute: 30);
    }
  }
}

/// Clamping strategy for Sight entities.
class SightClampingStrategy implements EntityClampingStrategy<SightFacade> {
  const SightClampingStrategy();

  @override
  SightFacade? clamp(
    SightFacade sight,
    TimeRange conflictRange,
    EntityTimelinePosition position,
  ) {
    final visitTime = sight.visitTime;
    if (visitTime == null) return null;

    DateTime? clampedTime;

    switch (position) {
      case EntityTimelinePosition.exactBoundaryMatch:
        final visitEnd = visitTime.add(const Duration(minutes: 1));
        if (visitTime.isAtSameMomentAs(conflictRange.end)) {
          clampedTime = conflictRange.end.add(const Duration(minutes: 1));
        } else if (visitEnd.isAtSameMomentAs(conflictRange.start)) {
          clampedTime =
              conflictRange.start.subtract(const Duration(minutes: 1));
        }

      default:
        // Sights are points in time - can only clamp exact boundary matches
        return null;
    }

    if (clampedTime == null) return null;

    final clamped = sight.clone();
    clamped.visitTime = clampedTime;
    return clamped;
  }
}

// =============================================================================
// TRIP DATE RANGE CLAMPING - For metadata updates
// =============================================================================

/// Clamping strategy for stays when trip dates change.
class StayDateRangeClampingStrategy {
  const StayDateRangeClampingStrategy();

  LodgingFacade? clamp(LodgingFacade stay, TimeRange newTripRange) {
    final checkin = stay.checkinDateTime!;
    final checkout = stay.checkoutDateTime!;

    DateTime clampedCheckin = checkin;
    DateTime clampedCheckout = checkout;

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

    // Validate clamped dates
    if (!clampedCheckin.isBefore(clampedCheckout)) return null;

    // Same day check-in/check-out is not valid for overnight stays
    if (clampedCheckin.year == clampedCheckout.year &&
        clampedCheckin.month == clampedCheckout.month &&
        clampedCheckin.day == clampedCheckout.day) {
      return null;
    }

    final clamped = stay.clone();
    clamped.checkinDateTime = clampedCheckin;
    clamped.checkoutDateTime = clampedCheckout;
    return clamped;
  }
}

// =============================================================================
// CLAMPING SERVICE - Facade for all clamping operations
// =============================================================================

/// Unified service for clamping entity times.
/// Uses strategy pattern internally to delegate to appropriate strategy.
class EntityClamper {
  static final _transitStrategy = const TransitClampingStrategy();
  static final _stayStrategy = const StayClampingStrategy();
  static final _sightStrategy = const SightClampingStrategy();
  static final _stayDateRangeStrategy = const StayDateRangeClampingStrategy();

  const EntityClamper._();

  /// Clamps a transit to avoid the conflict range.
  static TransitFacade? clampTransit(
    TransitFacade transit,
    TimeRange conflictRange,
    EntityTimelinePosition position,
  ) {
    return _transitStrategy.clamp(transit, conflictRange, position);
  }

  /// Clamps a stay to avoid the conflict range.
  static LodgingFacade? clampStay(
    LodgingFacade stay,
    TimeRange conflictRange,
    EntityTimelinePosition position,
  ) {
    return _stayStrategy.clamp(stay, conflictRange, position);
  }

  /// Clamps a sight to avoid the conflict range.
  static SightFacade? clampSight(
    SightFacade sight,
    TimeRange conflictRange,
    EntityTimelinePosition position,
  ) {
    return _sightStrategy.clamp(sight, conflictRange, position);
  }

  /// Clamps a stay to fit within the new trip date range.
  static LodgingFacade? clampStayToDateRange(
    LodgingFacade stay,
    TimeRange newTripRange,
  ) {
    return _stayDateRangeStrategy.clamp(stay, newTripRange);
  }
}
