import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/trip_metadata.dart';

import 'expense_view_type.dart';

abstract class TripManagementEvent {}

class GoToHome extends TripManagementEvent {}

class LoadTrip extends TripManagementEvent {
  final TripMetaDataFacade tripMetaDataFacade;
  final bool isNewlyCreatedTrip;

  LoadTrip(
      {required this.tripMetaDataFacade, required this.isNewlyCreatedTrip});
}

class UpdateTripMetadata extends TripManagementEvent {
  final TripMetadataUpdator tripMetadataUpdator;
  final DataState requestedDataState;

  UpdateTripMetadata.create({required this.tripMetadataUpdator})
      : requestedDataState = DataState.RequestedCreation;

  UpdateTripMetadata.update({required this.tripMetadataUpdator})
      : requestedDataState = DataState.RequestedUpdate;
}

class UpdateTransit extends TripManagementEvent {
  final TransitUpdator transitUpdator;
  final bool isLinkedExpense;
  final DataState requestedDataState;

  UpdateTransit.create(
      {required this.transitUpdator, this.isLinkedExpense = false})
      : requestedDataState = DataState.RequestedCreation;
  UpdateTransit.update(
      {required this.transitUpdator, this.isLinkedExpense = false})
      : requestedDataState = DataState.RequestedUpdate;
  UpdateTransit.select(
      {required this.transitUpdator, this.isLinkedExpense = false})
      : requestedDataState = DataState.RequestedSelection;
  UpdateTransit.delete(
      {required this.transitUpdator, this.isLinkedExpense = false})
      : requestedDataState = DataState.RequestedDeletion;
}

class UpdateLodging extends TripManagementEvent {
  final LodgingUpdator lodgingUpdator;
  final bool isLinkedExpense;
  final DataState requestedDateState;

  UpdateLodging.create(
      {required this.lodgingUpdator, this.isLinkedExpense = false})
      : requestedDateState = DataState.RequestedCreation;
  UpdateLodging.update(
      {required this.lodgingUpdator, this.isLinkedExpense = false})
      : requestedDateState = DataState.RequestedUpdate;
  UpdateLodging.select(
      {required this.lodgingUpdator, this.isLinkedExpense = false})
      : requestedDateState = DataState.RequestedSelection;
  UpdateLodging.delete(
      {required this.lodgingUpdator, this.isLinkedExpense = false})
      : requestedDateState = DataState.RequestedDeletion;
}

class UpdateExpense extends TripManagementEvent {
  final ExpenseUpdator expenseUpdator;
  final DataState requestedDataState;

  UpdateExpense.create({required this.expenseUpdator})
      : requestedDataState = DataState.RequestedCreation;
  UpdateExpense.update({required this.expenseUpdator})
      : requestedDataState = DataState.RequestedUpdate;
  UpdateExpense.select({required this.expenseUpdator})
      : requestedDataState = DataState.RequestedSelection;
  UpdateExpense.delete({required this.expenseUpdator})
      : requestedDataState = DataState.RequestedDeletion;
}

class UpdateExpenseView extends TripManagementEvent {
  final ExpenseViewType newExpenseViewType;
  UpdateExpenseView.showExpenseList()
      : newExpenseViewType = ExpenseViewType.RequestExpenseList;
  UpdateExpenseView.showBreakdown()
      : newExpenseViewType = ExpenseViewType.RequestBreakdownViewer;
  UpdateExpenseView.showBudgetEditor()
      : newExpenseViewType = ExpenseViewType.RequestBudgetEditor;
  UpdateExpenseView.showAddTripMate()
      : newExpenseViewType = ExpenseViewType.RequestAddTripmate;
  UpdateExpenseView.showDebtSummary()
      : newExpenseViewType = ExpenseViewType.RequestDebtSummary;
}

class UpdatePlanData extends TripManagementEvent {
  final PlanDataUpdator planDataUpdator;
  final DataState requestedDataState;
  UpdatePlanData.create({required this.planDataUpdator})
      : requestedDataState = DataState.RequestedCreation;
  UpdatePlanData.update({required this.planDataUpdator})
      : requestedDataState = DataState.RequestedUpdate;
  UpdatePlanData.delete({required this.planDataUpdator})
      : requestedDataState = DataState.RequestedDeletion;
}

class UpdateItineraryData extends TripManagementEvent {
  final PlanDataUpdator planDataUpdator;
  final DateTime day;
  UpdateItineraryData({required this.planDataUpdator, required this.day});
}
