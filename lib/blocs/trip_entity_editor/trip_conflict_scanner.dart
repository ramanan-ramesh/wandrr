import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_timeline_position.dart';
import 'package:wandrr/data/trip/models/services/time_range.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

import 'conflict_result.dart';
import 'entity_time_clamper.dart';

/// Exclusion criteria for scanning conflicts.
/// Each entity type has its own exclusion list to avoid false positives.
class ConflictScanExclusions {
  final Set<String> transitIds;
  final Set<String> stayIds;
  final Set<String> sightIds;

  const ConflictScanExclusions({
    this.transitIds = const {},
    this.stayIds = const {},
    this.sightIds = const {},
  });

  /// Creates exclusions for multiple transits (e.g., journey legs)
  factory ConflictScanExclusions.forTransits(Iterable<String> transitIds) {
    return ConflictScanExclusions(transitIds: transitIds.toSet());
  }

  /// Creates exclusions for a single stay
  factory ConflictScanExclusions.forStay(String? stayId) {
    return ConflictScanExclusions(
      stayIds: stayId != null ? {stayId} : {},
    );
  }

  /// Creates exclusions for multiple sights (e.g., in same itinerary)
  factory ConflictScanExclusions.forSights(Iterable<String> sightIds) {
    return ConflictScanExclusions(sightIds: sightIds.toSet());
  }
}

/// Pure service for detecting timeline conflicts in trip data.
/// Contains only pure logic - no UI concerns or message building.
class TripConflictScanner {
  final TripDataFacade _tripData;

  /// Assumed duration for sight visits when checking conflicts
  static const _sightVisitDuration = Duration(minutes: 1);

  TripConflictScanner({required TripDataFacade tripData})
      : _tripData = tripData;

  /// Scans for all entities that conflict with the given time range.
  /// Uses type-specific exclusions to avoid false positives.
  AggregatedConflicts scanForConflicts({
    required TimeRange referenceRange,
    required TripEntity tripEntity,
    ConflictScanExclusions exclusions = const ConflictScanExclusions(),
  }) {
    return AggregatedConflicts(
      transitConflicts: _findTransitConflicts(
          referenceRange, exclusions.transitIds, tripEntity),
      stayConflicts:
          _findStayConflicts(referenceRange, exclusions.stayIds, tripEntity),
      sightConflicts:
          _findSightConflicts(referenceRange, exclusions.sightIds, tripEntity),
    );
  }

  /// Scans for entities affected by trip metadata changes (date/contributor changes).
  /// Returns null if no changes require user attention.
  MetadataUpdateConflicts? scanForMetadataUpdate({
    required TripMetadataFacade oldMetadata,
    required TripMetadataFacade newMetadata,
  }) {
    final datesChanged =
        !oldMetadata.startDate!.isOnSameDayAs(newMetadata.startDate!) ||
            !oldMetadata.endDate!.isOnSameDayAs(newMetadata.endDate!);
    final contributorsChanged =
        _haveContributorsChanged(oldMetadata, newMetadata);

    if (!datesChanged && !contributorsChanged) return null;

    final newTripRange = TimeRange(
      start: newMetadata.startDate!,
      end: DateTime(newMetadata.endDate!.year, newMetadata.endDate!.month,
          newMetadata.endDate!.day, 23, 59),
    );

    final stayConflicts = datesChanged
        ? _findStaysConflictingWithTripDates(newTripRange)
        : <StayConflict>[];
    final transitConflicts = datesChanged
        ? _findTransitsOutsideDateRange(newTripRange)
        : <TransitConflict>[];
    final sightConflicts = datesChanged
        ? _findSightsOutsideDateRange(newTripRange)
        : <SightConflict>[];
    final expenseEntities = contributorsChanged
        ? _collectAllExpenseBearingEntities()
        : <ExpenseBearingTripEntity>[];

    if (stayConflicts.isEmpty &&
        transitConflicts.isEmpty &&
        sightConflicts.isEmpty &&
        expenseEntities.isEmpty) {
      return null;
    }

    return MetadataUpdateConflicts(
      stayConflicts: stayConflicts,
      transitConflicts: transitConflicts,
      sightConflicts: sightConflicts,
      expenseEntities: expenseEntities,
      oldMetadata: oldMetadata,
      newMetadata: newMetadata,
    );
  }

  bool _haveContributorsChanged(
      TripMetadataFacade oldMeta, TripMetadataFacade newMeta) {
    final oldSet = oldMeta.contributors.toSet();
    final newSet = newMeta.contributors.toSet();
    return oldSet.difference(newSet).isNotEmpty ||
        newSet.difference(oldSet).isNotEmpty;
  }

  List<StayConflict> _findStaysConflictingWithTripDates(
      TimeRange newTripRange) {
    final conflicts = <StayConflict>[];
    for (final stay in _tripData.lodgingCollection.collectionItems) {
      final checkin = stay.checkinDateTime!;
      final checkout = stay.checkoutDateTime!;
      var stayTimeRange =
          TimeRange(start: stay.checkinDateTime!, end: stay.checkoutDateTime!);
      final position = stayTimeRange.analyzePosition(newTripRange);
      if (position == EntityTimelinePosition.beforeEvent ||
          position == EntityTimelinePosition.afterEvent ||
          position == EntityTimelinePosition.startsBeforeEndsDuring ||
          position == EntityTimelinePosition.startsDuringEndsAfter ||
          position == EntityTimelinePosition.contains) {
        final clamped =
            EntityTimeClamper.clampStayToDateRange(stay, newTripRange);
        conflicts.add(StayConflict(
          entity: stay,
          entityTimeRange: TimeRange(start: checkin, end: checkout),
          position: position,
          clampedEntity: clamped,
        ));
      }
    }
    return conflicts;
  }

  List<TransitConflict> _findTransitsOutsideDateRange(TimeRange newTripRange) {
    final conflicts = <TransitConflict>[];
    for (final transit in _tripData.transitCollection.collectionItems) {
      final dep = transit.departureDateTime!;
      final arr = transit.arrivalDateTime!;
      final travelTimeRange = TimeRange(start: dep, end: arr);
      final position = travelTimeRange.analyzePosition(newTripRange);
      if (position == EntityTimelinePosition.beforeEvent ||
          position == EntityTimelinePosition.afterEvent ||
          position == EntityTimelinePosition.startsBeforeEndsDuring ||
          position == EntityTimelinePosition.startsDuringEndsAfter ||
          position == EntityTimelinePosition.contains) {
        final modified = transit.clone();
        modified.departureDateTime = null;
        modified.arrivalDateTime = null;
        conflicts.add(TransitConflict(
          entity: transit,
          entityTimeRange: TimeRange(start: dep, end: arr),
          position: position,
          clampedEntity: modified,
        ));
      }
    }
    return conflicts;
  }

  List<SightConflict> _findSightsOutsideDateRange(TimeRange newTripRange) {
    final conflicts = <SightConflict>[];
    for (final itinerary in _tripData.itineraryCollection) {
      for (final sight in itinerary.planData.sights) {
        if (sight.visitTime != null) {
          final sightDay = sight.day;
          final visitTimeRange = TimeRange(
              start: sight.visitTime!,
              end: sight.visitTime!.add(_sightVisitDuration));
          final position = visitTimeRange.analyzePosition(newTripRange);
          if (position == EntityTimelinePosition.beforeEvent ||
              position == EntityTimelinePosition.afterEvent ||
              position == EntityTimelinePosition.contains ||
              position == EntityTimelinePosition.startsBeforeEndsDuring ||
              position == EntityTimelinePosition.startsDuringEndsAfter) {
            final modified = sight.clone();
            modified.visitTime = null;
            conflicts.add(SightConflict(
              entity: sight,
              entityTimeRange: TimeRange(
                start: sight.visitTime ?? sightDay,
                end: (sight.visitTime ?? sightDay).add(_sightVisitDuration),
              ),
              position: EntityTimelinePosition.beforeEvent,
              clampedEntity: modified,
            ));
          }
        }
      }
    }
    return conflicts;
  }

  List<ExpenseBearingTripEntity> _collectAllExpenseBearingEntities() {
    final entities = <ExpenseBearingTripEntity>[];
    entities.addAll(_tripData.expenseCollection.collectionItems);
    entities.addAll(_tripData.transitCollection.collectionItems);
    entities.addAll(_tripData.lodgingCollection.collectionItems);
    for (final itinerary in _tripData.itineraryCollection) {
      entities.addAll(itinerary.planData.sights);
    }
    return entities;
  }

  List<TransitConflict> _findTransitConflicts(TimeRange referenceRange,
      Set<String> excludeTransitIds, TripEntity tripEntity) {
    final conflicts = <TransitConflict>[];

    for (final transit in _tripData.transitCollection.collectionItems) {
      // Skip if this transit is in the exclusion list
      if (transit.id != null && excludeTransitIds.contains(transit.id)) {
        continue;
      }
      if (transit.departureDateTime == null ||
          transit.arrivalDateTime == null) {
        continue;
      }

      final entityRange = TimeRange(
        start: transit.departureDateTime!,
        end: transit.arrivalDateTime!,
      );

      final position = entityRange.analyzePosition(referenceRange);
      bool isConflictedWithTripEntity = false;
      if (tripEntity is TransitFacade || tripEntity is SightFacade) {
        isConflictedWithTripEntity =
            position == EntityTimelinePosition.exactBoundaryMatch ||
                position == EntityTimelinePosition.containedIn ||
                position == EntityTimelinePosition.contains ||
                position == EntityTimelinePosition.startsDuringEndsAfter ||
                position == EntityTimelinePosition.startsBeforeEndsDuring;
      } else if (tripEntity is LodgingFacade) {
        isConflictedWithTripEntity =
            position == EntityTimelinePosition.exactBoundaryMatch ||
                position == EntityTimelinePosition.contains ||
                position == EntityTimelinePosition.startsDuringEndsAfter ||
                position == EntityTimelinePosition.startsBeforeEndsDuring;
      }
      if (isConflictedWithTripEntity) {
        final position = entityRange.analyzePosition(referenceRange);
        final clampedTransit =
            EntityTimeClamper.clampTransit(transit, referenceRange, tripEntity);

        conflicts.add(TransitConflict(
          entity: transit,
          entityTimeRange: entityRange,
          position: position,
          clampedEntity: clampedTransit,
        ));
      }
    }

    return conflicts;
  }

  List<StayConflict> _findStayConflicts(TimeRange referenceRange,
      Set<String> excludeStayIds, TripEntity tripEntity) {
    final conflicts = <StayConflict>[];

    for (final stay in _tripData.lodgingCollection.collectionItems) {
      // Skip if this stay is in the exclusion list
      if (stay.id != null && excludeStayIds.contains(stay.id)) {
        continue;
      }
      if (stay.checkinDateTime == null || stay.checkoutDateTime == null) {
        continue;
      }

      final entityRange = TimeRange(
        start: stay.checkinDateTime!,
        end: stay.checkoutDateTime!,
      );

      final position = entityRange.analyzePosition(referenceRange);
      bool isConflictedWithTripEntity = false;
      if (tripEntity is TransitFacade || tripEntity is SightFacade) {
        isConflictedWithTripEntity =
            position == EntityTimelinePosition.exactBoundaryMatch ||
                position == EntityTimelinePosition.containedIn ||
                position == EntityTimelinePosition.startsDuringEndsAfter ||
                position == EntityTimelinePosition.startsBeforeEndsDuring;
      } else if (tripEntity is LodgingFacade) {
        isConflictedWithTripEntity =
            position == EntityTimelinePosition.exactBoundaryMatch ||
                position == EntityTimelinePosition.containedIn ||
                position == EntityTimelinePosition.contains ||
                position == EntityTimelinePosition.startsDuringEndsAfter ||
                position == EntityTimelinePosition.startsBeforeEndsDuring;
      }

      if (isConflictedWithTripEntity) {
        final clampedStay =
            EntityTimeClamper.clampStay(stay, referenceRange, tripEntity);

        conflicts.add(StayConflict(
          entity: stay,
          entityTimeRange: entityRange,
          position: position,
          clampedEntity: clampedStay,
        ));
      }
    }

    return conflicts;
  }

  List<SightConflict> _findSightConflicts(TimeRange referenceRange,
      Set<String> excludeSightIds, TripEntity tripEntity) {
    final conflicts = <SightConflict>[];

    for (final itinerary in _tripData.itineraryCollection) {
      for (final sight in itinerary.planData.sights) {
        // Skip if this sight is in the exclusion list
        if (sight.id != null && excludeSightIds.contains(sight.id)) {
          continue;
        }
        if (sight.visitTime == null) continue;

        final entityRange = TimeRange(
          start: sight.visitTime!,
          end: sight.visitTime!.add(_sightVisitDuration),
        );

        final position = entityRange.analyzePosition(referenceRange);
        bool isConflictedWithTripEntity = false;
        if (tripEntity is TransitFacade || tripEntity is SightFacade) {
          isConflictedWithTripEntity =
              position == EntityTimelinePosition.exactBoundaryMatch ||
                  position == EntityTimelinePosition.contains ||
                  position == EntityTimelinePosition.containedIn ||
                  position == EntityTimelinePosition.startsBeforeEndsDuring ||
                  position == EntityTimelinePosition.startsDuringEndsAfter;
        } else if (tripEntity is LodgingFacade) {
          isConflictedWithTripEntity =
              position == EntityTimelinePosition.exactBoundaryMatch ||
                  position == EntityTimelinePosition.contains ||
                  position == EntityTimelinePosition.startsBeforeEndsDuring ||
                  position == EntityTimelinePosition.startsDuringEndsAfter;
        }
        if (isConflictedWithTripEntity) {
          final clampedSight =
              EntityTimeClamper.clampSight(sight, referenceRange, tripEntity);

          conflicts.add(SightConflict(
            entity: sight,
            entityTimeRange: entityRange,
            position: position,
            clampedEntity: clampedSight,
          ));
        }
      }
    }

    return conflicts;
  }
}
