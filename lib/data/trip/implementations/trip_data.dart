import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/implementations/firestore_model_collection.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary/itinerary_collection.dart';
import 'package:wandrr/data/trip/implementations/services/trip_data_update_plan_service.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

import 'expense.dart';
import 'lodging.dart';
import 'transit.dart';
import 'trip_metadata.dart';

class TripDataModelImplementation extends TripDataModelEventHandler {
  static TripDataModelImplementation createInstance(
      TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository) {
    var tripMetadataModelImplementation =
        TripMetadataModelImplementation.fromModelFacade(
            tripMetadataModelFacade: tripMetadata);

    var tripDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripMetadata.id);

    var transitModelCollection = FirestoreModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.transitCollectionName),
        (documentSnapshot) => TransitImplementation.fromDocumentSnapshot(
            tripMetadata.id!, documentSnapshot),
        (transitModelFacade) => TransitImplementation.fromModelFacade(
            transitModelFacade: transitModelFacade));
    var lodgingModelCollection = FirestoreModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.lodgingCollectionName),
        (documentSnapshot) => LodgingModelImplementation.fromDocumentSnapshot(
            tripId: tripMetadata.id!, documentSnapshot: documentSnapshot),
        (lodgingModelFacade) => LodgingModelImplementation.fromModelFacade(
            lodgingModelFacade: lodgingModelFacade));
    var expenseModelCollection = FirestoreModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.expenseCollectionName),
        (documentSnapshot) =>
            StandaloneExpenseModelImplementation.fromDocumentSnapshot(
                tripId: tripMetadata.id!, documentSnapshot: documentSnapshot),
        (expenseModelFacade) =>
            StandaloneExpenseModelImplementation.fromModelFacade(
                expenseModelFacade: expenseModelFacade));

    var itineraries = ItineraryCollection.createInstance(
        transitCollection: transitModelCollection,
        lodgingCollection: lodgingModelCollection,
        tripMetadata: tripMetadata);

    final instance = TripDataModelImplementation._(
        tripMetadataModelImplementation,
        transitModelCollection,
        lodgingModelCollection,
        expenseModelCollection,
        itineraries,
        apiServicesRepository.currencyConverter);

    return instance;
  }

  @override
  final ModelCollectionModifier<TransitFacade> transitCollection;

  @override
  final ModelCollectionModifier<LodgingFacade> lodgingCollection;

  @override
  final ModelCollectionModifier<StandaloneExpense> expenseCollection;

  @override
  final ItineraryCollection itineraryCollection;

  ApiService<(Money, String), double?> currencyConverter;

  @override
  TripMetadataFacade get tripMetadata =>
      _tripMetadataModelImplementation.clone();
  final TripMetadataModelImplementation _tripMetadataModelImplementation;

  final StreamController<bool> _isFullyLoadedController =
      StreamController<bool>.broadcast(sync: true);

  @override
  Stream<bool> get isFullyLoaded => _isFullyLoadedController.stream;

  bool _isFullyLoadedValue = false;

  @override
  bool get isFullyLoadedValue => _isFullyLoadedValue;

  /// Subscriptions to each sub-collection's onLoaded stream so we can cancel
  /// them in dispose and avoid callbacks on a destroyed object.
  final List<StreamSubscription> _loadedSubscriptions = [];

  late final TripEntityDataUpdatePlanService _updatePlanService;

  @override
  Future<void> applyUpdatePlan(TripEntityUpdatePlan plan) async {
    // Execute the update plan
    await _updatePlanService.execute(plan);

    // Update local metadata copy
    if (plan is TripEntityUpdatePlan<TripMetadataFacade>) {
      _tripMetadataModelImplementation.copyWith(plan.newEntity);
    }
  }

  @override
  Future updateTripMetadata(TripMetadataFacade tripMetadata) async {
    // This method now only updates the local metadata copy
    // For full rebalancing, use applyUpdatePlan() with a TripMetadataUpdatePlan
    _tripMetadataModelImplementation.copyWith(tripMetadata);
  }

  @override
  Future dispose() async {
    for (final s in _loadedSubscriptions) {
      await s.cancel();
    }
    _loadedSubscriptions.clear();
    await transitCollection.dispose();
    await lodgingCollection.dispose();
    await expenseCollection.dispose();
    await itineraryCollection.dispose();
    await _isFullyLoadedController.close();
  }

  TripDataModelImplementation._(
      TripMetadataModelImplementation tripMetadata,
      this.transitCollection,
      this.lodgingCollection,
      this.expenseCollection,
      this.itineraryCollection,
      this.currencyConverter)
      : _tripMetadataModelImplementation = tripMetadata {
    _loadedSubscriptions
      ..add(transitCollection.onLoaded.listen(checkLoadedStatus))
      ..add(lodgingCollection.onLoaded.listen(checkLoadedStatus))
      ..add(expenseCollection.onLoaded.listen(checkLoadedStatus))
      ..add(itineraryCollection.onLoaded.listen(checkLoadedStatus));
    checkLoadedStatus(null);
    _updatePlanService = TripEntityDataUpdatePlanService(
      transitCollection: transitCollection,
      lodgingCollection: lodgingCollection,
      expenseCollection: expenseCollection,
      itineraryCollection: itineraryCollection,
    );
  }

  void checkLoadedStatus(_) {
    _isFullyLoadedValue = transitCollection.isLoaded &&
        lodgingCollection.isLoaded &&
        expenseCollection.isLoaded &&
        itineraryCollection.isLoaded;
    _isFullyLoadedController.add(_isFullyLoadedValue);
  }
}
