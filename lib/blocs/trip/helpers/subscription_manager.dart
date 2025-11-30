import 'dart:async';

import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Manages all stream subscriptions for the TripManagementBloc
class SubscriptionManager {
  final _tripStreamSubscriptions = <StreamSubscription>[];
  final _tripRepositorySubscriptions = <StreamSubscription>[];
  final _itineraryPlanDataSubscriptions = <StreamSubscription>[];

  /// Adds a trip stream subscription to the manager
  void addTripStreamSubscription(StreamSubscription subscription) {
    _tripStreamSubscriptions.add(subscription);
  }

  /// Adds a trip repository subscription to the manager
  void addTripRepositorySubscription(StreamSubscription subscription) {
    _tripRepositorySubscriptions.add(subscription);
  }

  /// Adds an itinerary plan data subscription to the manager
  void addItineraryPlanDataSubscription(StreamSubscription subscription) {
    _itineraryPlanDataSubscriptions.add(subscription);
  }

  /// Subscribes to collection updates for a specific trip entity type
  void subscribeToCollectionUpdates<T extends TripEntity>({
    required ModelCollectionFacade<T> modelCollection,
    required void Function(CollectionItemChangeMetadata<T>) onAdded,
    required void Function(CollectionItemChangeMetadata<T>) onDeleted,
    required void Function(CollectionItemChangeMetadata) onUpdated,
  }) {
    final addedSubscription =
        modelCollection.onDocumentAdded.listen((eventData) {
      if (!eventData.isFromExplicitAction) {
        final metadata = CollectionItemChangeMetadata(
          eventData.modifiedCollectionItem,
          isFromExplicitAction: false,
        );
        onAdded(metadata);
      }
    });

    final deletedSubscription =
        modelCollection.onDocumentDeleted.listen((eventData) {
      if (!eventData.isFromExplicitAction) {
        final metadata = CollectionItemChangeMetadata(
          eventData.modifiedCollectionItem,
          isFromExplicitAction: false,
        );
        onDeleted(metadata);
      }
    });

    final updatedSubscription =
        modelCollection.onDocumentUpdated.listen((eventData) {
      if (!eventData.isFromExplicitAction) {
        final metadata = CollectionItemChangeMetadata(
          eventData.modifiedCollectionItem,
          isFromExplicitAction: false,
        );
        onUpdated(metadata);
      }
    });

    addTripStreamSubscription(addedSubscription);
    addTripStreamSubscription(deletedSubscription);
    addTripStreamSubscription(updatedSubscription);
  }

  /// Clears all trip stream subscriptions
  Future<void> clearTripSubscriptions() async {
    await _cancelSubscriptions(_tripStreamSubscriptions);
    _tripStreamSubscriptions.clear();
    await clearItineraryPlanDataSubscriptions();
  }

  /// Clears all repository subscriptions
  Future<void> clearRepositorySubscriptions() async {
    await _cancelSubscriptions(_tripRepositorySubscriptions);
    _tripRepositorySubscriptions.clear();
  }

  /// Clears all itinerary plan data subscriptions
  Future<void> clearItineraryPlanDataSubscriptions() async {
    await _cancelSubscriptions(_itineraryPlanDataSubscriptions);
    _itineraryPlanDataSubscriptions.clear();
  }

  /// Cancels all subscriptions in the provided list
  Future<void> _cancelSubscriptions(
      List<StreamSubscription> subscriptions) async {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  /// Disposes all subscriptions
  Future<void> dispose() async {
    await clearTripSubscriptions();
    await clearRepositorySubscriptions();
  }
}
