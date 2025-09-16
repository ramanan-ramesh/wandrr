import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/api_services/repository.dart';
import 'package:wandrr/data/trip/implementations/trip_repository.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/app_localizations.dart';

import 'events.dart';
import 'states.dart';

class TripManagementBloc
    extends Bloc<TripManagementEvent, TripManagementState> {
  TripRepositoryEventHandler? _tripRepository;
  final _tripStreamSubscriptions = <StreamSubscription>[];
  final _tripRepositorySubscriptions = <StreamSubscription>[];
  final AppLocalizations appLocalizations;
  final String currentUserName;
  ApiServicesRepositoryModifier? _apiServicesRepository;

  @override
  Future<void> close() async {
    for (final subscription in _tripRepositorySubscriptions) {
      await subscription.cancel();
    }
    await super.close();
  }

  TripManagementBloc(this.currentUserName, this.appLocalizations)
      : super(LoadingTripManagement()) {
    on<_OnStartup>(_onStartup);
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
    on<NavigateToSection>((event, emit) {
      emit(ProcessSectionNavigation(
          section: event.section, dateTime: event.dateTime));
    });

    add(_OnStartup());
  }

  FutureOr<void> _onStartup(
      _OnStartup event, Emitter<TripManagementState> emit) async {
    if (_tripRepository == null) {
      _tripRepository = await TripRepositoryImplementation.createInstance(
          userName: currentUserName, appLocalizations: appLocalizations);

      var tripMetadataUpdatedSubscription = _tripRepository!
          .tripMetadataModelCollection.onDocumentUpdated
          .listen((eventData) {
        var collectionModificationData = CollectionItemChangeMetadata(
            eventData.modifiedCollectionItem.afterUpdate.facade,
            isFromExplicitAction: false);
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent.updated(collectionModificationData,
              isOperationSuccess: true));
        }
      });
      var tripMetadataAddedSubscription = _tripRepository!
          .tripMetadataModelCollection.onDocumentAdded
          .listen((eventData) {
        if (!eventData.isFromExplicitAction) {
          var collectionModificationData = CollectionItemChangeMetadata(
              eventData.modifiedCollectionItem.facade,
              isFromExplicitAction: false);
          if (!isClosed) {
            add(_UpdateTripEntityInternalEvent.created(
                collectionModificationData,
                isOperationSuccess: true));
          }
        }
      });
      var tripMetadataDeletedSubscription = _tripRepository!
          .tripMetadataModelCollection.onDocumentDeleted
          .listen((eventData) {
        if (!eventData.isFromExplicitAction) {
          var collectionModificationData = CollectionItemChangeMetadata(
              eventData.modifiedCollectionItem.facade,
              isFromExplicitAction: false);
          if (!isClosed) {
            add(_UpdateTripEntityInternalEvent.deleted(
                collectionModificationData,
                isOperationSuccess: true));
          }
        }
      });
      _tripRepositorySubscriptions.add(tripMetadataUpdatedSubscription);
      _tripRepositorySubscriptions.add(tripMetadataDeletedSubscription);
      _tripRepositorySubscriptions.add(tripMetadataAddedSubscription);
    }
    emit(LoadedRepository(tripRepository: _tripRepository!));
  }

  FutureOr<void> _onGoToHome(
      GoToHome event, Emitter<TripManagementState> emit) async {
    await _tripRepository!.unloadActiveTrip();
    await _apiServicesRepository?.dispose();
    _apiServicesRepository = null;
    await _clearTripSubscriptions();

    emit(NavigateToHome());
  }

  FutureOr<void> _onLoadTrip(
      LoadTrip event, Emitter<TripManagementState> emit) async {
    var tripMetadata = _tripRepository!.tripMetadatas
        .where((element) => element.id == event.tripMetadata.id)
        .firstOrNull;
    if (tripMetadata != null) {
      emit(LoadingTrip(tripMetadata));
      if (_tripRepository!.activeTrip != null) {
        await _clearTripSubscriptions();
      }
      _apiServicesRepository = await ApiServicesRepositoryImpl.createInstance();
      await _tripRepository!
          .loadTrip(event.tripMetadata, _apiServicesRepository!);
      var activeTrip = _tripRepository!.activeTrip!;
      _subscribeToCollectionUpdatesForTripEntity<TransitFacade>(
          activeTrip.transitsModelCollection, emit);
      _subscribeToCollectionUpdatesForTripEntity<LodgingFacade>(
          activeTrip.lodgingModelCollection, emit);
      _subscribeToCollectionUpdatesForTripEntity<ExpenseFacade>(
          activeTrip.expenseModelCollection, emit);
      _subscribeToCollectionUpdatesForTripEntity<PlanDataFacade>(
          activeTrip.planDataModelCollection, emit);
      emit(ActivatedTrip(apiServicesRepository: _apiServicesRepository!));
    }
  }

  FutureOr<void> _onUpdateTransit(UpdateTripEntity<TransitFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var activeTrip = _tripRepository!.activeTrip!;
      var transit = TransitFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          transitOption: TransitOption.publicTransport,
          allTripContributors: activeTrip.tripMetadata.contributors,
          defaultCurrency: activeTrip.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<TransitFacade>.createdNewUiEntry(
          tripEntity: transit, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<TransitFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository!.activeTrip!.transitsModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onUpdateLodging(UpdateTripEntity<LodgingFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var activeTrip = _tripRepository!.activeTrip!;
      var lodgingModelFacade = LodgingFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          allTripContributors: activeTrip.tripMetadata.contributors,
          defaultCurrency: activeTrip.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<LodgingFacade>.createdNewUiEntry(
          tripEntity: lodgingModelFacade, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<LodgingFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository!.activeTrip!.lodgingModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onUpdateExpense(UpdateTripEntity<ExpenseFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event is UpdateLinkedExpense) {
      return;
    }
    if (event.dataState == DataState.newUiEntry) {
      var activeTrip = _tripRepository!.activeTrip!;
      var newExpense = ExpenseFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          allTripContributors: activeTrip.tripMetadata.contributors,
          defaultCurrency: activeTrip.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<ExpenseFacade>.createdNewUiEntry(
          tripEntity: newExpense, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<ExpenseFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository!.activeTrip!.expenseModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onUpdatePlanData(UpdateTripEntity<PlanDataFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var activeTrip = _tripRepository!.activeTrip!;
      var planDataModelFacade = PlanDataFacade.newUiEntry(
          id: null, tripId: activeTrip.tripMetadata.id!);
      emit(UpdatedTripEntity<PlanDataFacade>.createdNewUiEntry(
          tripEntity: planDataModelFacade, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<PlanDataFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository!.activeTrip!.planDataModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onItineraryDataUpdated(
      UpdateItineraryPlanData event, Emitter<TripManagementState> emit) async {
    var activeTrip = _tripRepository!.activeTrip!;
    var itinerary =
        activeTrip.itineraryCollection.getItineraryForDay(event.day);
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
        _tripRepository!.tripMetadataModelCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onTransitExpenseUpdated(
      UpdateLinkedExpense<TransitFacade> event,
      Emitter<TripManagementState> emit) async {
    switch (event.dataState) {
      case DataState.select:
        {
          emit(UpdatedLinkedExpense.selected(
              link: event.link, expense: event.tripEntity!));
          break;
        }
      case DataState.update:
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
      case DataState.select:
        {
          emit(UpdatedLinkedExpense.selected(
              link: event.link, expense: event.tripEntity!));
          break;
        }
      case DataState.update:
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
      ModelCollectionModifier<E> modelCollection,
      String? tripEntityId,
      Emitter<TripManagementState> emit) async {
    switch (requestedDataState) {
      case DataState.newUiEntry:
        {
          emit(UpdatedTripEntity<E>.createdNewUiEntry(
              tripEntity: tripEntity, isOperationSuccess: true));
        }
      case DataState.create:
        {
          if (tripEntityId == null) {
            var addedEntity = await modelCollection.tryAdd(tripEntity);
            if (addedEntity != null) {
              emit(UpdatedTripEntity<E>.created(
                  tripEntityModificationData: CollectionItemChangeMetadata(
                      addedEntity.facade,
                      isFromExplicitAction: true),
                  isOperationSuccess: true));
            } else {
              emit(UpdatedTripEntity<E>.created(
                  tripEntityModificationData: CollectionItemChangeMetadata(
                      tripEntity,
                      isFromExplicitAction: true),
                  isOperationSuccess: false));
            }
          }
          break;
        }
      case DataState.delete:
        {
          if (tripEntityId != null && tripEntityId.isNotEmpty) {
            if (modelCollection.collectionItems.any(
                (element) => element.documentReference.id == tripEntityId)) {
              var didDelete = await modelCollection.tryDeleteItem(tripEntity);
              emit(UpdatedTripEntity<E>.deleted(
                  tripEntityModificationData: CollectionItemChangeMetadata(
                      tripEntity,
                      isFromExplicitAction: true),
                  isOperationSuccess: didDelete));
            }
          } else {
            emit(UpdatedTripEntity<E>.deleted(
                tripEntityModificationData: CollectionItemChangeMetadata(
                    tripEntity,
                    isFromExplicitAction: true),
                isOperationSuccess: true));
          }
          break;
        }
      case DataState.update:
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
                  tripEntityModificationData: CollectionItemChangeMetadata(
                      tripEntity,
                      isFromExplicitAction: true),
                  isOperationSuccess: didUpdate));
            }
          }
          break;
        }
      case DataState.select:
        {
          var originalTripEntity = modelCollection.collectionItems
              .where((e) => e.id == tripEntityId)
              .firstOrNull
              ?.facade;
          emit(UpdatedTripEntity<E>.selected(
              tripEntity: originalTripEntity ?? tripEntity));
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
      if (!eventData.isFromExplicitAction) {
        var collectionModificationData = CollectionItemChangeMetadata(
            eventData.modifiedCollectionItem.facade,
            isFromExplicitAction: false);
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent<T>.created(
              collectionModificationData,
              isOperationSuccess: true));
        }
      }
    });
    var tripEntityDeletedSubscription =
        modelCollection.onDocumentDeleted.listen((eventData) {
      if (!eventData.isFromExplicitAction) {
        var collectionModificationData = CollectionItemChangeMetadata(
            eventData.modifiedCollectionItem.facade,
            isFromExplicitAction: false);
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent<T>.deleted(
              collectionModificationData,
              isOperationSuccess: true));
        }
      }
    });
    var tripEntityUpdatedSubscription =
        modelCollection.onDocumentUpdated.listen((eventData) {
      if (!eventData.isFromExplicitAction) {
        var collectionModificationData = CollectionItemChangeMetadata(
            eventData.modifiedCollectionItem.afterUpdate.facade,
            isFromExplicitAction: false);
        if (!isClosed) {
          add(_UpdateTripEntityInternalEvent<T>.updated(
              collectionModificationData,
              isOperationSuccess: true));
        }
      }
    });
    _tripStreamSubscriptions.add(tripEntityAddedSubscription);
    _tripStreamSubscriptions.add(tripEntityDeletedSubscription);
    _tripStreamSubscriptions.add(tripEntityUpdatedSubscription);
  }

  Future<void> _clearTripSubscriptions() async {
    for (final subscription in _tripStreamSubscriptions) {
      await subscription.cancel();
    }
    _tripStreamSubscriptions.clear();
  }

  FutureOr<void> _onTripEntityUpdateInternal<T extends TripEntity>(
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
}

class _UpdateTripEntityInternalEvent<T extends TripEntity>
    extends TripManagementEvent {
  CollectionItemChangeMetadata<T> updateData;
  bool isOperationSuccess;
  DataState dateState;

  _UpdateTripEntityInternalEvent.updated(this.updateData,
      {required this.isOperationSuccess})
      : dateState = DataState.update;

  _UpdateTripEntityInternalEvent.created(this.updateData,
      {required this.isOperationSuccess})
      : dateState = DataState.create;

  _UpdateTripEntityInternalEvent.deleted(this.updateData,
      {required this.isOperationSuccess})
      : dateState = DataState.delete;
}

class _OnStartup extends TripManagementEvent {}
