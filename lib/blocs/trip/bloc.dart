import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/helpers/itinerary_subscription_handler.dart';
import 'package:wandrr/blocs/trip/helpers/subscription_manager.dart';
import 'package:wandrr/blocs/trip/helpers/trip_entity_update_handler.dart';
import 'package:wandrr/blocs/trip/helpers/trip_metadata_subscription_handler.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/change_set.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
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
import 'package:wandrr/data/trip/services/budgeting/budgeting_service.dart';
import 'package:wandrr/data/trip/services/budgeting_service.dart';
import 'package:wandrr/data/trip/services/conflict_detection/trip_entity_update_plan.dart';

import 'events.dart';
import 'itinerary_plan_data_editor_config.dart';
import 'states.dart';

class TripManagementBloc
    extends Bloc<TripManagementEvent, TripManagementState> {
  TripRepositoryEventHandler? _tripRepository;
  final String _currentUserName;
  ApiServicesRepositoryModifier? _apiServicesRepository;

  BudgetingServiceModifier? _budgetingService;

  // Subscription Helper classes
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  static const TripEntityUpdateHandler _updateHandler =
      TripEntityUpdateHandler();
  TripMetadataSubscriptionHandler? _metadataSubscriptionHandler;
  ItinerarySubscriptionHandler? _itinerarySubscriptionHandler;

  // Operation timeout tracking — entity reference is the map key so each
  // in-flight operation is tracked individually (no string key collision risk).
  final Map<TripEntity, _PendingOperationTimer> _pendingTimers = {};
  static const Duration _kOperationTimeout = Duration(seconds: 5);

  TripDataModelEventHandler? get _activeTrip => _tripRepository?.activeTrip;

  // ---------------------------------------------------------------------------
  // Reusable teardown / init helpers
  // ---------------------------------------------------------------------------

  /// Lazy-initialises [_apiServicesRepository] and returns it.
  Future<ApiServicesRepositoryModifier> _getOrCreateApiServices() async {
    _apiServicesRepository ??= await ApiServicesRepositoryImpl.createInstance();
    return _apiServicesRepository!;
  }

  /// Disposes and nulls the budgeting service.
  Future<void> _disposeBudgetingService() async {
    await _budgetingService?.dispose();
    _budgetingService = null;
  }

  /// Cancels all active-trip subscriptions (entity collections + itinerary
  /// plan-data) and clears the itinerary subscription handler reference.
  Future<void> _teardownActiveTripSubscriptions() async {
    await _subscriptionManager.clearTripDataSubscriptions();
    await _subscriptionManager.clearItineraryPlanDataSubscriptions();
    _itinerarySubscriptionHandler = null;
  }

  // ---------------------------------------------------------------------------
  // Internal-event factory shorthands
  // ---------------------------------------------------------------------------

  _UpdateTripEntityInternalEvent<T> _internalCreated<T>(
          CollectionItemChangeMetadata<T> data) =>
      _UpdateTripEntityInternalEvent.created(data, isOperationSuccess: true);

  _UpdateTripEntityInternalEvent<T> _internalUpdated<T>(
          CollectionItemChangeMetadata<T> data) =>
      _UpdateTripEntityInternalEvent.updated(data, isOperationSuccess: true);

  _UpdateTripEntityInternalEvent<T> _internalDeleted<T>(
          CollectionItemChangeMetadata<T> data) =>
      _UpdateTripEntityInternalEvent.deleted(data, isOperationSuccess: true);

  TripManagementBloc(this._currentUserName)
      : super(const LoadingTripManagement()) {
    on<_OnStartup>(_onStartup);
    on<LoadTrip>(_onLoadTrip);
    on<SelectExpenseForDetails>(_onSelectExpenseForDetails);
    on<UpdateTripEntity<TransitFacade>>(_onUpdateTransit);
    on<UpdateTripEntity<LodgingFacade>>(_onUpdateLodging);
    on<GoToHome>(_onGoToHome);
    on<ApplyTripDataUpdatePlan>(_onApplyTripMetadataUpdatePlan);
    on<UpdateTripEntity<StandaloneExpense>>(_onUpdateExpense);
    on<UpdateTripEntity<TripMetadataFacade>>(_onUpdateTripMetadata);
    on<UpdateTripEntity<ItineraryPlanData>>(_onUpdateItineraryData);
    on<_UpdateTripEntityInternalEvent>(_onTripEntityUpdateInternal);
    on<_TimeoutOperationInternalEvent>(_onOperationTimeout);
    on<EditItineraryPlanData>(_onEditItineraryPlanData);
    on<CopyTrip>(_onCopyTrip);

    add(const _OnStartup());
  }

  @override
  Future<void> close() async {
    _cancelAllTimers();
    await _subscriptionManager.dispose();
    await _tripRepository?.dispose();
    await _apiServicesRepository?.dispose();
    await _disposeBudgetingService();
    await super.close();
  }

  FutureOr<void> _onStartup(
      _OnStartup event, Emitter<TripManagementState> emit) async {
    _tripRepository ??=
        await TripRepositoryImplementation.createInstance(_currentUserName);
    await _initializeMetadataSubscriptionHandler();
    final collection = _tripRepository!.tripMetadataCollection;
    if (!collection.isLoaded) {
      await collection.onLoaded.firstWhere((loaded) => loaded);
    }
    await _preloadMostVisited();
    emit(LoadedRepository(tripRepository: _tripRepository!));
  }

  FutureOr<void> _onGoToHome(
      GoToHome event, Emitter<TripManagementState> emit) async {
    await _tripRepository!.unloadActiveTrip();
    await _teardownActiveTripSubscriptions();
    _metadataSubscriptionHandler = null;
    await _disposeBudgetingService();
    emit(const NavigateToHome());
  }

  FutureOr<void> _onLoadTrip(
      LoadTrip event, Emitter<TripManagementState> emit) async {
    final tripMetadata = _tripRepository!.tripMetadataCollection.items
        .where((element) => element.id == event.tripMetadata.id)
        .firstOrNull;
    if (tripMetadata == null) {
      return;
    }

    await TripVisitTracker.recordVisit(tripMetadata.id!);
    emit(LoadingTrip(tripMetadata));

    final apiServices = await _getOrCreateApiServices();

    if (event.shouldActivateTrip) {
      if (_activeTrip != null) {
        await _teardownActiveTripSubscriptions();
      }
      final tripInstance = _tripRepository!
          .loadTrip(event.tripMetadata, apiServices, activateTrip: true);

      _subscribeToTripEntityCollections(tripInstance);
      await _createItineraryPlanDataSubscriptions(tripInstance);

      await _disposeBudgetingService();
      _budgetingService = BudgetingService.create(
        tripData: tripInstance,
        currencyConverter: apiServices.currencyConverter,
        supportedCurrencies: _tripRepository!.supportedCurrencies,
        currentUserName: _currentUserName,
      );

      emit(ActivatedTrip(
          apiServicesRepository: apiServices,
          budgetingService: _budgetingService!));
    } else {
      final tripInstance = _tripRepository!
          .loadTrip(event.tripMetadata, apiServices, activateTrip: false);
      emit(LoadedTripPreview(tripData: tripInstance));
    }
  }

  FutureOr<void> _onUpdateTransit(UpdateTripEntity<TransitFacade> event,
      Emitter<TripManagementState> emit) async {
    _schedulePendingOperationTimeout(event.tripEntity, event.dataState);
    await _updateHandler.updateTripEntityAndEmitState<TransitFacade>(
      tripEntity: event.tripEntity,
      requestedDataState: event.dataState,
      modelCollection: _activeTrip!.transitCollection,
      emit: emit,
    );
  }

  FutureOr<void> _onUpdateLodging(UpdateTripEntity<LodgingFacade> event,
      Emitter<TripManagementState> emit) async {
    _schedulePendingOperationTimeout(event.tripEntity, event.dataState);
    await _updateHandler.updateTripEntityAndEmitState<LodgingFacade>(
      tripEntity: event.tripEntity,
      requestedDataState: event.dataState,
      modelCollection: _activeTrip!.lodgingCollection,
      emit: emit,
    );
  }

  FutureOr<void> _onUpdateExpense(UpdateTripEntity<StandaloneExpense> event,
      Emitter<TripManagementState> emit) async {
    _schedulePendingOperationTimeout(event.tripEntity, event.dataState);
    await _updateHandler.updateTripEntityAndEmitState<StandaloneExpense>(
      tripEntity: event.tripEntity,
      requestedDataState: event.dataState,
      modelCollection: _activeTrip!.expenseCollection,
      emit: emit,
    );
  }

  void _onUpdateItineraryData(UpdateTripEntity<ItineraryPlanData> event,
      Emitter<TripManagementState> emit) {
    if (event.dataState == DataState.delete) {
      final emptyPlan = ItineraryPlanData.newEntry(
          tripId: event.tripEntity.tripId, day: event.tripEntity.day);
      _activeTrip!.itineraryCollection.updatePlanData(emptyPlan);
      return;
    }

    _activeTrip!.itineraryCollection.updatePlanData(event.tripEntity);
  }

  FutureOr<void> _onUpdateTripMetadata(
      UpdateTripEntity<TripMetadataFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.delete) {
      final isDeletingActiveTrip =
          _activeTrip?.tripMetadata.id == event.tripEntity.id;

      await _tripRepository!
          .deleteTrip(event.tripEntity, _apiServicesRepository!);

      if (isDeletingActiveTrip) {
        await _teardownActiveTripSubscriptions();
        await _disposeBudgetingService();
      }
      return;
    }
    _schedulePendingOperationTimeout(event.tripEntity, event.dataState);
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
    // Cancel any pending timeout timer for this operation since it succeeded.
    _cancelPendingTimerFor(
        event.updateData.collectionItemChange, event.dateState);
    switch (event.dateState) {
      case DataState.create:
        emit(UpdatedTripEntity<T>.created(
            tripEntityModificationData: event.updateData,
            isOperationSuccess: event.isOperationSuccess));
      case DataState.delete:
        emit(UpdatedTripEntity<T>.deleted(
            tripEntityModificationData: event.updateData,
            isOperationSuccess: event.isOperationSuccess));
      case DataState.update:
        emit(UpdatedTripEntity<T>.updated(
            tripEntityModificationData: event.updateData,
            isOperationSuccess: event.isOperationSuccess));
        // Handle external (Firestore-triggered) metadata currency changes.
        final change = event.updateData.collectionItemChange;
        if (change is Changeset<TripMetadataFacade>) {
          final oldCurrency = change.beforeUpdate.budget.currency;
          final newCurrency = change.afterUpdate.budget.currency;
          if (oldCurrency != newCurrency) {
            _budgetingService?.updateCurrency(newCurrency);
          }
          _budgetingService?.recalculateTotalExpenditure();
        }
      default:
        break;
    }
  }

  /// Handles tapping an expense-bearing entity from the BudgetingPage.
  ///
  /// Previously this was wired to [UpdateTripEntity<ExpenseBearingTripEntity>],
  /// but Dart's covariant generic subtyping caused the handler to also fire
  /// whenever a [TransitFacade] or [LodgingFacade] was selected from the
  /// timeline (because [UpdateTripEntity<TransitFacade>] IS-A
  /// [UpdateTripEntity<ExpenseBearingTripEntity>] at runtime).  The dedicated
  /// [SelectExpenseForDetails] event has no such subtyping ambiguity.
  FutureOr<void> _onSelectExpenseForDetails(
      SelectExpenseForDetails event, Emitter<TripManagementState> emit) {
    final entity = event.tripEntity;
    if (entity is SightFacade) {
      // Sights appear in the expense list too; tapping one should open the
      // itinerary editor, not the generic expense editor.
      final itineraryPlanData = _activeTrip!.itineraryCollection
          .getItineraryForDay(entity.day)
          .planData;
      add(EditItineraryPlanData(
          day: entity.day,
          planDataEditorConfig: UpdateItineraryPlanDataComponentConfig(
              planDataType: PlanDataType.sight,
              index: itineraryPlanData.sights.indexOf(entity))));
    } else {
      emit(SelectedExpenseBearingTripEntity(tripEntity: entity));
    }
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

  Future<void> _preloadMostVisited() async {
    final mostVisitedTrip = await TripVisitTracker.getMostVisitedTrip(
        _tripRepository!.tripMetadataCollection.items);
    if (mostVisitedTrip != null) {
      final api = await _getOrCreateApiServices();
      _tripRepository!.loadTrip(mostVisitedTrip, api, activateTrip: false);
    }
  }

  Future _initializeMetadataSubscriptionHandler() async {
    _metadataSubscriptionHandler = TripMetadataSubscriptionHandler(
      tripMetadataCollection: _tripRepository!.tripMetadataCollection,
      subscriptionManager: _subscriptionManager,
      getActiveTrip: () => _activeTrip,
      isBlocClosed: () => isClosed,
      addEvent: add,
      onDateChanged: () async => await _subscriptionManager
          .clearItineraryPlanDataSubscriptions()
          .then((_) => _createItineraryPlanDataSubscriptions(_activeTrip!)),
      createUpdateEvent: _internalUpdated,
      createAddEvent: _internalCreated,
      createDeleteEvent: _internalDeleted,
    );
    _metadataSubscriptionHandler!.createSubscriptions();
  }

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

  void _subscribeToTripEntityCollection<T extends TripEntity<Enum>>(
    ModelCollectionFacade<T> collection,
  ) {
    _subscriptionManager.subscribeToCollectionUpdates<T>(
      modelCollection: collection,
      onAdded: (data) {
        if (!isClosed) {
          add(_internalCreated<T>(data));
        }
      },
      onDeleted: (data) {
        if (!isClosed) {
          add(_internalDeleted<T>(data));
        }
      },
      onUpdated: (data) {
        if (!isClosed) {
          add(_internalUpdated(data));
        }
      },
    );
  }

  Future<void> _createItineraryPlanDataSubscriptions(
      TripDataModelEventHandler tripData) async {
    _itinerarySubscriptionHandler = ItinerarySubscriptionHandler(
      itineraryCollection: tripData.itineraryCollection,
      subscriptionManager: _subscriptionManager,
      onUpdated: (data) {
        if (!isClosed) {
          add(_internalUpdated(data));
        }
      },
    );
    await _itinerarySubscriptionHandler!.createSubscriptions();
  }

  Future<void> _onApplyTripMetadataUpdatePlan(
      ApplyTripDataUpdatePlan event, Emitter<TripManagementState> emit) async {
    await _activeTrip?.applyUpdatePlan(event.updatePlan);

    // Drive budgeting updates that the service no longer handles internally.
    final plan = event.updatePlan;
    if (_budgetingService != null) {
      var currencyChanged = false;
      var needsRecalculation = plan.hasConflicts;

      if (plan is TripEntityUpdatePlan<TripMetadataFacade>) {
        final oldMeta = plan.oldEntity;
        final newMeta = plan.newEntity;

        currencyChanged = oldMeta.budget.currency != newMeta.budget.currency;
        final datesChanged = oldMeta.startDate != newMeta.startDate ||
            oldMeta.endDate != newMeta.endDate;

        needsRecalculation =
            needsRecalculation || currencyChanged || datesChanged;

        if (currencyChanged) {
          _budgetingService?.updateCurrency(newMeta.budget.currency);
        }

        // Re-subscribe plan-data streams so new itinerary days (added by the
        // date change) are included in the bloc's update pipeline, and refresh
        // the budgeting service's itinerary subscriptions too.
        if (datesChanged && _activeTrip != null) {
          await _subscriptionManager.clearItineraryPlanDataSubscriptions();
          await _createItineraryPlanDataSubscriptions(_activeTrip!);
          _budgetingService?.refreshItinerarySubscriptions();
        }
      }

      if (needsRecalculation) {
        await _budgetingService?.recalculateTotalExpenditure();
      }
    }
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
    await _tripRepository!.copyTrip(
        event.sourceTripMetadata, newTripMetadata, _apiServicesRepository!);
  }

  // ---------------------------------------------------------------------------
  // Operation timeout helpers
  // ---------------------------------------------------------------------------

  /// Schedules a 5-second timeout for a CRUD operation on [entity].
  /// The entity reference itself is the map key, so concurrent operations on
  /// different entity instances are tracked independently and accurately.
  void _schedulePendingOperationTimeout(TripEntity entity, DataState state) {
    if (state != DataState.create &&
        state != DataState.delete &&
        state != DataState.update) {
      return;
    }
    _pendingTimers[entity]?.timer.cancel();
    _pendingTimers[entity] = _PendingOperationTimer(
      timer: Timer(_kOperationTimeout, () {
        _pendingTimers.remove(entity);
        if (!isClosed) {
          add(_TimeoutOperationInternalEvent(entity, state));
        }
      }),
      state: state,
    );
  }

  /// Cancels the pending timeout timer for the operation that just echoed back
  /// from Firestore, confirming it completed successfully.
  void _cancelPendingTimerFor(dynamic change, DataState state) {
    TripEntity? incomingEntity;

    if (change is Changeset) {
      final after = change.afterUpdate;
      if (after is TripEntity) incomingEntity = after;
    } else if (change is TripEntity) {
      incomingEntity = change;
    }

    if (incomingEntity == null) return;

    TripEntity? keyToRemove;
    for (final entry in _pendingTimers.entries) {
      if (entry.value.state != state) continue;
      if (entry.key.runtimeType != incomingEntity.runtimeType) continue;

      if (state == DataState.create) {
        // For creates the pending entity has id == null while the echoed-back
        // entity carries a fresh Firestore id.  Match by non-id key properties.
        if (_entitiesMatchForCreate(entry.key, incomingEntity)) {
          keyToRemove = entry.key;
          break;
        }
      } else if (entry.key.id == incomingEntity.id) {
        keyToRemove = entry.key;
        break;
      }
    }

    if (keyToRemove != null) {
      _pendingTimers.remove(keyToRemove)?.timer.cancel();
    }
  }

  /// Returns `true` when [pending] (the locally-created entity, `id == null`)
  /// and [incoming] (the Firestore-echoed entity, `id != null`) represent the
  /// same just-created record, compared by their non-id key properties.
  ///
  /// Each entity type uses the minimal set of fields that together uniquely
  /// identify a "just submitted" record:
  ///   - [TransitFacade]       : tripId + transitOption + depart/arrive datetimes
  ///   - [LodgingFacade]       : tripId + checkin/checkout datetimes
  ///   - [StandaloneExpense]   : tripId + title + category + total amount
  ///   - [TripMetadataFacade]  : name + startDate + endDate
  bool _entitiesMatchForCreate(TripEntity pending, TripEntity incoming) {
    if (pending.runtimeType != incoming.runtimeType) return false;

    if (pending is TransitFacade && incoming is TransitFacade) {
      return pending.tripId == incoming.tripId &&
          pending.transitOption == incoming.transitOption &&
          pending.departureDateTime == incoming.departureDateTime &&
          pending.arrivalDateTime == incoming.arrivalDateTime;
    }

    if (pending is LodgingFacade && incoming is LodgingFacade) {
      return pending.tripId == incoming.tripId &&
          pending.checkinDateTime == incoming.checkinDateTime &&
          pending.checkoutDateTime == incoming.checkoutDateTime;
    }

    if (pending is StandaloneExpense && incoming is StandaloneExpense) {
      return pending.tripId == incoming.tripId &&
          pending.title == incoming.title &&
          pending.category == incoming.category &&
          pending.expense.totalExpense == incoming.expense.totalExpense;
    }

    if (pending is TripMetadataFacade && incoming is TripMetadataFacade) {
      return pending.name == incoming.name &&
          pending.startDate == incoming.startDate &&
          pending.endDate == incoming.endDate;
    }

    // Fallback for unknown entity types: same runtime type is enough.
    return true;
  }

  void _cancelAllTimers() {
    for (final entry in _pendingTimers.values) {
      entry.timer.cancel();
    }
    _pendingTimers.clear();
  }

  void _onOperationTimeout(
      _TimeoutOperationInternalEvent event, Emitter<TripManagementState> emit) {
    final entity = event.entity;
    final state = event.state;
    final data = CollectionItemChangeMetadata<dynamic>(entity,
        isFromExplicitAction: true);

    if (entity is TransitFacade) {
      _emitTimeoutState<TransitFacade>(state, data, emit);
    } else if (entity is LodgingFacade) {
      _emitTimeoutState<LodgingFacade>(state, data, emit);
    } else if (entity is StandaloneExpense) {
      _emitTimeoutState<StandaloneExpense>(state, data, emit);
    } else if (entity is TripMetadataFacade) {
      _emitTimeoutState<TripMetadataFacade>(state, data, emit);
    }
  }

  void _emitTimeoutState<T>(
      DataState state,
      CollectionItemChangeMetadata<dynamic> data,
      Emitter<TripManagementState> emit) {
    switch (state) {
      case DataState.create:
        emit(UpdatedTripEntity<T>.created(
            tripEntityModificationData: data, isOperationSuccess: false));
        break;
      case DataState.delete:
        emit(UpdatedTripEntity<T>.deleted(
            tripEntityModificationData: data, isOperationSuccess: false));
        break;
      case DataState.update:
        emit(UpdatedTripEntity<T>.updated(
            tripEntityModificationData: data, isOperationSuccess: false));
        break;
      default:
        break;
    }
  }
}

class _TimeoutOperationInternalEvent extends TripManagementEvent {
  final TripEntity entity;
  final DataState state;

  const _TimeoutOperationInternalEvent(this.entity, this.state);
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

class _PendingOperationTimer {
  final Timer timer;
  final DataState state;

  _PendingOperationTimer({required this.timer, required this.state});
}
