import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_data/models/collection_change_metadata.dart';
import 'package:wandrr/app_data/models/data_states.dart';
import 'package:wandrr/app_data/models/model_collection_facade.dart';
import 'package:wandrr/trip_data/models/expense.dart';
import 'package:wandrr/trip_data/models/lodging.dart';
import 'package:wandrr/trip_data/models/plan_data.dart';
import 'package:wandrr/trip_data/models/transit.dart';
import 'package:wandrr/trip_data/models/trip_entity.dart';
import 'package:wandrr/trip_data/models/trip_metadata.dart';
import 'package:wandrr/trip_data/models/trip_repository.dart';

import 'events.dart';
import 'states.dart';

class _UpdateTripEntityInternalEvent<T extends TripEntity>
    extends TripManagementEvent {
  CollectionChangeMetadata<T> updateData;
  bool isOperationSuccess;
  DataState dateState;

  _UpdateTripEntityInternalEvent.updated(
      this.updateData, this.isOperationSuccess)
      : dateState = DataState.Update;

  _UpdateTripEntityInternalEvent.created(
      this.updateData, this.isOperationSuccess)
      : dateState = DataState.Create;

  _UpdateTripEntityInternalEvent.deleted(
      this.updateData, this.isOperationSuccess)
      : dateState = DataState.Delete;
}

class TripManagementBloc
    extends Bloc<TripManagementEvent, TripManagementState> {
  final TripRepositoryEventHandler _tripRepository;
  final _tripStreamSubscriptions = <StreamSubscription>[];
  final _tripRepositorySubscriptions = <StreamSubscription>[];
  final String currentUserName;

  TripManagementBloc(this._tripRepository, this.currentUserName)
      : super(NavigateToHome()) {
    on<LoadTrip>(_onLoadTrip);
    on<UpdateTripEntity<TransitFacade>>(_onUpdateTransit);
    on<UpdateTripEntity<LodgingFacade>>(_onUpdateLodging);
    on<GoToHome>(_onGoToHome);
    on<UpdateLinkedExpense<TransitFacade>>(_onTransitExpenseUpdated);
    on<UpdateLinkedExpense<LodgingFacade>>(_onLodgingExpenseUpdated);
    on<UpdateTripEntity<ExpenseFacade>>(_onUpdateExpense);
    on<UpdateTripEntity<TripMetadataFacade>>(_onUpdateTripMetadata);
    on<UpdateTripEntity<PlanDataFacade>>(_onUpdatePlanData);
    on<UpdateItineraryPlanData>(_onItineraryDataUpdated);
    on<_UpdateTripEntityInternalEvent>(_onTripEntityUpdateInternal);

    var tripMetadataUpdatedSubscription = _tripRepository
        .tripMetadataModelCollection.onDocumentUpdated
        .listen((eventData) {
      if (!eventData.isFromEvent) {
        var collectionModificationData = CollectionChangeMetadata(
            eventData.modifiedCollectionItem.afterUpdate.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent.updated(
              collectionModificationData, true));
        }
      }
    });
    var tripMetadataAddedSubscription = _tripRepository
        .tripMetadataModelCollection.onDocumentAdded
        .listen((eventData) {
      if (!eventData.isFromEvent) {
        var collectionModificationData = CollectionChangeMetadata(
            eventData.modifiedCollectionItem.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent.created(
              collectionModificationData, true));
        }
      }
    });
    var tripMetadataDeletedSubscription = _tripRepository
        .tripMetadataModelCollection.onDocumentDeleted
        .listen((eventData) {
      if (!eventData.isFromEvent) {
        var collectionModificationData = CollectionChangeMetadata(
            eventData.modifiedCollectionItem.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent.deleted(
              collectionModificationData, true));
        }
      }
    });
    _tripRepositorySubscriptions.add(tripMetadataUpdatedSubscription);
    _tripRepositorySubscriptions.add(tripMetadataDeletedSubscription);
    _tripRepositorySubscriptions.add(tripMetadataAddedSubscription);
  }

  FutureOr<void> _onGoToHome(
      GoToHome event, Emitter<TripManagementState> emit) async {
    await _tripRepository.loadAndActivateTrip(null);
    for (var subscription in _tripStreamSubscriptions) {
      await subscription.cancel();
    }
    _tripStreamSubscriptions.clear();
    for (var subscription in _tripRepositorySubscriptions) {
      await subscription.cancel();
    }
    _tripRepositorySubscriptions.clear();

    emit(NavigateToHome());
  }

  FutureOr<void> _onLoadTrip(
      LoadTrip event, Emitter<TripManagementState> emit) async {
    var tripMetadata = _tripRepository.tripMetadatas
        .where((element) => element.id == event.tripMetadata.id)
        .firstOrNull;
    if (tripMetadata != null) {
      await _tripRepository.loadAndActivateTrip(event.tripMetadata);
      var activeTrip = _tripRepository.activeTripEventHandler!;
      _subscribeToCollectionUpdatesForTripEntity<TransitFacade>(
          activeTrip.transitsModelCollection, emit);
      _subscribeToCollectionUpdatesForTripEntity<LodgingFacade>(
          activeTrip.lodgingModelCollection, emit);
      _subscribeToCollectionUpdatesForTripEntity<ExpenseFacade>(
          activeTrip.expenseModelCollection, emit);
      _subscribeToCollectionUpdatesForTripEntity<PlanDataFacade>(
          activeTrip.planDataModelCollection, emit);
      emit(ActivatedTrip());
    }
  }

  FutureOr<void> _onUpdateTransit(UpdateTripEntity<TransitFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.NewUiEntry) {
      var activeTrip = _tripRepository.activeTripEventHandler!;
      var transit = TransitFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          transitOption: TransitOption.PublicTransport,
          allTripContributors: activeTrip.tripMetadata.contributors,
          currentUserName: currentUserName,
          defaultCurrency: activeTrip.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<TransitFacade>.createdNewUiEntry(
          tripEntity: transit, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<TransitFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository.activeTripEventHandler!.transitsModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onUpdateLodging(UpdateTripEntity<LodgingFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.NewUiEntry) {
      var activeTrip = _tripRepository.activeTripEventHandler!;
      var lodgingModelFacade = LodgingFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          allTripContributors: activeTrip.tripMetadata.contributors,
          currentUserName: currentUserName,
          defaultCurrency: activeTrip.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<LodgingFacade>.createdNewUiEntry(
          tripEntity: lodgingModelFacade, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<LodgingFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository.activeTripEventHandler!.lodgingModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onUpdateExpense(UpdateTripEntity<ExpenseFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event is UpdateLinkedExpense) {
      return;
    }
    if (event.dataState == DataState.NewUiEntry) {
      var activeTrip = _tripRepository.activeTripEventHandler!;
      var newExpense = ExpenseFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          allTripContributors: activeTrip.tripMetadata.contributors,
          currentUserName: currentUserName,
          defaultCurrency: activeTrip.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<ExpenseFacade>.createdNewUiEntry(
          tripEntity: newExpense, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<ExpenseFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository.activeTripEventHandler!.expenseModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onUpdatePlanData(UpdateTripEntity<PlanDataFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.NewUiEntry) {
      var activeTrip = _tripRepository.activeTripEventHandler!;
      var planDataModelFacade = PlanDataFacade.newUiEntry(
          id: null, tripId: activeTrip.tripMetadata.id!);
      emit(UpdatedTripEntity<PlanDataFacade>.createdNewUiEntry(
          tripEntity: planDataModelFacade, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<PlanDataFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository.activeTripEventHandler!.planDataModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onItineraryDataUpdated(
      UpdateItineraryPlanData event, Emitter<TripManagementState> emit) async {
    var activeTrip = _tripRepository.activeTripEventHandler!;
    var itinerary =
        activeTrip.itineraryModelCollection.getItineraryForDay(event.day);
    var didUpdate =
        await itinerary.planDataEventHandler.tryUpdate(event.planData);
    emit(ItineraryDataUpdated(day: event.day, isOperationSuccess: didUpdate));
  }

  FutureOr<void> _onUpdateTripMetadata(
      UpdateTripEntity<TripMetadataFacade> event,
      Emitter<TripManagementState> emit) async {
    await _tryUpdateTripEntityAndEmitState<TripMetadataFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository.tripMetadataModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onTransitExpenseUpdated(
      UpdateLinkedExpense<TransitFacade> event,
      Emitter<TripManagementState> emit) async {
    switch (event.dataState) {
      case DataState.Select:
        {
          emit(UpdatedLinkedExpense.selected(
              link: event.link,
              expense: event.tripEntity!,
              isOperationSuccess: true));
          break;
        }
      case DataState.Update:
        {
          event.link.expense = event.tripEntity!;
          add(UpdateTripEntity<TransitFacade>.update(tripEntity: event.link));
          break;
        }
      default:
        {
          break;
        }
    }
  }

  FutureOr<void> _onLodgingExpenseUpdated(
      UpdateLinkedExpense<LodgingFacade> event,
      Emitter<TripManagementState> emit) async {
    switch (event.dataState) {
      case DataState.Select:
        {
          emit(UpdatedLinkedExpense.selected(
              link: event.link,
              expense: event.tripEntity!,
              isOperationSuccess: true));
          break;
        }
      case DataState.Update:
        {
          event.link.expense = event.tripEntity!;
          add(UpdateTripEntity<LodgingFacade>.update(tripEntity: event.link));
          break;
        }
      default:
        {
          break;
        }
    }
  }

  FutureOr _tryUpdateTripEntityAndEmitState<E>(
      E tripEntity,
      DataState requestedDataState,
      ModelCollectionFacade<E> modelCollection,
      String? tripEntityId,
      Emitter<TripManagementState> emit) async {
    switch (requestedDataState) {
      case DataState.NewUiEntry:
        {
          emit(UpdatedTripEntity<E>.createdNewUiEntry(
              tripEntity: tripEntity, isOperationSuccess: true));
        }
      case DataState.Create:
        {
          if (tripEntityId == null) {
            var addedEntity = await modelCollection.tryAdd(tripEntity);
            if (addedEntity != null) {
              emit(UpdatedTripEntity<E>.created(
                  tripEntityModificationData:
                      CollectionChangeMetadata(addedEntity.facade, true),
                  isOperationSuccess: true));
            } else {
              emit(UpdatedTripEntity<E>.created(
                  tripEntityModificationData:
                      CollectionChangeMetadata(tripEntity, true),
                  isOperationSuccess: false));
            }
          }
          break;
        }
      case DataState.Delete:
        {
          if (tripEntityId != null && tripEntityId.isNotEmpty) {
            if (modelCollection.collectionItems.any(
                (element) => element.documentReference.id == tripEntityId)) {
              var didDelete = await modelCollection.tryDeleteItem(tripEntity);
              emit(UpdatedTripEntity<E>.deleted(
                  tripEntityModificationData:
                      CollectionChangeMetadata(tripEntity, true),
                  isOperationSuccess: didDelete));
            }
          } else {
            emit(UpdatedTripEntity<E>.deleted(
                tripEntityModificationData:
                    CollectionChangeMetadata(tripEntity, true),
                isOperationSuccess: true));
          }
          break;
        }
      case DataState.Update:
        {
          if (tripEntityId != null && tripEntityId.isNotEmpty) {
            var collectionItem = modelCollection.collectionItems
                .where((element) => element.id == tripEntityId)
                .firstOrNull;
            if (collectionItem != null) {
              var didUpdate = false;
              await modelCollection.runUpdateTransaction(() async {
                didUpdate = await collectionItem.tryUpdate(tripEntity);
              });
              emit(UpdatedTripEntity<E>.updated(
                  tripEntityModificationData:
                      CollectionChangeMetadata(tripEntity, true),
                  isOperationSuccess: didUpdate));
            }
          }
          break;
        }
      case DataState.Select:
        {
          emit(UpdatedTripEntity<E>.selected(tripEntity: tripEntity));
        }
      default:
        {
          break;
        }
    }
  }

  void _subscribeToCollectionUpdatesForTripEntity<T extends TripEntity>(
      ModelCollectionFacade<T> modelCollection,
      Emitter<TripManagementState> emitter) {
    var tripEntityAddedSubscription =
        modelCollection.onDocumentAdded.listen((eventData) {
      if (!eventData.isFromEvent) {
        var collectionModificationData = CollectionChangeMetadata(
            eventData.modifiedCollectionItem.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent<T>.created(
              collectionModificationData, true));
        }
      }
    });
    var tripEntityDeletedSubscription =
        modelCollection.onDocumentDeleted.listen((eventData) {
      if (!eventData.isFromEvent) {
        var collectionModificationData = CollectionChangeMetadata(
            eventData.modifiedCollectionItem.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent<T>.deleted(
              collectionModificationData, true));
        }
      }
    });
    var tripEntityUpdatedSubscription =
        modelCollection.onDocumentUpdated.listen((eventData) {
      if (!eventData.isFromEvent) {
        var collectionModificationData = CollectionChangeMetadata(
            eventData.modifiedCollectionItem.afterUpdate.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent<T>.updated(
              collectionModificationData, true));
        }
      }
    });
    _tripStreamSubscriptions.add(tripEntityAddedSubscription);
    _tripStreamSubscriptions.add(tripEntityDeletedSubscription);
    _tripStreamSubscriptions.add(tripEntityUpdatedSubscription);
  }

  FutureOr<void> _onTripEntityUpdateInternal<T extends TripEntity>(
      _UpdateTripEntityInternalEvent<T> event,
      Emitter<TripManagementState> emit) {
    switch (event.dateState) {
      case DataState.Create:
        {
          emit(UpdatedTripEntity<T>.created(
              tripEntityModificationData: event.updateData,
              isOperationSuccess: event.isOperationSuccess));
          break;
        }
      case DataState.Delete:
        {
          emit(UpdatedTripEntity<T>.deleted(
              tripEntityModificationData: event.updateData,
              isOperationSuccess: event.isOperationSuccess));
          break;
        }
      case DataState.Update:
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
}
