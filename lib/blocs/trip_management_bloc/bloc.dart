import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/expense_view_type.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_metadata.dart';
import 'package:wandrr/repositories/trip_management.dart';

import 'data_state.dart';
import 'events.dart';
import 'states.dart';

class TripManagementBloc
    extends Bloc<TripManagementEvent, TripManagementState> {
  final TripManagement _tripManagement;

  TripManagementBloc(this._tripManagement)
      : super(
          LoadedTripMetadatas(tripMetadatas: _tripManagement.tripMetadatas),
        ) {
    on<LoadTrip>(_onLoadTrip);
    on<UpdateTransit>(_onUpdateTransit);
    on<UpdateLodging>(_onUpdateLodging);
    on<UpdateExpense>(_onUpdateExpense);
    on<UpdateTripMetadata>(_onUpdateTripMetadata);
    on<GoToHome>(_onGoToHome);
    on<UpdateExpenseView>(_onExpenseViewUpdated);
    on<UpdatePlanData>(_onPlanDataUpdated);
    on<UpdateItineraryData>(_onItineraryDataUpdated);
  }

  FutureOr<void> _onLoadTrip(
      LoadTrip event, Emitter<TripManagementState> emit) async {
    if (_tripManagement.tripMetadatas.contains(event.tripMetaDataFacade)) {
      var trip = await _tripManagement.retrieveTrip(
          tripMetaData: event.tripMetaDataFacade as TripMetaData,
          isNewlyCreatedTrip: event.isNewlyCreatedTrip);
      _tripManagement.setActiveTrip(trip);
      emit(LoadedTrip(tripFacade: trip));
      emit(ExpenseViewUpdated.showExpenseList());
    }
  }

  FutureOr<void> _onUpdateTransit(
      UpdateTransit event, Emitter<TripManagementState> emit) async {
    var requestedDataState = event.requestedDataState;
    var transitUpdator = event.transitUpdator;
    var currentOperation = transitUpdator.dataState;
    if (requestedDataState == DataState.RequestedCreation) {
      if (currentOperation == DataState.None) {
        transitUpdator.dataState = DataState.CreateNewUIEntry;
        emit(TransitUpdated.created(
            transitUpdator: transitUpdator, isOperationSuccess: true));
        return;
      }
    }
    if (requestedDataState == DataState.RequestedDeletion) {
      if (transitUpdator.id == null ||
          currentOperation == DataState.CreateNewUIEntry) {
        emit(TransitUpdated.deleted(
            transitUpdator: transitUpdator, isOperationSuccess: true));
        return;
      }
    }
    if (requestedDataState == DataState.RequestedSelection) {
      if (currentOperation != DataState.CreateNewUIEntry &&
          currentOperation != DataState.Selected) {
        transitUpdator.dataState = DataState.Selected;
        emit(TransitUpdated.selected(
            transitUpdator: transitUpdator, isOperationSuccess: true));
        return;
      }
    }

    if (requestedDataState == DataState.RequestedUpdate) {
      var originalTransit = _tripManagement.activeTrip!.transits
          .firstWhere((element) => element.id == event.transitUpdator.id);
      var originalTransitUpdator =
          TransitUpdator.fromTransit(transit: originalTransit);
      if (originalTransitUpdator == event.transitUpdator) {
        event.transitUpdator.dataState = DataState.Updated;
        if (event.isLinkedExpense) {
          event.transitUpdator.expenseUpdator!.dataState = DataState.Updated;
        }
        emit(TransitUpdated.updated(
            transitUpdator: event.transitUpdator, isOperationSuccess: false));
        return;
      }
    }

    var tripModifier = _tripManagement.activeTrip as TripModifier;
    event.transitUpdator.dataState = requestedDataState;
    var totalTripExpenseBeforeUpdate =
        _tripManagement.activeTrip!.tripMetaData.totalExpenditure;
    var didUpdateTransit =
        await tripModifier.updateTransit(transitUpdator: event.transitUpdator);
    if (didUpdateTransit) {
      var totalTripExpenseAfterUpdate =
          _tripManagement.activeTrip!.tripMetaData.totalExpenditure;
      if (totalTripExpenseAfterUpdate != totalTripExpenseBeforeUpdate) {
        emit(UpdatedTripMetadata.updated(
            tripMetadataUpdator: TripMetadataUpdator.fromTripMetadata(
                tripMetaDataFacade: _tripManagement.activeTrip!.tripMetaData),
            isOperationSuccess: true));
      }
    }

    switch (requestedDataState) {
      case DataState.RequestedDeletion:
        {
          event.transitUpdator.dataState = DataState.Deleted;
          emit(TransitUpdated.deleted(
              transitUpdator: event.transitUpdator,
              isOperationSuccess: didUpdateTransit));
          break;
        }
      case DataState.RequestedUpdate:
        {
          event.transitUpdator.dataState = DataState.Updated;
          if (event.isLinkedExpense) {
            event.transitUpdator.expenseUpdator!.dataState = DataState.Updated;
          }
          emit(TransitUpdated.updated(
              transitUpdator: event.transitUpdator,
              isOperationSuccess: didUpdateTransit));
          break;
        }
      case DataState.RequestedCreation:
        {
          event.transitUpdator.dataState == DataState.Created;
          emit(TransitUpdated.created(
              transitUpdator: event.transitUpdator,
              isOperationSuccess: didUpdateTransit));
          break;
        }
      default:
        {
          break;
        }
    }
  }

  FutureOr<void> _onUpdateLodging(
      UpdateLodging event, Emitter<TripManagementState> emit) async {
    var requestedDataState = event.requestedDateState;
    var lodgingUpdator = event.lodgingUpdator;
    var currentOperation = lodgingUpdator.dataState;
    if (requestedDataState == DataState.RequestedCreation) {
      if (currentOperation == DataState.None) {
        lodgingUpdator.dataState = DataState.CreateNewUIEntry;
        emit(LodgingUpdated.created(
            lodgingUpdator: lodgingUpdator, isOperationSuccess: true));
        return;
      }
    }
    if (requestedDataState == DataState.RequestedDeletion) {
      if (lodgingUpdator.id == null ||
          currentOperation == DataState.CreateNewUIEntry) {
        emit(LodgingUpdated.deleted(
            lodgingUpdator: lodgingUpdator, isOperationSuccess: true));
        return;
      }
    }
    if (requestedDataState == DataState.RequestedSelection) {
      if (currentOperation != DataState.CreateNewUIEntry &&
          currentOperation != DataState.Selected) {
        lodgingUpdator.dataState = DataState.Selected;
        emit(LodgingUpdated.selected(
            lodgingUpdator: lodgingUpdator, isOperationSuccess: true));
        return;
      }
    }

    if (requestedDataState == DataState.RequestedUpdate) {
      var originalLodging = _tripManagement.activeTrip!.lodgings
          .firstWhere((element) => element.id == event.lodgingUpdator.id);
      var originalLodgingUpdator =
          LodgingUpdator.fromLodging(lodging: originalLodging);
      if (originalLodgingUpdator == event.lodgingUpdator) {
        event.lodgingUpdator.dataState = DataState.Updated;
        if (event.isLinkedExpense) {
          event.lodgingUpdator.expenseUpdator!.dataState = DataState.Updated;
        }
        emit(LodgingUpdated.updated(
            lodgingUpdator: event.lodgingUpdator, isOperationSuccess: false));
        return;
      }
    }

    var tripModifier = _tripManagement.activeTrip as TripModifier;
    event.lodgingUpdator.dataState = event.requestedDateState;
    var totalTripExpenseBeforeUpdate =
        _tripManagement.activeTrip!.tripMetaData.totalExpenditure;
    var didUpdateLodging =
        await tripModifier.updateLodging(lodgingUpdator: event.lodgingUpdator);
    if (didUpdateLodging) {
      var totalTripExpenseAfterUpdate =
          _tripManagement.activeTrip!.tripMetaData.totalExpenditure;
      if (totalTripExpenseAfterUpdate != totalTripExpenseBeforeUpdate) {
        emit(UpdatedTripMetadata.updated(
            tripMetadataUpdator: TripMetadataUpdator.fromTripMetadata(
                tripMetaDataFacade: _tripManagement.activeTrip!.tripMetaData),
            isOperationSuccess: true));
      }
    }

    switch (requestedDataState) {
      case DataState.RequestedDeletion:
        {
          event.lodgingUpdator.dataState = DataState.Deleted;
          emit(LodgingUpdated.deleted(
              lodgingUpdator: event.lodgingUpdator,
              isOperationSuccess: didUpdateLodging));
          break;
        }
      case DataState.RequestedUpdate:
        {
          event.lodgingUpdator.dataState = DataState.Updated;
          if (event.isLinkedExpense) {
            event.lodgingUpdator.expenseUpdator!.dataState = DataState.Updated;
          }
          emit(LodgingUpdated.updated(
              lodgingUpdator: event.lodgingUpdator,
              isOperationSuccess: didUpdateLodging));
          break;
        }
      case DataState.RequestedCreation:
        {
          event.lodgingUpdator.dataState = DataState.Created;
          emit(LodgingUpdated.created(
              lodgingUpdator: event.lodgingUpdator,
              isOperationSuccess: didUpdateLodging));
          break;
        }
      default:
        {
          break;
        }
    }
  }

  FutureOr<void> _onUpdateExpense(
      UpdateExpense event, Emitter<TripManagementState> emit) async {
    var requestedDataState = event.requestedDataState;
    var expenseUpdator = event.expenseUpdator;
    var currentOperation = expenseUpdator.dataState;
    if (requestedDataState == DataState.RequestedCreation) {
      if (currentOperation == DataState.None) {
        expenseUpdator.dataState = DataState.CreateNewUIEntry;
        emit(ExpenseUpdated.created(
            expenseUpdator: expenseUpdator, isOperationSuccess: true));
        return;
      }
    }
    if (requestedDataState == DataState.RequestedDeletion) {
      if (expenseUpdator.id == null ||
          currentOperation == DataState.CreateNewUIEntry) {
        emit(ExpenseUpdated.deleted(
            expenseUpdator: expenseUpdator, isOperationSuccess: true));
        return;
      }
    }
    if (requestedDataState == DataState.RequestedSelection) {
      if (currentOperation != DataState.CreateNewUIEntry &&
          currentOperation != DataState.Selected) {
        expenseUpdator.dataState = DataState.Selected;
        emit(ExpenseUpdated.selected(
            expenseUpdator: expenseUpdator, isOperationSuccess: true));
        return;
      }
    }

    if (requestedDataState == DataState.RequestedUpdate) {
      var originalExpense = _tripManagement.activeTrip!.expenses
          .firstWhere((element) => element.id == event.expenseUpdator.id);
      var originalExpenseUpdator =
          ExpenseUpdator.fromExpense(expense: originalExpense);
      if (originalExpenseUpdator == event.expenseUpdator) {
        emit(ExpenseUpdated.updated(
            expenseUpdator: event.expenseUpdator, isOperationSuccess: false));
        return;
      }
    }

    var tripModifier = _tripManagement.activeTrip as TripModifier;
    var totalExpenseBeforeUpdate =
        _tripManagement.activeTrip!.tripMetaData.totalExpenditure;
    event.expenseUpdator.dataState = event.requestedDataState;
    var didUpdateExpense =
        await tripModifier.updateExpense(expenseUpdator: event.expenseUpdator);
    if (didUpdateExpense) {
      var totalTripExpenseAfterUpdate =
          _tripManagement.activeTrip!.tripMetaData.totalExpenditure;
      if (totalTripExpenseAfterUpdate != totalExpenseBeforeUpdate) {
        emit(UpdatedTripMetadata.updated(
            tripMetadataUpdator: TripMetadataUpdator.fromTripMetadata(
                tripMetaDataFacade: _tripManagement.activeTrip!.tripMetaData),
            isOperationSuccess: true));
      }
    }

    switch (requestedDataState) {
      case DataState.RequestedDeletion:
        {
          event.expenseUpdator.dataState = DataState.Deleted;
          emit(ExpenseUpdated.deleted(
              expenseUpdator: event.expenseUpdator,
              isOperationSuccess: didUpdateExpense));
          break;
        }
      case DataState.RequestedUpdate:
        {
          event.expenseUpdator.dataState = DataState.Updated;
          emit(ExpenseUpdated.updated(
              expenseUpdator: event.expenseUpdator,
              isOperationSuccess: didUpdateExpense));
          break;
        }
      case DataState.RequestedCreation:
        {
          event.expenseUpdator.dataState = DataState.Created;
          emit(ExpenseUpdated.created(
              expenseUpdator: event.expenseUpdator,
              isOperationSuccess: didUpdateExpense));
          break;
        }
      default:
        {
          break;
        }
    }
  }

  FutureOr<void> _onPlanDataUpdated(
      UpdatePlanData event, Emitter<TripManagementState> emit) async {
    var requestedDataState = event.requestedDataState;
    var planDataUpdator = event.planDataUpdator;
    var currentOperation = planDataUpdator.dataState;
    if (requestedDataState == DataState.RequestedCreation) {
      if (currentOperation == DataState.None) {
        planDataUpdator.dataState = DataState.CreateNewUIEntry;
        emit(PlanDataUpdated.created(
            planDataUpdator: planDataUpdator, isOperationSuccess: true));
        return;
      }
    }
    if (requestedDataState == DataState.RequestedDeletion) {
      if (planDataUpdator.id == null ||
          currentOperation == DataState.CreateNewUIEntry) {
        emit(PlanDataUpdated.deleted(
            planDataUpdator: planDataUpdator, isOperationSuccess: true));
        return;
      }
    }

    var tripModifier = _tripManagement.activeTrip as TripModifier;
    event.planDataUpdator.dataState = event.requestedDataState;
    var updatedPlanData = await tripModifier.updatePlanData(
        planDataUpdator: event.planDataUpdator);

    switch (requestedDataState) {
      case DataState.RequestedCreation:
        {
          event.planDataUpdator.dataState = DataState.Created;
          emit(PlanDataUpdated.created(
              planDataUpdator: updatedPlanData ?? planDataUpdator,
              isOperationSuccess: updatedPlanData != null));
          break;
        }
      case DataState.RequestedUpdate:
        {
          event.planDataUpdator.dataState = DataState.Updated;
          emit(PlanDataUpdated.updated(
              planDataUpdator: updatedPlanData ?? event.planDataUpdator,
              isOperationSuccess: updatedPlanData != null));
          break;
        }
      case DataState.RequestedDeletion:
        {
          event.planDataUpdator.dataState = DataState.Deleted;
          emit(PlanDataUpdated.deleted(
              planDataUpdator: updatedPlanData ?? event.planDataUpdator,
              isOperationSuccess: updatedPlanData != null));
          break;
        }
      default:
        {
          break;
        }
    }
  }

  FutureOr<void> _onItineraryDataUpdated(
      UpdateItineraryData event, Emitter<TripManagementState> emit) async {
    var planDataUpdator = event.planDataUpdator;
    var itinerary = _tripManagement.activeTrip!.itineraries
        .firstWhere((element) => element.isOnSameDayAs(event.day));

    var tripModifier = _tripManagement.activeTrip as TripModifier;
    var updatedPlanData = await tripModifier.updateItineraryData(
        itineraryFacade: itinerary, planDataUpdator: planDataUpdator);
    emit(ItineraryDataUpdated(
        planDataUpdator: updatedPlanData ?? event.planDataUpdator,
        day: event.day,
        isOperationSuccess: updatedPlanData != null));
  }

  FutureOr<void> _onUpdateTripMetadata(
      UpdateTripMetadata event, Emitter<TripManagementState> emit) async {
    switch (event.requestedDataState) {
      case DataState.RequestedUpdate:
        {
          var tripMetadata =
              _tripManagement.activeTrip!.tripMetaData as TripMetaData;
          var didUpdate = await tripMetadata.update(
              tripMetadataUpdator: event.tripMetadataUpdator);
          emit(UpdatedTripMetadata.updated(
              tripMetadataUpdator: event.tripMetadataUpdator,
              isOperationSuccess: didUpdate));
          break;
        }
      case DataState.RequestedCreation:
        {
          var trip = await _tripManagement.createTrip(
              tripMetadataUpdator: event.tripMetadataUpdator);
          if (trip != null) {
            _tripManagement.setActiveTrip(trip);
            emit(LoadedTrip(tripFacade: trip));
            emit(ExpenseViewUpdated.showExpenseList());
          }
          break;
        }
      case DataState.RequestedDeletion:
        {
          await _tripManagement.deleteTrip(
              tripMetadataUpdator: event.tripMetadataUpdator);
          emit(UpdatedTripMetadata.deleted(
              tripMetadataUpdator: event.tripMetadataUpdator,
              isOperationSuccess: true));
          add(GoToHome());
        }
      default:
        {}
    }
  }

  FutureOr<void> _onGoToHome(
      GoToHome event, Emitter<TripManagementState> emit) async {
    _tripManagement.setActiveTrip(null);
    emit(LoadedTripMetadatas(tripMetadatas: _tripManagement.tripMetadatas));
  }

  FutureOr<void> _onExpenseViewUpdated(
      UpdateExpenseView event, Emitter<TripManagementState> emit) {
    switch (event.newExpenseViewType) {
      case ExpenseViewType.RequestBreakdownViewer:
        {
          emit(ExpenseViewUpdated.showBreakdown());
          break;
        }
      case ExpenseViewType.RequestDebtSummary:
        {
          emit(ExpenseViewUpdated.showDebtSummary());
          break;
        }
      case ExpenseViewType.RequestBudgetEditor:
        {
          emit(ExpenseViewUpdated.showBudgetEditor());
          break;
        }
      case ExpenseViewType.RequestExpenseList:
        {
          emit(ExpenseViewUpdated.showExpenseList());
          break;
        }
      case ExpenseViewType.RequestAddTripmate:
        {
          emit(ExpenseViewUpdated.showAddTripMate());
          break;
        }
      default:
        {
          emit(ExpenseViewUpdated.showExpenseList());
          break;
        }
    }
  }
}
