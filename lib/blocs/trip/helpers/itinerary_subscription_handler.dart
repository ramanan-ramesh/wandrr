import 'package:wandrr/blocs/trip/helpers/subscription_manager.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';

/// Callback interface for itinerary subscription events
typedef OnItineraryUpdated = void Function(CollectionItemChangeMetadata);

/// Handles subscriptions for itinerary plan data
class ItinerarySubscriptionHandler {
  final ItineraryFacadeCollectionEventHandler _itineraryCollection;
  final SubscriptionManager _subscriptionManager;
  final bool Function() _isBlocClosed;
  final OnItineraryUpdated _onUpdated;

  ItinerarySubscriptionHandler({
    required ItineraryFacadeCollectionEventHandler itineraryCollection,
    required SubscriptionManager subscriptionManager,
    required bool Function() isBlocClosed,
    required OnItineraryUpdated onUpdated,
  })  : _itineraryCollection = itineraryCollection,
        _subscriptionManager = subscriptionManager,
        _isBlocClosed = isBlocClosed,
        _onUpdated = onUpdated;

  /// Creates subscriptions for all itinerary plan data
  Future<void> createSubscriptions() async {
    for (final itinerary in _itineraryCollection) {
      final planDataSubscription = itinerary.planDataStream.listen((eventData) {
        if (eventData.isFromExplicitAction || _isBlocClosed()) return;

        final metadata = CollectionItemChangeMetadata(
          eventData.modifiedCollectionItem,
          isFromExplicitAction: false,
        );
        _onUpdated(metadata);
      });

      _subscriptionManager
          .addItineraryPlanDataSubscription(planDataSubscription);
    }
  }
}
