import 'package:flutter/foundation.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';

/// Helper class for determining if timeline should rebuild based on state changes
class TimelineRebuildHelper {
  final DateTime itineraryDay;

  const TimelineRebuildHelper(this.itineraryDay);

  /// Determines if the timeline should rebuild based on state change
  bool shouldRebuild(
    TripManagementState previousState,
    TripManagementState currentState,
  ) {
    if (currentState.isTripEntityUpdated<LodgingFacade>()) {
      return _shouldRebuildForLodging(currentState);
    }
    if (currentState.isTripEntityUpdated<TransitFacade>()) {
      return _shouldRebuildForTransit(currentState);
    }
    if (currentState.isTripEntityUpdated<ItineraryPlanData>()) {
      return _shouldRebuildForSight(currentState);
    }
    return false;
  }

  /// Checks if should rebuild for lodging changes
  bool _shouldRebuildForLodging(TripManagementState state) {
    final tripEntityUpdatedState = state as UpdatedTripEntity;
    final dataState = tripEntityUpdatedState.dataState;
    final collectionItemChangeset = tripEntityUpdatedState
        .tripEntityModificationData.modifiedCollectionItem;

    if (dataState == DataState.delete || dataState == DataState.create) {
      final lodging = collectionItemChangeset as LodgingFacade;
      return _doesItineraryDayFallDuringStayDuration(lodging);
    }

    if (dataState == DataState.update) {
      if (collectionItemChangeset is! CollectionItemChangeSet<LodgingFacade>) {
        return false;
      }
      final lodgingBeforeUpdate = collectionItemChangeset.beforeUpdate;
      final lodgingAfterUpdate = collectionItemChangeset.afterUpdate;

      final wasOnItineraryDay =
          _doesItineraryDayFallDuringStayDuration(lodgingBeforeUpdate);
      final isOnItineraryDay =
          _doesItineraryDayFallDuringStayDuration(lodgingAfterUpdate);

      if (wasOnItineraryDay || isOnItineraryDay) {
        return true;
      }
    }
    return false;
  }

  /// Checks if should rebuild for transit changes
  bool _shouldRebuildForTransit(TripManagementState state) {
    final tripEntityUpdatedState = state as UpdatedTripEntity;
    final dataState = tripEntityUpdatedState.dataState;
    final collectionItemChangeset = tripEntityUpdatedState
        .tripEntityModificationData.modifiedCollectionItem;

    if (dataState == DataState.delete || dataState == DataState.create) {
      final transit = collectionItemChangeset as TransitFacade;
      return _isTransitOnItineraryDay(transit);
    }

    if (dataState == DataState.update) {
      if (collectionItemChangeset is! CollectionItemChangeSet<TransitFacade>) {
        return false;
      }
      final transitBeforeUpdate = collectionItemChangeset.beforeUpdate;
      final transitAfterUpdate = collectionItemChangeset.afterUpdate;

      final wasOnItineraryDay = _isTransitOnItineraryDay(transitBeforeUpdate);
      final isOnItineraryDay = _isTransitOnItineraryDay(transitAfterUpdate);

      if (wasOnItineraryDay || isOnItineraryDay) {
        return true;
      }
    }
    return false;
  }

  /// Checks if should rebuild for sight changes
  bool _shouldRebuildForSight(TripManagementState state) {
    final tripEntityUpdatedState = state as UpdatedTripEntity;
    final dataState = tripEntityUpdatedState.dataState;

    if (dataState == DataState.update) {
      final collectionItemChangeset = tripEntityUpdatedState
          .tripEntityModificationData.modifiedCollectionItem;

      if (collectionItemChangeset
          is! CollectionItemChangeSet<ItineraryPlanData>) {
        return false;
      }

      if (collectionItemChangeset.beforeUpdate.day
              .isOnSameDayAs(itineraryDay) ||
          collectionItemChangeset.afterUpdate.day.isOnSameDayAs(itineraryDay)) {
        final sightsBeforeUpdate = collectionItemChangeset.beforeUpdate.sights;
        final sightsAfterUpdate = collectionItemChangeset.afterUpdate.sights;
        return !listEquals(sightsBeforeUpdate, sightsAfterUpdate);
      }
    }
    return false;
  }

  /// Checks if itinerary day falls during stay duration
  bool _doesItineraryDayFallDuringStayDuration(LodgingFacade lodging) {
    var checkinDate = lodging.checkinDateTime!;
    var checkoutDate = lodging.checkoutDateTime!;
    return (checkinDate.isOnSameDayAs(itineraryDay) ||
            itineraryDay.isAfter(checkinDate)) &&
        (checkoutDate.isOnSameDayAs(itineraryDay) ||
            itineraryDay.isBefore(checkoutDate));
  }

  /// Checks if transit is on the itinerary day
  bool _isTransitOnItineraryDay(TransitFacade transit) {
    return transit.arrivalDateTime!.isOnSameDayAs(itineraryDay) ||
        transit.departureDateTime!.isOnSameDayAs(itineraryDay);
  }
}
