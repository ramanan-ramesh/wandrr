import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_metadata.dart';

import 'expense_view_type.dart';

abstract class TripManagementState {}

class LoadedTripMetadatas extends TripManagementState {
  final List<TripMetaDataFacade> tripMetadatas;

  LoadedTripMetadatas({required this.tripMetadatas});
}

class LoadedTrip extends TripManagementState {
  final TripFacade tripFacade;

  LoadedTrip({required this.tripFacade});
}

class UpdatedTripMetadata extends TripManagementState {
  final TripMetadataUpdator tripMetadataUpdator;
  final DataState operation;
  final bool isOperationSuccess;

  UpdatedTripMetadata.created(
      {required this.tripMetadataUpdator, required this.isOperationSuccess})
      : operation = DataState.Created;

  UpdatedTripMetadata.updated(
      {required this.tripMetadataUpdator, required this.isOperationSuccess})
      : operation = DataState.Updated;
}

class TransitUpdated extends TripManagementState {
  final TransitUpdator transitUpdator;
  final DataState operation;
  final bool isOperationSuccess;

  TransitUpdated.created(
      {required this.transitUpdator, required this.isOperationSuccess})
      : operation = DataState.Created;

  TransitUpdated.updated(
      {required this.transitUpdator, required this.isOperationSuccess})
      : operation = DataState.Updated;

  TransitUpdated.deleted(
      {required this.transitUpdator, required this.isOperationSuccess})
      : operation = DataState.Deleted;

  TransitUpdated.selected(
      {required this.transitUpdator, required this.isOperationSuccess})
      : operation = DataState.Selected;
}

class LodgingUpdated extends TripManagementState {
  final LodgingUpdator lodgingUpdator;
  final DataState operation;
  final bool isOperationSuccess;

  LodgingUpdated.created(
      {required this.lodgingUpdator, required this.isOperationSuccess})
      : operation = DataState.Created;

  LodgingUpdated.updated(
      {required this.lodgingUpdator, required this.isOperationSuccess})
      : operation = DataState.Updated;

  LodgingUpdated.deleted(
      {required this.lodgingUpdator, required this.isOperationSuccess})
      : operation = DataState.Deleted;

  LodgingUpdated.selected(
      {required this.lodgingUpdator, required this.isOperationSuccess})
      : operation = DataState.Selected;
}

class ExpenseUpdated extends TripManagementState {
  final ExpenseUpdator expenseUpdator;
  final DataState operation;
  final bool isOperationSuccess;

  ExpenseUpdated.created(
      {required this.expenseUpdator, required this.isOperationSuccess})
      : operation = DataState.Created;

  ExpenseUpdated.updated(
      {required this.expenseUpdator, required this.isOperationSuccess})
      : operation = DataState.Updated;

  ExpenseUpdated.deleted(
      {required this.expenseUpdator, required this.isOperationSuccess})
      : operation = DataState.Deleted;

  ExpenseUpdated.selected(
      {required this.expenseUpdator, required this.isOperationSuccess})
      : operation = DataState.Selected;
}

class ExpenseViewUpdated extends TripManagementState {
  final ExpenseViewType newExpenseViewType;
  ExpenseViewUpdated.showExpenseList()
      : newExpenseViewType = ExpenseViewType.ShowExpenseList;
  ExpenseViewUpdated.showBreakdown()
      : newExpenseViewType = ExpenseViewType.ShowBreakdownViewer;
  ExpenseViewUpdated.showDebtSummary()
      : newExpenseViewType = ExpenseViewType.ShowDebtSummary;
  ExpenseViewUpdated.showBudgetEditor()
      : newExpenseViewType = ExpenseViewType.ShowBudgetEditor;
  ExpenseViewUpdated.showAddTripMate()
      : newExpenseViewType = ExpenseViewType.ShowAddTripmate;
}

class PlanDataUpdated extends TripManagementState {
  final PlanDataUpdator planDataUpdator;
  final DataState operation;
  final bool isOperationSuccess;

  PlanDataUpdated.created(
      {required this.planDataUpdator, required this.isOperationSuccess})
      : operation = DataState.Created;

  PlanDataUpdated.updated(
      {required this.planDataUpdator, required this.isOperationSuccess})
      : operation = DataState.Updated;

  PlanDataUpdated.deleted(
      {required this.planDataUpdator, required this.isOperationSuccess})
      : operation = DataState.Deleted;
}

class ItineraryDataUpdated extends TripManagementState {
  final PlanDataUpdator planDataUpdator;
  final DateTime day;
  final bool isOperationSuccess;
  ItineraryDataUpdated(
      {required this.planDataUpdator,
      required this.day,
      required this.isOperationSuccess});
}
