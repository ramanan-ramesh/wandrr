import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_metadata_update.dart';

/// Service to detect timeline conflicts when editing transits, stays, or sights.
/// Detects conflicts across ALL entity types (transits, stays, sights).
/// A conflict occurs when:
/// - Time ranges overlap (one starts before the other ends)
/// - Any boundary exactly matches (e.g., departure == arrival of another)
class TimelineConflictDetector {
  final TripDataFacade tripData;

  TimelineConflictDetector({required this.tripData});

  /// Detects conflicts for a transit being added or edited.
  /// Checks for conflicting transits, stays, AND sights.
  TripEntityUpdatePlan? detectTransitConflicts({
    required TransitFacade transit,
    required bool isNewEntity,
  }) {
    if (transit.departureDateTime == null || transit.arrivalDateTime == null) {
      return null;
    }

    final depTime = transit.departureDateTime!;
    final arrTime = transit.arrivalDateTime!;

    final transitConflicts = _findConflictingTransits(
      depTime,
      arrTime,
      excludeId: isNewEntity ? null : transit.id,
    );
    final stayConflicts = _findConflictingStays(depTime, arrTime);
    final sightConflicts = _findConflictingSights(depTime, arrTime);

    if (transitConflicts.isEmpty &&
        stayConflicts.isEmpty &&
        sightConflicts.isEmpty) {
      return null;
    }

    final metadata = tripData.tripMetadata;
    return TripEntityUpdatePlan(
      transitChanges: transitConflicts,
      stayChanges: stayConflicts,
      sightChanges: sightConflicts,
      tripStartDate: metadata.startDate!,
      tripEndDate: metadata.endDate!,
    );
  }

  /// Detects conflicts for a stay being added or edited.
  /// Checks for conflicting stays, transits, AND sights.
  TripEntityUpdatePlan? detectStayConflicts({
    required LodgingFacade stay,
    required bool isNewEntity,
  }) {
    if (stay.checkinDateTime == null || stay.checkoutDateTime == null) {
      return null;
    }

    final checkinTime = stay.checkinDateTime!;
    final checkoutTime = stay.checkoutDateTime!;

    final stayConflicts = _findConflictingStays(
      checkinTime,
      checkoutTime,
      excludeId: isNewEntity ? null : stay.id,
    );
    final transitConflicts =
        _findConflictingTransits(checkinTime, checkoutTime);
    final sightConflicts = _findConflictingSights(checkinTime, checkoutTime);

    if (stayConflicts.isEmpty &&
        transitConflicts.isEmpty &&
        sightConflicts.isEmpty) {
      return null;
    }

    final metadata = tripData.tripMetadata;
    return TripEntityUpdatePlan(
      transitChanges: transitConflicts,
      stayChanges: stayConflicts,
      sightChanges: sightConflicts,
      tripStartDate: metadata.startDate!,
      tripEndDate: metadata.endDate!,
    );
  }

  /// Detects conflicts for a sight being added or edited.
  /// Checks for conflicting sights, transits, AND stays.
  TripEntityUpdatePlan? detectSightConflicts({
    required SightFacade sight,
    required bool isNewEntity,
  }) {
    if (sight.visitTime == null) {
      return null;
    }

    final visitTime = sight.visitTime!;
    // Assume sight visits last about 2 hours for conflict detection
    final visitEndTime = visitTime.add(const Duration(hours: 2));

    final transitConflicts = _findConflictingTransits(visitTime, visitEndTime);
    final stayConflicts = _findConflictingStays(visitTime, visitEndTime);
    final sightConflicts = _findConflictingSights(
      visitTime,
      visitEndTime,
      excludeId: isNewEntity ? null : sight.id,
    );

    if (transitConflicts.isEmpty &&
        stayConflicts.isEmpty &&
        sightConflicts.isEmpty) {
      return null;
    }

    final metadata = tripData.tripMetadata;
    return TripEntityUpdatePlan(
      transitChanges: transitConflicts,
      stayChanges: stayConflicts,
      sightChanges: sightConflicts,
      tripStartDate: metadata.startDate!,
      tripEndDate: metadata.endDate!,
    );
  }

  /// Finds transits that conflict with the given time range.
  /// Conflict = overlapping time ranges OR exact boundary match.
  List<EntityChange<TransitFacade>> _findConflictingTransits(
    DateTime newStart,
    DateTime newEnd, {
    String? excludeId,
  }) {
    final conflicts = <EntityChange<TransitFacade>>[];
    for (final transit in tripData.transitCollection.collectionItems) {
      if (excludeId != null && transit.id == excludeId) continue;
      if (transit.departureDateTime == null ||
          transit.arrivalDateTime == null) {
        continue;
      }

      final depTime = transit.departureDateTime!;
      final arrTime = transit.arrivalDateTime!;

      if (_hasConflict(newStart, newEnd, depTime, arrTime)) {
        final conflictType =
            _getConflictType(newStart, newEnd, depTime, arrTime);
        final routeDesc =
            '${transit.departureLocation?.context.name ?? "?"} → ${transit.arrivalLocation?.context.name ?? "?"}';
        final message = _buildTransitConflictMessage(transit, conflictType);

        // Try to clamp the transit times
        final clampedTransit = _clampTransitTimes(transit, newStart, newEnd);

        if (clampedTransit != null) {
          conflicts.add(EntityChange<TransitFacade>.forClamping(
            originalEntity: transit,
            modifiedEntity: clampedTransit,
            conflictDescription: routeDesc,
            originalTimeDescription: _formatTransitTime(transit),
            conflictMessage: message,
            conflictType: conflictType,
          ));
        } else {
          // Can't clamp - mark for deletion
          conflicts.add(EntityChange<TransitFacade>.forDeletion(
            originalEntity: transit,
            conflictDescription: routeDesc,
            originalTimeDescription: _formatTransitTime(transit),
            conflictMessage: message,
            conflictType: conflictType,
          ));
        }
      }
    }
    return conflicts;
  }

  /// Tries to clamp transit times around the conflicting range
  /// Returns null if the transit cannot be reasonably clamped
  TransitFacade? _clampTransitTimes(
    TransitFacade transit,
    DateTime conflictStart,
    DateTime conflictEnd,
  ) {
    if (transit.departureDateTime == null || transit.arrivalDateTime == null) {
      return null;
    }

    final depTime = transit.departureDateTime!;
    final arrTime = transit.arrivalDateTime!;

    // If transit is completely within the conflict range, it must be deleted
    if (depTime.isAfter(conflictStart) && arrTime.isBefore(conflictEnd)) {
      return null;
    }

    // If transit starts before conflict and ends during/after, clamp end to conflict start
    if (depTime.isBefore(conflictStart) && arrTime.isAfter(conflictStart)) {
      // Transit must end before conflict starts (at least 1 minute before)
      final newArrival = conflictStart.subtract(const Duration(minutes: 1));
      if (newArrival.isAfter(depTime)) {
        final cloned = transit.clone();
        cloned.arrivalDateTime = newArrival;
        return cloned;
      }
      return null;
    }

    // If transit starts during conflict and ends after, clamp start to conflict end
    if (depTime.isBefore(conflictEnd) && arrTime.isAfter(conflictEnd)) {
      // Transit must start after conflict ends (at least 1 minute after)
      final newDeparture = conflictEnd.add(const Duration(minutes: 1));
      if (newDeparture.isBefore(arrTime)) {
        final cloned = transit.clone();
        cloned.departureDateTime = newDeparture;
        return cloned;
      }
      return null;
    }

    return null;
  }

  String _buildTransitConflictMessage(
      TransitFacade transit, ConflictType type) {
    final route =
        '${transit.departureLocation?.context.name ?? "Unknown"} → ${transit.arrivalLocation?.context.name ?? "Unknown"}';
    switch (type) {
      case ConflictType.overlap:
        return 'Transit "$route" overlaps with your journey time';
      case ConflictType.boundaryMatch:
        return 'Transit "$route" departs/arrives at the same time as your journey';
      case ConflictType.contained:
        return 'Transit "$route" is completely within your journey time';
    }
  }

  ConflictType _getConflictType(
    DateTime newStart,
    DateTime newEnd,
    DateTime existingStart,
    DateTime existingEnd,
  ) {
    // Check for boundary matches first
    if (_isSameTime(newStart, existingStart) ||
        _isSameTime(newStart, existingEnd) ||
        _isSameTime(newEnd, existingStart) ||
        _isSameTime(newEnd, existingEnd)) {
      return ConflictType.boundaryMatch;
    }

    // Check if existing is completely contained
    if (existingStart.isAfter(newStart) && existingEnd.isBefore(newEnd)) {
      return ConflictType.contained;
    }

    return ConflictType.overlap;
  }

  /// Finds stays that conflict with the given time range.
  /// Conflict = overlapping time ranges OR exact boundary match.
  List<EntityChange<LodgingFacade>> _findConflictingStays(
    DateTime newStart,
    DateTime newEnd, {
    String? excludeId,
  }) {
    final conflicts = <EntityChange<LodgingFacade>>[];
    for (final stay in tripData.lodgingCollection.collectionItems) {
      if (excludeId != null && stay.id == excludeId) continue;
      if (stay.checkinDateTime == null || stay.checkoutDateTime == null) {
        continue;
      }

      final checkin = stay.checkinDateTime!;
      final checkout = stay.checkoutDateTime!;

      if (_hasConflict(newStart, newEnd, checkin, checkout)) {
        final conflictType =
            _getConflictType(newStart, newEnd, checkin, checkout);
        final locationDesc = stay.location?.context.name ?? 'Unknown location';
        final message = _buildStayConflictMessage(stay, conflictType);

        // Try to clamp the stay times
        final clampedStay = _clampStayTimes(stay, newStart, newEnd);

        if (clampedStay != null) {
          conflicts.add(EntityChange<LodgingFacade>.forClamping(
            originalEntity: stay,
            modifiedEntity: clampedStay,
            conflictDescription: locationDesc,
            originalTimeDescription: _formatStayTime(stay),
            conflictMessage: message,
            conflictType: conflictType,
          ));
        } else {
          // Can't clamp - mark for deletion
          conflicts.add(EntityChange<LodgingFacade>.forDeletion(
            originalEntity: stay,
            conflictDescription: locationDesc,
            originalTimeDescription: _formatStayTime(stay),
            conflictMessage: message,
            conflictType: conflictType,
          ));
        }
      }
    }
    return conflicts;
  }

  /// Tries to clamp stay times around the conflicting range
  /// Returns null if the stay cannot be reasonably clamped
  LodgingFacade? _clampStayTimes(
    LodgingFacade stay,
    DateTime conflictStart,
    DateTime conflictEnd,
  ) {
    if (stay.checkinDateTime == null || stay.checkoutDateTime == null) {
      return null;
    }

    final checkin = stay.checkinDateTime!;
    final checkout = stay.checkoutDateTime!;

    // If stay is completely within the conflict range, it must be deleted
    if (checkin.isAfter(conflictStart) && checkout.isBefore(conflictEnd)) {
      return null;
    }

    // If stay checkout falls during conflict, clamp checkout to before conflict
    if (checkin.isBefore(conflictStart) && checkout.isAfter(conflictStart)) {
      // Stay must checkout before conflict starts (at least 1 hour before for stays)
      final newCheckout = conflictStart.subtract(const Duration(hours: 1));
      if (newCheckout.isAfter(checkin)) {
        final cloned = stay.clone();
        cloned.checkoutDateTime = newCheckout;
        return cloned;
      }
      return null;
    }

    // If stay checkin falls during conflict, clamp checkin to after conflict
    if (checkin.isBefore(conflictEnd) && checkout.isAfter(conflictEnd)) {
      // Stay must checkin after conflict ends (at least 1 hour after for stays)
      final newCheckin = conflictEnd.add(const Duration(hours: 1));
      if (newCheckin.isBefore(checkout)) {
        final cloned = stay.clone();
        cloned.checkinDateTime = newCheckin;
        return cloned;
      }
      return null;
    }

    return null;
  }

  String _buildStayConflictMessage(LodgingFacade stay, ConflictType type) {
    final location = stay.location?.context.name ?? 'your stay';
    switch (type) {
      case ConflictType.overlap:
        return 'Stay at "$location" check-in/checkout overlaps with your journey';
      case ConflictType.boundaryMatch:
        return 'Stay at "$location" check-in/checkout time matches your journey time';
      case ConflictType.contained:
        return 'Stay at "$location" is completely within your journey time';
    }
  }

  /// Finds sights that conflict with the given time range.
  /// Conflict = overlapping time ranges OR exact boundary match.
  List<EntityChange<SightFacade>> _findConflictingSights(
    DateTime newStart,
    DateTime newEnd, {
    String? excludeId,
  }) {
    final conflicts = <EntityChange<SightFacade>>[];
    for (final itinerary in tripData.itineraryCollection) {
      for (final sight in itinerary.planData.sights) {
        if (excludeId != null && sight.id == excludeId) continue;
        if (sight.visitTime == null) continue;

        final visitStart = sight.visitTime!;
        final visitEnd = visitStart.add(const Duration(hours: 2));

        if (_hasConflict(newStart, newEnd, visitStart, visitEnd)) {
          final conflictType =
              _getConflictType(newStart, newEnd, visitStart, visitEnd);
          final message = _buildSightConflictMessage(sight, conflictType);

          // Try to clamp the sight time
          final clampedSight = _clampSightTime(sight, newStart, newEnd);

          if (clampedSight != null) {
            conflicts.add(EntityChange<SightFacade>.forClamping(
              originalEntity: sight,
              modifiedEntity: clampedSight,
              conflictDescription: sight.name,
              originalTimeDescription: _formatSightTime(sight),
              conflictMessage: message,
              conflictType: conflictType,
            ));
          } else {
            // Can't clamp - mark for deletion (or clear visit time)
            conflicts.add(EntityChange<SightFacade>.forDeletion(
              originalEntity: sight,
              conflictDescription: sight.name,
              originalTimeDescription: _formatSightTime(sight),
              conflictMessage: message,
              conflictType: conflictType,
            ));
          }
        }
      }
    }
    return conflicts;
  }

  /// Tries to clamp sight visit time around the conflicting range
  /// Returns null if the sight cannot be reasonably clamped
  SightFacade? _clampSightTime(
    SightFacade sight,
    DateTime conflictStart,
    DateTime conflictEnd,
  ) {
    if (sight.visitTime == null) {
      return null;
    }

    final visitTime = sight.visitTime!;
    final visitEnd = visitTime.add(const Duration(hours: 2));

    // If sight visit is completely within the conflict range, clear the time
    if (visitTime.isAfter(conflictStart) && visitEnd.isBefore(conflictEnd)) {
      // Can't clamp - the visit is entirely during the conflict
      return null;
    }

    // If visit starts before conflict but ends during it, move visit earlier
    if (visitTime.isBefore(conflictStart) && visitEnd.isAfter(conflictStart)) {
      // Keep same day, just move time to before conflict
      final newVisitTime =
          conflictStart.subtract(const Duration(hours: 2, minutes: 30));
      // Make sure it's still on the same day as the original
      if (newVisitTime.day == visitTime.day && newVisitTime.hour >= 6) {
        final cloned = sight.clone();
        cloned.visitTime = newVisitTime;
        return cloned;
      }
      return null;
    }

    // If visit starts during conflict, move it to after conflict
    if (visitTime.isAfter(conflictStart) && visitTime.isBefore(conflictEnd)) {
      final newVisitTime = conflictEnd.add(const Duration(minutes: 30));
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

  String _buildSightConflictMessage(SightFacade sight, ConflictType type) {
    final name = sight.name.isNotEmpty ? sight.name : 'this sight';
    switch (type) {
      case ConflictType.overlap:
        return 'Visit to "$name" overlaps with your journey';
      case ConflictType.boundaryMatch:
        return 'Visit time for "$name" coincides with your journey time';
      case ConflictType.contained:
        return 'Visit to "$name" is during your journey';
    }
  }

  /// Checks if two time ranges conflict.
  /// A conflict occurs if:
  /// - The ranges overlap (one starts before the other ends)
  /// - Any boundary exactly matches another boundary
  bool _hasConflict(
    DateTime newStart,
    DateTime newEnd,
    DateTime existingStart,
    DateTime existingEnd,
  ) {
    // Check for exact boundary matches
    if (_isSameTime(newStart, existingStart) ||
        _isSameTime(newStart, existingEnd) ||
        _isSameTime(newEnd, existingStart) ||
        _isSameTime(newEnd, existingEnd)) {
      return true;
    }

    // Check for overlapping ranges
    // Overlap occurs when: newStart < existingEnd AND newEnd > existingStart
    return newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart);
  }

  /// Checks if two DateTimes represent the same moment in time
  bool _isSameTime(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  String _formatTransitTime(TransitFacade t) {
    if (t.departureDateTime == null || t.arrivalDateTime == null) {
      return 'No time';
    }
    final depDate = t.departureDateTime!;
    final arrDate = t.arrivalDateTime!;
    return '${depDate.dayDateMonthFormat} ${depDate.hourMinuteAmPmFormat} → ${arrDate.dayDateMonthFormat} ${arrDate.hourMinuteAmPmFormat}';
  }

  String _formatStayTime(LodgingFacade s) {
    if (s.checkinDateTime == null || s.checkoutDateTime == null) {
      return 'No dates';
    }
    final checkin = s.checkinDateTime!;
    final checkout = s.checkoutDateTime!;
    return '${checkin.dayDateMonthFormat} ${checkin.hourMinuteAmPmFormat} → ${checkout.dayDateMonthFormat} ${checkout.hourMinuteAmPmFormat}';
  }

  String _formatSightTime(SightFacade s) {
    if (s.visitTime == null) return 'No time';
    return '${s.visitTime!.dayDateMonthFormat} ${s.visitTime!.hourMinuteAmPmFormat}';
  }
}
