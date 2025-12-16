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
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/app_localizations.dart';

import 'events.dart';
import 'states.dart';

class TripManagementBloc
    extends Bloc<TripManagementEvent, TripManagementState> {
  TripRepositoryEventHandler? _tripRepository;
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final AppLocalizations appLocalizations;
  final String currentUserName;
  ApiServicesRepositoryModifier? _apiServicesRepository;

  // Helper classes
  late final TripEntityUpdateHandler _updateHandler;
  TripEntityFactory? _entityFactory;
  TripMetadataSubscriptionHandler? _metadataSubscriptionHandler;
  ItinerarySubscriptionHandler? _itinerarySubscriptionHandler;

  TripDataModelEventHandler? get _activeTrip => _tripRepository?.activeTrip;

  TripManagementBloc(this.currentUserName, this.appLocalizations)
      : super(LoadingTripManagement()) {
    _updateHandler = TripEntityUpdateHandler();

    on<_OnStartup>(_onStartup);
    on<LoadTrip>(_onLoadTrip);
    on<SelectExpenseLinkedTripEntity>(_onSelectExpenseLinkedTripEntity);
    on<UpdateTripEntity<TransitFacade>>(_onUpdateTransit);
    on<UpdateTripEntity<LodgingFacade>>(_onUpdateLodging);
    on<GoToHome>(_onGoToHome);
    on<UpdateTripEntity<ExpenseFacade>>(_onUpdateExpense);
    on<UpdateTripEntity<TripMetadataFacade>>(_onUpdateTripMetadata);
    on<UpdateTripEntity<ItineraryPlanData>>(_onUpdateItineraryData);
    on<_UpdateTripEntityInternalEvent>(_onTripEntityUpdateInternal);
    on<EditItineraryPlanData>(_onEditItineraryPlanData);

    add(_OnStartup());
  }

  @override
  Future<void> close() async {
    await _subscriptionManager.dispose();
    await super.close();
  }

  FutureOr<void> _onStartup(
      _OnStartup event, Emitter<TripManagementState> emit) async {
    if (_tripRepository == null) {
      _tripRepository = await TripRepositoryImplementation.createInstance(
          userName: currentUserName, appLocalizations: appLocalizations);
      _initializeMetadataSubscriptionHandler();
      _metadataSubscriptionHandler!.createSubscriptions();
    }
    emit(LoadedRepository(tripRepository: _tripRepository!));
  }

  FutureOr<void> _onGoToHome(
      GoToHome event, Emitter<TripManagementState> emit) async {
    await _tripRepository!.unloadActiveTrip();
    await _apiServicesRepository?.dispose();
    _apiServicesRepository = null;
    await _subscriptionManager.clearTripSubscriptions();
    _entityFactory = null;
    _itinerarySubscriptionHandler = null;

    emit(NavigateToHome());
  }

  FutureOr<void> _onLoadTrip(
      LoadTrip event, Emitter<TripManagementState> emit) async {
    var tripMetadata = _tripRepository!.tripMetadataCollection.collectionItems
        .where((element) => element.id == event.tripMetadata.id)
        .firstOrNull;
    if (tripMetadata != null) {
      emit(LoadingTrip(tripMetadata));
      if (_activeTrip != null) {
        await _subscriptionManager.clearTripSubscriptions();
      }
      _apiServicesRepository = await ApiServicesRepositoryImpl.createInstance();
      await _tripRepository!
          .loadTrip(event.tripMetadata, _apiServicesRepository!);

      _entityFactory = TripEntityFactory(_activeTrip!);
      _subscribeToTripEntityCollections();
      await _createItineraryPlanDataSubscriptions();

      emit(ActivatedTrip(apiServicesRepository: _apiServicesRepository!));
    }
  }

  FutureOr<void> _onUpdateTransit(UpdateTripEntity<TransitFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var transit = _entityFactory!.createTransit(existing: event.tripEntity);
      emit(UpdatedTripEntity<TransitFacade>.createdNewUiEntry(
          tripEntity: transit, isOperationSuccess: true));
      return;
    }
    await _updateHandler.updateTripEntityAndEmitState<TransitFacade>(
      tripEntity: event.tripEntity!,
      requestedDataState: event.dataState,
      modelCollection: _activeTrip!.transitCollection,
      emit: emit,
    );
  }

  FutureOr<void> _onUpdateLodging(UpdateTripEntity<LodgingFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var lodging = _entityFactory!.createLodging(existing: event.tripEntity);
      emit(UpdatedTripEntity<LodgingFacade>.createdNewUiEntry(
          tripEntity: lodging, isOperationSuccess: true));
      return;
    }
    await _updateHandler.updateTripEntityAndEmitState<LodgingFacade>(
      tripEntity: event.tripEntity!,
      requestedDataState: event.dataState,
      modelCollection: _activeTrip!.lodgingCollection,
      emit: emit,
    );
  }

  FutureOr<void> _onUpdateExpense(UpdateTripEntity<ExpenseFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var expense = _entityFactory!.createExpense(existing: event.tripEntity);
      emit(UpdatedTripEntity<ExpenseFacade>.createdNewUiEntry(
          tripEntity: expense, isOperationSuccess: true));
      return;
    }
    await _updateHandler.updateTripEntityAndEmitState<ExpenseFacade>(
      tripEntity: event.tripEntity!,
      requestedDataState: event.dataState,
      modelCollection: _activeTrip!.expenseCollection,
      emit: emit,
    );
  }

  FutureOr<void> _onUpdateItineraryData(
      UpdateTripEntity<ItineraryPlanData> event,
      Emitter<TripManagementState> emit) async {
    if (event.tripEntity == null) {
      return;
    }
    var itineraryDay = event.tripEntity!.day;
    var itinerary =
        _activeTrip!.itineraryCollection.getItineraryForDay(itineraryDay);
    var itineraryPlanDataBeforeUpdate = itinerary.planData.clone();
    var didUpdate = await itinerary.updatePlanData(event.tripEntity!);
    emit(UpdatedTripEntity.updated(
        tripEntityModificationData: CollectionItemChangeMetadata(
            CollectionItemChangeSet<ItineraryPlanData>(
                itineraryPlanDataBeforeUpdate, event.tripEntity!),
            isFromExplicitAction: true),
        isOperationSuccess: didUpdate));
  }

  FutureOr<void> _onUpdateTripMetadata(
      UpdateTripEntity<TripMetadataFacade> event,
      Emitter<TripManagementState> emit) async {
    await _updateHandler.updateTripEntityAndEmitState<TripMetadataFacade>(
      tripEntity: event.tripEntity!,
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

  FutureOr<void> _onSelectExpenseLinkedTripEntity(
      SelectExpenseLinkedTripEntity event, Emitter<TripManagementState> emit) {
    emit(SelectedExpenseLinkedTripEntity(tripEntity: event.tripEntity!));
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

  /// Initializes metadata subscription handler
  void _initializeMetadataSubscriptionHandler() {
    _metadataSubscriptionHandler = TripMetadataSubscriptionHandler(
      tripRepository: _tripRepository!,
      subscriptionManager: _subscriptionManager,
      activeTrip: _activeTrip,
      isBlocClosed: () => isClosed,
      addEvent: add,
      clearItinerarySubscriptions: () async =>
          await _subscriptionManager.clearItineraryPlanDataSubscriptions(),
      createItinerarySubscriptions: _createItineraryPlanDataSubscriptions,
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
  }

  /// Subscribes to all trip entity collections
  void _subscribeToTripEntityCollections() {
    _subscribeToTripEntityCollection<TransitFacade>(
      _activeTrip!.transitCollection,
    );
    _subscribeToTripEntityCollection<LodgingFacade>(
      _activeTrip!.lodgingCollection,
    );
    _subscribeToTripEntityCollection<ExpenseFacade>(
      _activeTrip!.expenseCollection,
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
  Future<void> _createItineraryPlanDataSubscriptions() async {
    _itinerarySubscriptionHandler = ItinerarySubscriptionHandler(
      activeTrip: _activeTrip!,
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
