import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';

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
    return TripEntityUpdatePlan.forTimelineConflicts(
      transitConflicts: transitConflicts,
      stayConflicts: stayConflicts,
      sightConflicts: sightConflicts,
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
    return TripEntityUpdatePlan.forTimelineConflicts(
      transitConflicts: transitConflicts,
      stayConflicts: stayConflicts,
      sightConflicts: sightConflicts,
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
    return TripEntityUpdatePlan.forTimelineConflicts(
      transitConflicts: transitConflicts,
      stayConflicts: stayConflicts,
      sightConflicts: sightConflicts,
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
        conflicts.add(EntityChange<TransitFacade>.forDeletion(
          originalEntity: transit,
          conflictDescription:
              '${transit.departureLocation ?? "?"} → ${transit.arrivalLocation ?? "?"}',
          originalTimeDescription: _formatTransitTime(transit),
        ));
      }
    }
    return conflicts;
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
        conflicts.add(EntityChange<LodgingFacade>.forDeletion(
          originalEntity: stay,
          conflictDescription: stay.location?.toString() ?? 'Unknown',
          originalTimeDescription: _formatStayTime(stay),
        ));
      }
    }
    return conflicts;
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
          conflicts.add(EntityChange<SightFacade>.forDeletion(
            originalEntity: sight,
            conflictDescription: sight.name,
            originalTimeDescription: _formatSightTime(sight),
          ));
        }
      }
    }
    return conflicts;
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
    return '${t.departureDateTime!.dayDateMonthFormat} - ${t.arrivalDateTime!.dayDateMonthFormat}';
  }

  String _formatStayTime(LodgingFacade s) {
    if (s.checkinDateTime == null || s.checkoutDateTime == null) {
      return 'No dates';
    }
    return '${s.checkinDateTime!.dayDateMonthFormat} - ${s.checkoutDateTime!.dayDateMonthFormat}';
  }

  String _formatSightTime(SightFacade s) {
    if (s.visitTime == null) return 'No time';
    return s.visitTime!.dayDateMonthFormat;
  }
}
