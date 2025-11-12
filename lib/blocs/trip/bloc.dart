import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/store/models/collection_item_change_set.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/api_services/repository.dart';
import 'package:wandrr/data/trip/implementations/trip_repository.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
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
  final _tripStreamSubscriptions = <StreamSubscription>[];
  final _tripRepositorySubscriptions = <StreamSubscription>[];
  final _itineraryPlanDataSubscriptions = <StreamSubscription>[];
  final AppLocalizations appLocalizations;
  final String currentUserName;
  ApiServicesRepositoryModifier? _apiServicesRepository;

  TripDataModelEventHandler? get _activeTrip => _tripRepository?.activeTrip;

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

  FutureOr<void> _onStartup(
      _OnStartup event, Emitter<TripManagementState> emit) async {
    if (_tripRepository == null) {
      _tripRepository = await TripRepositoryImplementation.createInstance(
          userName: currentUserName, appLocalizations: appLocalizations);
      _createTripMetadataCollectionSubscriptions();
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
    var tripMetadata = _tripRepository!.tripMetadataCollection.collectionItems
        .where((element) => element.id == event.tripMetadata.id)
        .firstOrNull;
    if (tripMetadata != null) {
      emit(LoadingTrip(tripMetadata));
      if (_activeTrip != null) {
        await _clearTripSubscriptions();
      }
      _apiServicesRepository = await ApiServicesRepositoryImpl.createInstance();
      await _tripRepository!
          .loadTrip(event.tripMetadata, _apiServicesRepository!);
      _subscribeToCollectionUpdatesForTripEntity<TransitFacade>(
          _activeTrip!.transitCollection, emit);
      _subscribeToCollectionUpdatesForTripEntity<LodgingFacade>(
          _activeTrip!.lodgingCollection, emit);
      _subscribeToCollectionUpdatesForTripEntity<ExpenseFacade>(
          _activeTrip!.expenseCollection, emit);
      await _createItineraryPlanDataSubscriptions();
      emit(ActivatedTrip(apiServicesRepository: _apiServicesRepository!));
    }
  }

  FutureOr<void> _onUpdateTransit(UpdateTripEntity<TransitFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var transit = event.tripEntity ??
          TransitFacade.newUiEntry(
              tripId: _activeTrip!.tripMetadata.id!,
              transitOption: TransitOption.publicTransport,
              allTripContributors: _activeTrip!.tripMetadata.contributors,
              defaultCurrency: _activeTrip!.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<TransitFacade>.createdNewUiEntry(
          tripEntity: transit, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<TransitFacade>(
        event.tripEntity!,
        event.dataState,
        _activeTrip!.transitCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onUpdateLodging(UpdateTripEntity<LodgingFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var lodgingModelFacade = event.tripEntity ??
          LodgingFacade.newUiEntry(
              tripId: _activeTrip!.tripMetadata.id!,
              allTripContributors: _activeTrip!.tripMetadata.contributors,
              defaultCurrency: _activeTrip!.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<LodgingFacade>.createdNewUiEntry(
          tripEntity: lodgingModelFacade, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<LodgingFacade>(
        event.tripEntity!,
        event.dataState,
        _activeTrip!.lodgingCollection,
        event.tripEntity!.id,
        emit);
  }

  FutureOr<void> _onUpdateExpense(UpdateTripEntity<ExpenseFacade> event,
      Emitter<TripManagementState> emit) async {
    if (event.dataState == DataState.newUiEntry) {
      var newExpense = event.tripEntity ??
          ExpenseFacade.newUiEntry(
              tripId: _activeTrip!.tripMetadata.id!,
              allTripContributors: _activeTrip!.tripMetadata.contributors,
              defaultCurrency: _activeTrip!.tripMetadata.budget.currency);
      emit(UpdatedTripEntity<ExpenseFacade>.createdNewUiEntry(
          tripEntity: newExpense, isOperationSuccess: true));
      return;
    }
    await _tryUpdateTripEntityAndEmitState<ExpenseFacade>(
        event.tripEntity!,
        event.dataState,
        _activeTrip!.expenseCollection,
        event.tripEntity!.id,
        emit);
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
    var didUpdate = await itinerary.updatePlanData(event.tripEntity!);
    emit(UpdatedTripEntity<ItineraryPlanData>.updated(
        tripEntityModificationData: CollectionItemChangeMetadata(
            event.tripEntity!,
            isFromExplicitAction: true),
        isOperationSuccess: didUpdate));
  }

  FutureOr<void> _onUpdateTripMetadata(
      UpdateTripEntity<TripMetadataFacade> event,
      Emitter<TripManagementState> emit) async {
    await _tryUpdateTripEntityAndEmitState<TripMetadataFacade>(
        event.tripEntity!,
        event.dataState,
        _tripRepository!.tripMetadataCollection,
        event.tripEntity!.id,
        emit);
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

  void _createTripMetadataCollectionSubscriptions() {
    var tripMetadataUpdatedSubscription = _tripRepository!
        .tripMetadataCollection.onDocumentUpdated
        .listen((eventData) {
      var updatedTripMetadata = eventData.modifiedCollectionItem.afterUpdate;
      if (_activeTrip != null &&
          _activeTrip!.tripMetadata.id != updatedTripMetadata.id) {
        return;
      }
      if (!eventData.isFromExplicitAction && !isClosed) {
        var hasStartDateChanged = !eventData
            .modifiedCollectionItem.beforeUpdate.startDate!
            .isOnSameDayAs(updatedTripMetadata.startDate!);
        var hasEndDateChanged = !eventData
            .modifiedCollectionItem.beforeUpdate.endDate!
            .isOnSameDayAs(updatedTripMetadata.endDate!);
        if (hasStartDateChanged || hasEndDateChanged) {
          _clearItineraryPlanDataSubscriptions()
              .then((value) => _createItineraryPlanDataSubscriptions());
        }
        var collectionModificationData = CollectionItemChangeMetadata(
            eventData.modifiedCollectionItem,
            isFromExplicitAction: false);
        add(_UpdateTripEntityInternalEvent.updated(collectionModificationData,
            isOperationSuccess: true));
      }
    });
    var tripMetadataAddedSubscription = _tripRepository!
        .tripMetadataCollection.onDocumentAdded
        .listen((eventData) {
      var addedTripMetadata = eventData.modifiedCollectionItem;
      if (_activeTrip != null &&
          _activeTrip!.tripMetadata.id != addedTripMetadata.id) {
        return;
      }
      if (!eventData.isFromExplicitAction) {
        if (!isClosed) {
          var collectionModificationData = CollectionItemChangeMetadata(
              addedTripMetadata,
              isFromExplicitAction: false);
          add(_UpdateTripEntityInternalEvent.created(collectionModificationData,
              isOperationSuccess: true));
        }
      }
    });
    var tripMetadataDeletedSubscription = _tripRepository!
        .tripMetadataCollection.onDocumentDeleted
        .listen((eventData) {
      var deletedTripMetadata = eventData.modifiedCollectionItem;
      if (_activeTrip != null &&
          _activeTrip!.tripMetadata.id != deletedTripMetadata.id) {
        return;
      }
      if (!eventData.isFromExplicitAction) {
        if (!isClosed) {
          var collectionModificationData = CollectionItemChangeMetadata(
              deletedTripMetadata,
              isFromExplicitAction: false);
          add(_UpdateTripEntityInternalEvent.deleted(collectionModificationData,
              isOperationSuccess: true));
        }
      }
    });
    _tripRepositorySubscriptions.add(tripMetadataUpdatedSubscription);
    _tripRepositorySubscriptions.add(tripMetadataDeletedSubscription);
    _tripRepositorySubscriptions.add(tripMetadataAddedSubscription);
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
            if (modelCollection.collectionItems
                .whereType<TripEntity>()
                .any((element) => element.id == tripEntityId)) {
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
                .whereType<TripEntity>()
                .where((element) => element.id == tripEntityId)
                .firstOrNull;
            if (collectionItem != null) {
              var didUpdate = await modelCollection.tryUpdateItem(tripEntity);
              emit(UpdatedTripEntity.updated(
                  tripEntityModificationData: CollectionItemChangeMetadata(
                      CollectionItemChangeSet<E>(
                          collectionItem as E, tripEntity),
                      isFromExplicitAction: true),
                  isOperationSuccess: didUpdate));
            }
          }
          break;
        }
      case DataState.select:
        {
          var originalTripEntity = modelCollection.collectionItems
              .whereType<TripEntity>()
              .where((e) => e.id == tripEntityId)
              .firstOrNull as E?;
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
        if (!isClosed) {
          var collectionModificationData = CollectionItemChangeMetadata(
              eventData.modifiedCollectionItem,
              isFromExplicitAction: false);
          add(_UpdateTripEntityInternalEvent<T>.created(
              collectionModificationData,
              isOperationSuccess: true));
        }
      }
    });
    var tripEntityDeletedSubscription =
        modelCollection.onDocumentDeleted.listen((eventData) {
      if (!eventData.isFromExplicitAction) {
        if (!isClosed) {
          var collectionModificationData = CollectionItemChangeMetadata(
              eventData.modifiedCollectionItem,
              isFromExplicitAction: false);
          add(_UpdateTripEntityInternalEvent<T>.deleted(
              collectionModificationData,
              isOperationSuccess: true));
        }
      }
    });
    var tripEntityUpdatedSubscription =
        modelCollection.onDocumentUpdated.listen((eventData) {
      if (!eventData.isFromExplicitAction) {
        if (!isClosed) {
          var collectionModificationData = CollectionItemChangeMetadata(
              eventData.modifiedCollectionItem,
              isFromExplicitAction: false);
          add(_UpdateTripEntityInternalEvent.updated(collectionModificationData,
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
    await _clearItineraryPlanDataSubscriptions();
  }

  FutureOr<void> _createItineraryPlanDataSubscriptions() async {
    for (final itinerary in _activeTrip!.itineraryCollection) {
      var planDataSubscription = itinerary.planDataStream.listen((eventData) {
        if (!eventData.isFromExplicitAction) {
          if (!isClosed) {
            add(_UpdateTripEntityInternalEvent.updated(
                CollectionItemChangeMetadata(eventData.modifiedCollectionItem,
                    isFromExplicitAction: false),
                isOperationSuccess: true));
          }
        }
      });
      _itineraryPlanDataSubscriptions.add(planDataSubscription);
    }
  }

  Future<void> _clearItineraryPlanDataSubscriptions() async {
    for (final subscription in _itineraryPlanDataSubscriptions) {
      await subscription.cancel();
    }
    _itineraryPlanDataSubscriptions.clear();
  }
}

class _UpdateTripEntityInternalEvent<T> extends TripManagementEvent {
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
