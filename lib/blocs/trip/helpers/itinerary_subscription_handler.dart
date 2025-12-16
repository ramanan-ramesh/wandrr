import 'package:wandrr/blocs/trip/helpers/subscription_manager.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';

/// Handles subscriptions for itinerary plan data
class ItinerarySubscriptionHandler {
  final TripDataModelEventHandler activeTrip;
  final SubscriptionManager subscriptionManager;
  final bool Function() isBlocClosed;
  final void Function(CollectionItemChangeMetadata) onUpdated;

  ItinerarySubscriptionHandler({
    required this.activeTrip,
    required this.subscriptionManager,
    required this.isBlocClosed,
    required this.onUpdated,
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
        onUpdated(metadata);
      });

      subscriptionManager
          .addItineraryPlanDataSubscription(planDataSubscription);
    }
  }
}
