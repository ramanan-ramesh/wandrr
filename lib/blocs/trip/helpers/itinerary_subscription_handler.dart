import 'package:wandrr/blocs/trip/helpers/subscription_manager.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';

/// Callback interface for itinerary subscription events
typedef OnItineraryUpdated = void Function(CollectionItemChangeMetadata);

/// Handles subscriptions for itinerary plan data
class ItinerarySubscriptionHandler {
  final ItineraryFacadeCollection _itineraryCollection;
  final SubscriptionManager _subscriptionManager;
  final OnItineraryUpdated _onUpdated;

  ItinerarySubscriptionHandler({
    required ItineraryFacadeCollection itineraryCollection,
    required SubscriptionManager subscriptionManager,
    required OnItineraryUpdated onUpdated,
  })  : _itineraryCollection = itineraryCollection,
        _subscriptionManager = subscriptionManager,
        _onUpdated = onUpdated;

  /// Creates subscriptions for all itinerary plan data
  Future<void> createSubscriptions() async {
    for (final itinerary in _itineraryCollection) {
      final planDataSubscription = itinerary.planDataStream.listen(_onUpdated);
      _subscriptionManager
          .addItineraryPlanDataSubscription(planDataSubscription);
    }
  }
}
