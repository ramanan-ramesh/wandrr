import 'package:wandrr/app_data/models/data_states.dart';
import 'package:wandrr/trip_data/models/expense.dart';
import 'package:wandrr/trip_data/models/plan_data.dart';
import 'package:wandrr/trip_data/models/trip_metadata.dart';

abstract class TripManagementEvent {}

class GoToHome extends TripManagementEvent {}

class UpdateTripEntity<T> extends TripManagementEvent {
  T? tripEntity;
  final DataState dataState;

  UpdateTripEntity.createNewUiEntry() : dataState = DataState.NewUiEntry;

  UpdateTripEntity.create({required this.tripEntity})
      : dataState = DataState.Create;

  UpdateTripEntity.delete({required this.tripEntity})
      : dataState = DataState.Delete;

  UpdateTripEntity.update({required this.tripEntity})
      : dataState = DataState.Update;

  UpdateTripEntity.select({required this.tripEntity})
      : dataState = DataState.Select;
}

class LoadTrip extends TripManagementEvent {
  final TripMetadataFacade tripMetadata;

  LoadTrip({required this.tripMetadata});
}

class UpdateLinkedExpense<T> extends UpdateTripEntity<ExpenseFacade> {
  final T link;

  UpdateLinkedExpense.update(
      {required this.link, required ExpenseFacade expense})
      : super.update(tripEntity: expense);

  UpdateLinkedExpense.delete(
      {required this.link, required ExpenseFacade expense})
      : super.delete(tripEntity: expense);

  UpdateLinkedExpense.select(
      {required this.link, required ExpenseFacade expense})
      : super.select(tripEntity: expense);
}

class UpdateItineraryPlanData extends TripManagementEvent {
  final PlanDataFacade planData;
  final DateTime day;

  UpdateItineraryPlanData({required this.planData, required this.day});
}
