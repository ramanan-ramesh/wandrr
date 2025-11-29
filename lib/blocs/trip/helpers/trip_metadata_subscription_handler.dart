import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/helpers/subscription_manager.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';

/// Handles subscriptions for trip metadata collection
class TripMetadataSubscriptionHandler {
  final TripRepositoryEventHandler tripRepository;
  final SubscriptionManager subscriptionManager;
  final TripDataModelEventHandler? activeTrip;
  final bool Function() isBlocClosed;
  final void Function(TripManagementEvent) addEvent;
  final Future<void> Function() clearItinerarySubscriptions;
  final Future<void> Function() createItinerarySubscriptions;
  final TripManagementEvent Function(
      CollectionItemChangeMetadata<
          CollectionItemChangeSet<TripMetadataFacade>>) createUpdateEvent;
  final TripManagementEvent Function(
      CollectionItemChangeMetadata<TripMetadataFacade>) createAddEvent;
  final TripManagementEvent Function(
      CollectionItemChangeMetadata<TripMetadataFacade>) createDeleteEvent;

  TripMetadataSubscriptionHandler({
    required this.tripRepository,
    required this.subscriptionManager,
    required this.activeTrip,
    required this.isBlocClosed,
    required this.addEvent,
    required this.clearItinerarySubscriptions,
    required this.createItinerarySubscriptions,
    required this.createUpdateEvent,
    required this.createAddEvent,
    required this.createDeleteEvent,
  });

  /// Creates subscriptions for trip metadata collection
  void createSubscriptions() {
    _subscribeToUpdates();
    _subscribeToAdded();
    _subscribeToDeleted();
  }

  /// Subscribes to trip metadata updates
  void _subscribeToUpdates() {
    final subscription = tripRepository.tripMetadataCollection.onDocumentUpdated
        .listen((eventData) {
      if (_shouldIgnoreEvent(eventData.modifiedCollectionItem.afterUpdate.id)) {
        return;
      }

      if (eventData.isFromExplicitAction || isBlocClosed()) return;

      _handleDateChanges(eventData);
      _addUpdateEvent(eventData.modifiedCollectionItem);
    });

    subscriptionManager.addTripRepositorySubscription(subscription);
  }

  /// Subscribes to trip metadata additions
  void _subscribeToAdded() {
    final subscription = tripRepository.tripMetadataCollection.onDocumentAdded
        .listen((eventData) {
      if (_shouldIgnoreEvent(eventData.modifiedCollectionItem.id)) {
        return;
      }

      if (eventData.isFromExplicitAction || isBlocClosed()) return;

      final metadata = CollectionItemChangeMetadata(
        eventData.modifiedCollectionItem,
        isFromExplicitAction: false,
      );
      addEvent(createAddEvent(metadata));
    });

    subscriptionManager.addTripRepositorySubscription(subscription);
  }

  /// Subscribes to trip metadata deletions
  void _subscribeToDeleted() {
    final subscription = tripRepository.tripMetadataCollection.onDocumentDeleted
        .listen((eventData) {
      if (_shouldIgnoreEvent(eventData.modifiedCollectionItem.id)) {
        return;
      }

      if (eventData.isFromExplicitAction || isBlocClosed()) return;

      final metadata = CollectionItemChangeMetadata(
        eventData.modifiedCollectionItem,
        isFromExplicitAction: false,
      );
      addEvent(createDeleteEvent(metadata));
    });

    subscriptionManager.addTripRepositorySubscription(subscription);
  }

  /// Checks if the event should be ignored (not for active trip)
  bool _shouldIgnoreEvent(String? eventId) {
    return activeTrip != null && activeTrip!.tripMetadata.id != eventId;
  }

  /// Handles trip date changes and recreates itinerary subscriptions if needed
  void _handleDateChanges(
      CollectionItemChangeMetadata<CollectionItemChangeSet<TripMetadataFacade>>
          eventData) {
    if (activeTrip == null) return;

    final updatedMetadata = eventData.modifiedCollectionItem.afterUpdate;
    final beforeUpdate = eventData.modifiedCollectionItem.beforeUpdate;

    final hasStartDateChanged =
        !beforeUpdate.startDate!.isOnSameDayAs(updatedMetadata.startDate!);
    final hasEndDateChanged =
        !beforeUpdate.endDate!.isOnSameDayAs(updatedMetadata.endDate!);

    if (hasStartDateChanged || hasEndDateChanged) {
      clearItinerarySubscriptions().then((_) => createItinerarySubscriptions());
    }
  }

  /// Adds an update event for trip metadata
  void _addUpdateEvent(
      CollectionItemChangeSet<TripMetadataFacade> modifiedCollectionItem) {
    final metadata = CollectionItemChangeMetadata(
      modifiedCollectionItem,
      isFromExplicitAction: false,
    );
    addEvent(createUpdateEvent(metadata));
  }
}
