import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/helpers/subscription_manager.dart';
import 'package:wandrr/data/store/models/change_set.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

/// Callback interface for trip metadata change events
typedef OnTripMetadataChanged = Future<void> Function();

/// Callback interface for trip metadata events
typedef CreateTripMetadataEvent = TripManagementEvent Function(
  CollectionItemChangeMetadata,
);

/// Handles subscriptions for trip metadata collection
class TripMetadataSubscriptionHandler {
  final ModelCollectionFacade<TripMetadataFacade> _tripMetadataCollection;
  final SubscriptionManager _subscriptionManager;

  /// Returns the currently active trip at the time of an event (not captured at construction).
  final TripDataModelEventHandler? Function() _getActiveTrip;
  final bool Function() _isBlocClosed;
  final void Function(TripManagementEvent) _addEvent;
  final OnTripMetadataChanged _onDateChanged;
  final CreateTripMetadataEvent _createUpdateEvent;
  final CreateTripMetadataEvent _createAddEvent;
  final CreateTripMetadataEvent _createDeleteEvent;

  TripMetadataSubscriptionHandler({
    required ModelCollectionFacade<TripMetadataFacade> tripMetadataCollection,
    required SubscriptionManager subscriptionManager,
    required TripDataModelEventHandler? Function() getActiveTrip,
    required bool Function() isBlocClosed,
    required void Function(TripManagementEvent) addEvent,
    required OnTripMetadataChanged onDateChanged,
    required CreateTripMetadataEvent createUpdateEvent,
    required CreateTripMetadataEvent createAddEvent,
    required CreateTripMetadataEvent createDeleteEvent,
  })  : _tripMetadataCollection = tripMetadataCollection,
        _subscriptionManager = subscriptionManager,
        _getActiveTrip = getActiveTrip,
        _isBlocClosed = isBlocClosed,
        _addEvent = addEvent,
        _onDateChanged = onDateChanged,
        _createUpdateEvent = createUpdateEvent,
        _createAddEvent = createAddEvent,
        _createDeleteEvent = createDeleteEvent;

  /// Creates subscriptions for trip metadata collection
  void createSubscriptions() {
    _subscribeToUpdates();
    _subscribeToAdded();
    _subscribeToDeleted();
  }

  /// Subscribes to trip metadata updates
  void _subscribeToUpdates() {
    final subscription =
        _tripMetadataCollection.onDocumentUpdated.listen((eventData) {
      if (_shouldIgnoreEvent(eventData.collectionItemChange.afterUpdate.id)) {
        return;
      }

      if (eventData.isFromExplicitAction || _isBlocClosed()) {
        return;
      }

      _handleDateChanges(eventData);
      final metadata = CollectionItemChangeMetadata(
        eventData.collectionItemChange,
        isFromExplicitAction: false,
      );
      _addEvent(_createUpdateEvent(metadata));
    });

    _subscriptionManager.addTripRepositorySubscription(subscription);
  }

  /// Subscribes to trip metadata additions
  void _subscribeToAdded() {
    final subscription =
        _tripMetadataCollection.onDocumentAdded.listen((eventData) {
      if (_shouldIgnoreEvent(eventData.collectionItemChange.id)) {
        return;
      }

      if (eventData.isFromExplicitAction || _isBlocClosed()) {
        return;
      }

      final metadata = CollectionItemChangeMetadata(
        eventData.collectionItemChange,
        isFromExplicitAction: false,
      );
      _addEvent(_createAddEvent(metadata));
    });

    _subscriptionManager.addTripRepositorySubscription(subscription);
  }

  /// Subscribes to trip metadata deletions
  void _subscribeToDeleted() {
    final subscription =
        _tripMetadataCollection.onDocumentDeleted.listen((eventData) {
      if (_shouldIgnoreEvent(eventData.collectionItemChange.id)) {
        return;
      }

      if (eventData.isFromExplicitAction || _isBlocClosed()) {
        return;
      }

      final metadata = CollectionItemChangeMetadata(
        eventData.collectionItemChange,
        isFromExplicitAction: false,
      );
      _addEvent(_createDeleteEvent(metadata));
    });

    _subscriptionManager.addTripRepositorySubscription(subscription);
  }

  /// Returns true when the event should not be forwarded to the bloc.
  /// Events for trips other than the active one are suppressed when a trip
  /// is active; all events are processed when no trip is loaded (home screen).
  bool _shouldIgnoreEvent(String? eventId) {
    final activeTrip = _getActiveTrip();
    return activeTrip != null && activeTrip.tripMetadata.id != eventId;
  }

  /// Handles trip date changes and recreates itinerary subscriptions if needed.
  /// Only acts when the updated metadata belongs to the currently active trip.
  void _handleDateChanges(
      CollectionItemChangeMetadata<Changeset<TripMetadataFacade>> eventData) {
    final updatedMetadata = eventData.collectionItemChange.afterUpdate;
    final beforeUpdate = eventData.collectionItemChange.beforeUpdate;

    // Ignore date-change handling for trips other than the active one.
    final activeTrip = _getActiveTrip();
    if (activeTrip == null ||
        activeTrip.tripMetadata.id != updatedMetadata.id) {
      return;
    }

    final hasStartDateChanged =
        !beforeUpdate.startDate!.isOnSameDayAs(updatedMetadata.startDate!);
    final hasEndDateChanged =
        !beforeUpdate.endDate!.isOnSameDayAs(updatedMetadata.endDate!);

    if (hasStartDateChanged || hasEndDateChanged) {
      _onDateChanged();
    }
  }
}
