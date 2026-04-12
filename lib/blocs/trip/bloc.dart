import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/helpers/itinerary_subscription_handler.dart';
import 'package:wandrr/blocs/trip/helpers/subscription_manager.dart';
import 'package:wandrr/blocs/trip/helpers/trip_entity_factory.dart';
import 'package:wandrr/blocs/trip/helpers/trip_entity_update_handler.dart';
import 'package:wandrr/blocs/trip/helpers/trip_metadata_subscription_handler.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/api_services/repository.dart';
import 'package:wandrr/data/trip/implementations/trip_repository.dart';
import 'package:wandrr/data/trip/implementations/trip_visit_tracker.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';

import 'events.dart';
import 'itinerary_plan_data_editor_config.dart';
import 'states.dart';

class TripManagementBloc
    extends Bloc<TripManagementEvent, TripManagementState> {
  TripRepositoryEventHandler? _tripRepository;
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final String _currentUserName;
  ApiServicesRepositoryModifier? _apiServicesRepository;

  // Helper classes
  static const TripEntityUpdateHandler _updateHandler =
      TripEntityUpdateHandler();
  TripMetadataSubscriptionHandler? _metadataSubscriptionHandler;
  ItinerarySubscriptionHandler? _itinerarySubscriptionHandler;

  TripDataModelEventHandler? get _activeTrip => _tripRepository?.activeTrip;

  TripManagementBloc(this._currentUserName)
      : super(const LoadingTripManagement()) {
    on<_OnStartup>(_onStartup);
    on<LoadTrip>(_onLoadTrip);
    on<SelectExpenseBearingTripEntity>(_onSelectExpenseBearingTripEntity);
    on<UpdateTripEntity<TransitFacade>>(_onUpdateTransit);
    on<UpdateTripEntity<LodgingFacade>>(_onUpdateLodging);
    on<GoToHome>(_onGoToHome);
    on<ApplyTripDataUpdatePlan>(_onApplyTripMetadataUpdatePlan);
    on<UpdateTripEntity<StandaloneExpense>>(_onUpdateExpense);
    on<UpdateTripEntity<TripMetadataFacade>>(_onUpdateTripMetadata);
    on<UpdateTripEntity<ItineraryPlanData>>(_onUpdateItineraryData);
    on<_UpdateTripEntityInternalEvent>(_onTripEntityUpdateInternal);
    on<EditItineraryPlanData>(_onEditItineraryPlanData);
    on<CopyTrip>(_onCopyTrip);

    add(const _OnStartup());
  }

  @override
  Future<void> close() async {
    await _subscriptionManager.dispose();
    await _tripRepository?.dispose();
    await _apiServicesRepository?.dispose();
    await super.close();
  }

  FutureOr<void> _onStartup(
      _OnStartup event, Emitter<TripManagementState> emit) async {
    if (_tripRepository == null) {
      _tripRepository = await TripRepositoryImplementation.createInstance(
          userName: _currentUserName);
      await _initializeMetadataSubscriptionHandler();
      if (_tripRepository!.tripMetadataCollection.isLoaded) {
        unawaited(_preloadMostVisited());
      } else {
        await _tripRepository!.tripMetadataCollection.onLoaded
            .firstWhere((loaded) => loaded);
        unawaited(_preloadMostVisited());
      }
    }
    emit(LoadedRepository(tripRepository: _tripRepository!));
  }

  FutureOr<void> _onGoToHome(
      GoToHome event, Emitter<TripManagementState> emit) async {
    await _tripRepository!.unloadActiveTrip();
    await _subscriptionManager.clearTripDataSubscriptions();
    _metadataSubscriptionHandler = null;
    _itinerarySubscriptionHandler = null;

    emit(const NavigateToHome());
  }

  FutureOr<void> _onLoadTrip(
      LoadTrip event, Emitter<TripManagementState> emit) async {
    var tripMetadata = _tripRepository!.tripMetadataCollection.collectionItems
        .where((element) => element.id == event.tripMetadata.id)
        .firstOrNull;
    if (tripMetadata != null) {
      await TripVisitTracker.recordVisit(tripMetadata.id!);
      emit(LoadingTrip(tripMetadata));
      if (event.shouldActivateTrip) {
        if (_activeTrip != null) {
          await _subscriptionManager.clearTripDataSubscriptions();
          await _subscriptionManager.clearItineraryPlanDataSubscriptions();
        }
        _apiServicesRepository ??=
            await ApiServicesRepositoryImpl.createInstance();
        final tripInstance = _tripRepository!.loadTrip(
            event.tripMetadata, _apiServicesRepository!,
            activateTrip: true);

        _subscribeToTripEntityCollections(tripInstance);
        await _createItineraryPlanDataSubscriptions(tripInstance);

        emit(ActivatedTrip(apiServicesRepository: _apiServicesRepository!));
      } else {
        _apiServicesRepository ??=
            await ApiServicesRepositoryImpl.createInstance();
        final tripInstance = _tripRepository!.loadTrip(
            event.tripMetadata, _apiServicesRepository!,
            activateTrip: true);
        LoadedTripPreview(tripData: tripInstance);
      }
    }
  }

  FutureOr<void> _onUpdateTransit(UpdateTripEntity<TransitFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var transit = TripEntityFactory.createTransit(
        tripMetadata: _activeTrip!.tripMetadata,
        existing: event.tripEntity,
      );
      emit(UpdatedTripEntity<TransitFacade>.createdNewUiEntry(
          tripEntity: transit, isOperationSuccess: true));
      return;
    }
    await _updateHandler.updateTripEntityAndEmitState<TransitFacade>(
      tripEntity: event.tripEntity,
      requestedDataState: event.dataState,
      modelCollection: _activeTrip!.transitCollection,
      emit: emit,
    );
  }

  FutureOr<void> _onUpdateLodging(UpdateTripEntity<LodgingFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var lodging = TripEntityFactory.createLodging(
        tripMetadata: _activeTrip!.tripMetadata,
        existing: event.tripEntity,
      );
      emit(UpdatedTripEntity<LodgingFacade>.createdNewUiEntry(
          tripEntity: lodging, isOperationSuccess: true));
      return;
    }
    await _updateHandler.updateTripEntityAndEmitState<LodgingFacade>(
      tripEntity: event.tripEntity,
      requestedDataState: event.dataState,
      modelCollection: _activeTrip!.lodgingCollection,
      emit: emit,
    );
  }

  FutureOr<void> _onUpdateExpense(UpdateTripEntity<StandaloneExpense> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var expense = TripEntityFactory.createExpense(
        tripMetadata: _activeTrip!.tripMetadata,
        existing: event.tripEntity,
      );
      emit(UpdatedTripEntity<StandaloneExpense>.createdNewUiEntry(
          tripEntity: expense, isOperationSuccess: true));
      return;
    }
    await _updateHandler.updateTripEntityAndEmitState<StandaloneExpense>(
      tripEntity: event.tripEntity,
      requestedDataState: event.dataState,
      modelCollection: _activeTrip!.expenseCollection,
      emit: emit,
    );
  }

  FutureOr<void> _onUpdateItineraryData(
      UpdateTripEntity<ItineraryPlanData> event,
      Emitter<TripManagementState> emit) async {
    var itineraryDay = event.tripEntity.day;
    var itinerary =
        _activeTrip!.itineraryCollection.getItineraryForDay(itineraryDay);
    var itineraryPlanDataBeforeUpdate = itinerary.planData.clone();
    var didUpdate = await itinerary.updatePlanData(event.tripEntity);
    emit(UpdatedTripEntity.updated(
        tripEntityModificationData: CollectionItemChangeMetadata(
            CollectionItemChangeSet<ItineraryPlanData>(
                itineraryPlanDataBeforeUpdate, event.tripEntity),
            isFromExplicitAction: true),
        isOperationSuccess: didUpdate));
  }

  FutureOr<void> _onUpdateTripMetadata(
      UpdateTripEntity<TripMetadataFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.delete) {
      await _tripRepository!
          .deleteTrip(event.tripEntity, _apiServicesRepository!);
      return;
    }
    await _updateHandler.updateTripEntityAndEmitState<TripMetadataFacade>(
      tripEntity: event.tripEntity,
      requestedDataState: event.dataState,
      modelCollection: _tripRepository!.tripMetadataCollection,
      emit: emit,
    );
  }

  FutureOr<void> _onTripEntityUpdateInternal<T>(
      _UpdateTripEntityInternalEvent<T> event,
      Emitter<TripManagementState> emit) {
    switch (event.dateState) {
      case DataState.create:
        {
          emit(UpdatedTripEntity<T>.created(
              tripEntityModificationData: event.updateData,
              isOperationSuccess: event.isOperationSuccess));
          break;
        }
      case DataState.delete:
        {
          emit(UpdatedTripEntity<T>.deleted(
              tripEntityModificationData: event.updateData,
              isOperationSuccess: event.isOperationSuccess));
          break;
        }
      case DataState.update:
        {
          var updateState = UpdatedTripEntity<T>.updated(
              tripEntityModificationData: event.updateData,
              isOperationSuccess: event.isOperationSuccess);
          emit(updateState);
          break;
        }
      default:
        break;
    }
  }

  Future<void> _onSelectExpenseBearingTripEntity(
      SelectExpenseBearingTripEntity event,
      Emitter<TripManagementState> emit) async {
    if (event.tripEntity is SightFacade) {
      var selectedSight = event.tripEntity as SightFacade;
      var itineraryPlanData = _activeTrip!.itineraryCollection
          .getItineraryForDay(selectedSight.day)
          .planData;
      emit(SelectedItineraryPlanData(
          planData: itineraryPlanData,
          planDataEditorConfig: UpdateItineraryPlanDataComponentConfig(
              planDataType: PlanDataType.sight,
              index: itineraryPlanData.sights.indexOf(selectedSight))));
      return;
    }
    emit(SelectedExpenseBearingTripEntity(tripEntity: event.tripEntity));
  }

  FutureOr<void> _onEditItineraryPlanData(
      EditItineraryPlanData event, Emitter<TripManagementState> emit) {
    final itinerary =
        _activeTrip!.itineraryCollection.getItineraryForDay(event.day);
    final planData = itinerary.planData;
    emit(SelectedItineraryPlanData(
      planData: planData,
      planDataEditorConfig: event.planDataEditorConfig,
    ));
  }

  // Preload most visited trip in the background once metadata is available
  Future<void> _preloadMostVisited() async {
    final mostVisited = await TripVisitTracker.getMostVisitedTrip(
        _tripRepository!.tripMetadataCollection.collectionItems);
    if (mostVisited != null) {
      _apiServicesRepository ??=
          await ApiServicesRepositoryImpl.createInstance();
      // Load in background (Fire-and-forget, TripRepository caches it)
      _tripRepository!
          .loadTrip(mostVisited, _apiServicesRepository!, activateTrip: false);
    }
  }

  /// Initializes metadata subscription handler
  Future _initializeMetadataSubscriptionHandler() async {
    _metadataSubscriptionHandler = TripMetadataSubscriptionHandler(
      tripMetadataCollection: _tripRepository!.tripMetadataCollection,
      subscriptionManager: _subscriptionManager,
      activeTrip: _activeTrip,
      isBlocClosed: () => isClosed,
      addEvent: add,
      onDateChanged: () async => await _subscriptionManager
          .clearItineraryPlanDataSubscriptions()
          .then((_) => _createItineraryPlanDataSubscriptions(_activeTrip!)),
      createUpdateEvent: (metadata) => _UpdateTripEntityInternalEvent.updated(
        metadata,
        isOperationSuccess: true,
      ),
      createAddEvent: (metadata) => _UpdateTripEntityInternalEvent.created(
        metadata,
        isOperationSuccess: true,
      ),
      createDeleteEvent: (metadata) => _UpdateTripEntityInternalEvent.deleted(
        metadata,
        isOperationSuccess: true,
      ),
    );
    _metadataSubscriptionHandler!.createSubscriptions();
  }

  /// Subscribes to all trip entity collections
  void _subscribeToTripEntityCollections(TripDataModelEventHandler tripData) {
    _subscribeToTripEntityCollection<TransitFacade>(
      tripData.transitCollection,
    );
    _subscribeToTripEntityCollection<LodgingFacade>(
      tripData.lodgingCollection,
    );
    _subscribeToTripEntityCollection<StandaloneExpense>(
      tripData.expenseCollection,
    );
  }

  /// Subscribes to a specific trip entity collection
  void _subscribeToTripEntityCollection<T extends TripEntity>(
    ModelCollectionFacade<T> collection,
  ) {
    _subscriptionManager.subscribeToCollectionUpdates<T>(
      modelCollection: collection,
      onAdded: (metadata) {
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent<T>.created(
            metadata,
            isOperationSuccess: true,
          ));
        }
      },
      onDeleted: (metadata) {
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent<T>.deleted(
            metadata,
            isOperationSuccess: true,
          ));
        }
      },
      onUpdated: (metadata) {
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent.updated(
            metadata,
            isOperationSuccess: true,
          ));
        }
      },
    );
  }

  /// Creates subscriptions for itinerary plan data
  Future<void> _createItineraryPlanDataSubscriptions(
      TripDataModelEventHandler tripData) async {
    _itinerarySubscriptionHandler = ItinerarySubscriptionHandler(
      itineraryCollection: tripData.itineraryCollection,
      subscriptionManager: _subscriptionManager,
      isBlocClosed: () => isClosed,
      onUpdated: (metadata) {
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent.updated(
            metadata,
            isOperationSuccess: true,
          ));
        }
      },
    );
    await _itinerarySubscriptionHandler!.createSubscriptions();
  }

  Future<void> _onApplyTripMetadataUpdatePlan(
      ApplyTripDataUpdatePlan event, Emitter<TripManagementState> emit) async {
    await _activeTrip?.applyUpdatePlan(event.updatePlan);
  }

  FutureOr<void> _onCopyTrip(
      CopyTrip event, Emitter<TripManagementState> emit) async {
    final originalStartDate = event.sourceTripMetadata.startDate!;
    final originalEndDate = event.sourceTripMetadata.endDate!;
    final dateOffset = event.newStartDate.difference(originalStartDate);
    final shifted = DateTime(
            originalEndDate.year, originalEndDate.month, originalEndDate.day)
        .add(dateOffset);
    final newEndDate = DateTime(shifted.year, shifted.month, shifted.day);
    final newTripMetadata = TripMetadataFacade(
        id: null,
        startDate: event.newStartDate,
        endDate: newEndDate,
        name: event.newName,
        contributors: event.contributors,
        thumbnailTag: event.thumbnailTag,
        budget: event.budget);
    final copiedTripMetadata = await _tripRepository!.copyTrip(
        event.sourceTripMetadata, newTripMetadata, _apiServicesRepository!);

    emit(UpdatedTripEntity<TripMetadataFacade>.created(
      tripEntityModificationData: CollectionItemChangeMetadata(
          copiedTripMetadata,
          isFromExplicitAction: true),
      isOperationSuccess: true,
    ));
  }
}

class _UpdateTripEntityInternalEvent<T> extends TripManagementEvent {
  final CollectionItemChangeMetadata<T> updateData;
  final bool isOperationSuccess;
  final DataState dateState;

  const _UpdateTripEntityInternalEvent.updated(this.updateData,
      {required this.isOperationSuccess})
      : dateState = DataState.update;

  const _UpdateTripEntityInternalEvent.created(this.updateData,
      {required this.isOperationSuccess})
      : dateState = DataState.create;

  const _UpdateTripEntityInternalEvent.deleted(this.updateData,
      {required this.isOperationSuccess})
      : dateState = DataState.delete;
}

class _OnStartup extends TripManagementEvent {
  const _OnStartup();
}
