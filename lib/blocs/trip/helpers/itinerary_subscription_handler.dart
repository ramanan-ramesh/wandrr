import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/helpers/subscription_manager.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';

/// Handles subscriptions for itinerary plan data
class ItinerarySubscriptionHandler {
  final TripDataModelEventHandler activeTrip;
  final SubscriptionManager subscriptionManager;
  final bool Function() isBlocClosed;
  final void Function(TripManagementEvent) addEvent;

  ItinerarySubscriptionHandler({
    required this.activeTrip,
    required this.subscriptionManager,
    required this.isBlocClosed,
    required this.addEvent,
  });

  /// Creates subscriptions for all itinerary plan data
  Future<void> createSubscriptions() async {
    for (final itinerary in activeTrip.itineraryCollection) {
      final planDataSubscription = itinerary.planDataStream.listen((eventData) {
        if (eventData.isFromExplicitAction || isBlocClosed()) return;

        final metadata = CollectionItemChangeMetadata(
          eventData.modifiedCollectionItem,
          isFromExplicitAction: false,
        );
        addEvent(_UpdateTripEntityInternalEvent.updated(
          metadata,
          isOperationSuccess: true,
        ));
      });

      subscriptionManager
          .addItineraryPlanDataSubscription(planDataSubscription);
    }
  }
}

/// Internal event for trip entity updates from subscriptions
class _UpdateTripEntityInternalEvent<T> extends TripManagementEvent {
  final CollectionItemChangeMetadata<T> updateData;
  final bool isOperationSuccess;

  const _UpdateTripEntityInternalEvent.updated(
    this.updateData, {
    required this.isOperationSuccess,
  });
}
