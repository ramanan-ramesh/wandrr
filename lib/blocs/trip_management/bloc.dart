import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/contracts/data_states.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/lodging.dart';
import 'package:wandrr/contracts/model_collection.dart';
import 'package:wandrr/contracts/plan_data.dart';
import 'package:wandrr/contracts/transit.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/contracts/trip_repository.dart';

import 'events.dart';
import 'states.dart';

class _UpdateTripEntityInternal<T extends TripEntity>
    extends TripManagementEvent {
  CollectionModificationData<T> updateData;
  bool isOperationSuccess;
  DataState dateState;

  _UpdateTripEntityInternal.updated(this.updateData, this.isOperationSuccess)
      : dateState = DataState.Update;

  _UpdateTripEntityInternal.created(this.updateData, this.isOperationSuccess)
      : dateState = DataState.Create;

  _UpdateTripEntityInternal.deleted(this.updateData, this.isOperationSuccess)
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
    on<UpdateTripEntity<TransitModelFacade>>(_onUpdateTransit);
    on<UpdateTripEntity<LodgingModelFacade>>(_onUpdateLodging);
    on<GoToHome>(_onGoToHome);
    on<UpdateLinkedExpense<TransitModelFacade>>(_onTransitExpenseUpdated);
    on<UpdateLinkedExpense<LodgingModelFacade>>(_onLodgingExpenseUpdated);
    on<UpdateTripEntity<ExpenseModelFacade>>(_onUpdateExpense);
    on<UpdateTripEntity<TripMetadataModelFacade>>(_onUpdateTripMetadata);
    on<UpdateTripEntity<PlanDataModelFacade>>(_onUpdatePlanData);
    on<UpdateItineraryPlanData>(_onItineraryDataUpdated);
    on<_UpdateTripEntityInternal>(_onTripEntityUpdateInternal);

    var tripMetadataUpdatedSubscription = _tripRepository
        .tripMetadataModelCollection.onDocumentUpdated
        .listen((eventData) {
      if (!eventData.isFromEvent) {
        var collectionModificationData = CollectionModificationData(
            eventData.modifiedCollectionItem.afterUpdate.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternal.updated(
              collectionModificationData, true));
        }
      }
    });
    var tripMetadataAddedSubscription = _tripRepository
        .tripMetadataModelCollection.onDocumentAdded
        .listen((eventData) {
      if (!eventData.isFromEvent) {
        var collectionModificationData = CollectionModificationData(
            eventData.modifiedCollectionItem.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternal.created(
              collectionModificationData, true));
        }
      }
    });
    var tripMetadataDeletedSubscription = _tripRepository
        .tripMetadataModelCollection.onDocumentDeleted
        .listen((eventData) {
      if (!eventData.isFromEvent) {
        var collectionModificationData = CollectionModificationData(
            eventData.modifiedCollectionItem.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternal.deleted(
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
      _subscribeToCollectionUpdatesForTripEntity<TransitModelFacade>(
          activeTrip.transitsModelCollection, emit);
      _subscribeToCollectionUpdatesForTripEntity<LodgingModelFacade>(
          activeTrip.lodgingModelCollection, emit);
      _subscribeToCollectionUpdatesForTripEntity<ExpenseModelFacade>(
          activeTrip.expenseModelCollection, emit);
      _subscribeToCollectionUpdatesForTripEntity<PlanDataModelFacade>(
          activeTrip.planDataModelCollection, emit);
      emit(ActivatedTrip());
    }
  }

  FutureOr<void> _onUpdateTransit(UpdateTripEntity<TransitModelFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.NewUiEntry) {
      var activeTrip = _tripRepository.activeTripEventHandler!;
      var transit = TransitModelFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          transitOption: TransitOption.PublicTransport,
          allTripContributors: activeTrip.tripMetadata.contributors,
          currentUserName: currentUserName,
          defaultCurrency: activeTrip.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<TransitModelFacade>.createdNewUiEntry(
          tripEntity: transit, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<TransitModelFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository.activeTripEventHandler!.transitsModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onUpdateLodging(UpdateTripEntity<LodgingModelFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.NewUiEntry) {
      var activeTrip = _tripRepository.activeTripEventHandler!;
      var lodgingModelFacade = LodgingModelFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          allTripContributors: activeTrip.tripMetadata.contributors,
          currentUserName: currentUserName,
          defaultCurrency: activeTrip.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<LodgingModelFacade>.createdNewUiEntry(
          tripEntity: lodgingModelFacade, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<LodgingModelFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository.activeTripEventHandler!.lodgingModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onUpdateExpense(UpdateTripEntity<ExpenseModelFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event is UpdateLinkedExpense) {
      return;
    }
    if (event.dataState == DataState.NewUiEntry) {
      var activeTrip = _tripRepository.activeTripEventHandler!;
      var newExpense = ExpenseModelFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          allTripContributors: activeTrip.tripMetadata.contributors,
          currentUserName: currentUserName,
          defaultCurrency: activeTrip.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<ExpenseModelFacade>.createdNewUiEntry(
          tripEntity: newExpense, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<ExpenseModelFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository.activeTripEventHandler!.expenseModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onUpdatePlanData(UpdateTripEntity<PlanDataModelFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.NewUiEntry) {
      var activeTrip = _tripRepository.activeTripEventHandler!;
      var planDataModelFacade = PlanDataModelFacade.newUiEntry(
          id: null, tripId: activeTrip.tripMetadata.id!);
      emit(UpdatedTripEntity<PlanDataModelFacade>.createdNewUiEntry(
          tripEntity: planDataModelFacade, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<PlanDataModelFacade>(
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
      UpdateTripEntity<TripMetadataModelFacade> event,
      Emitter<TripManagementState> emit) async {
    await _tryUpdateTripEntityAndEmitState<TripMetadataModelFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository.tripMetadataModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onTransitExpenseUpdated(
      UpdateLinkedExpense<TransitModelFacade> event,
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
          add(UpdateTripEntity<TransitModelFacade>.update(
              tripEntity: event.link));
          break;
        }
      default:
        {
          break;
        }
    }
  }

  FutureOr<void> _onLodgingExpenseUpdated(
      UpdateLinkedExpense<LodgingModelFacade> event,
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
          add(UpdateTripEntity<LodgingModelFacade>.update(
              tripEntity: event.link));
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
                      CollectionModificationData(addedEntity.facade, true),
                  isOperationSuccess: true));
            } else {
              emit(UpdatedTripEntity<E>.created(
                  tripEntityModificationData:
                      CollectionModificationData(tripEntity, true),
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
                      CollectionModificationData(tripEntity, true),
                  isOperationSuccess: didDelete));
            }
          } else {
            emit(UpdatedTripEntity<E>.deleted(
                tripEntityModificationData:
                    CollectionModificationData(tripEntity, true),
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
                      CollectionModificationData(tripEntity, true),
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
        var collectionModificationData = CollectionModificationData(
            eventData.modifiedCollectionItem.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternal<T>.created(
              collectionModificationData, true));
        }
      }
    });
    var tripEntityDeletedSubscription =
        modelCollection.onDocumentDeleted.listen((eventData) {
      if (!eventData.isFromEvent) {
        var collectionModificationData = CollectionModificationData(
            eventData.modifiedCollectionItem.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternal<T>.deleted(
              collectionModificationData, true));
        }
      }
    });
    var tripEntityUpdatedSubscription =
        modelCollection.onDocumentUpdated.listen((eventData) {
      if (!eventData.isFromEvent) {
        var collectionModificationData = CollectionModificationData(
            eventData.modifiedCollectionItem.afterUpdate.clone(), false);
        if (!isClosed) {
          add(_UpdateTripEntityInternal<T>.updated(
              collectionModificationData, true));
        }
      }
    });
    _tripStreamSubscriptions.add(tripEntityAddedSubscription);
    _tripStreamSubscriptions.add(tripEntityDeletedSubscription);
    _tripStreamSubscriptions.add(tripEntityUpdatedSubscription);
  }

  FutureOr<void> _onTripEntityUpdateInternal<T extends TripEntity>(
      _UpdateTripEntityInternal<T> event, Emitter<TripManagementState> emit) {
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
