import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/trip_data/models/expense.dart';
import 'package:wandrr/trip_data/models/location.dart';
import 'package:wandrr/trip_data/models/trip_entity.dart';

import 'money.dart';

class TransitFacade extends Equatable implements TripEntity {
  String tripId;

  @override
  String? id;

  TransitOption transitOption;

  LocationFacade? departureLocation;

  DateTime? departureDateTime;

  LocationFacade? arrivalLocation;

  DateTime? arrivalDateTime;

  String? operator;

  String? confirmationId;

  //TODO: Make this null. Don't want to put in DB if not present
  String notes;

  ExpenseFacade expense;

  TransitFacade(
      {required this.tripId,
      required this.transitOption,
      required this.departureDateTime,
      required this.arrivalDateTime,
      required this.departureLocation,
      required this.arrivalLocation,
      required this.expense,
      this.confirmationId,
      this.id,
      this.operator,
      String? notes})
      : notes = notes ?? '';

  TransitFacade.newUiEntry(
      {required this.tripId,
      required this.transitOption,
      String? notes,
      required List<String> allTripContributors,
      required String currentUserName,
      required String defaultCurrency})
      : notes = notes ?? '',
        expense = ExpenseFacade(
            tripId: tripId,
            title: '',
            totalExpense: Money(currency: defaultCurrency, amount: 0),
            category: getExpenseCategory(transitOption),
            paidBy: Map.fromIterables(allTripContributors,
                List.filled(allTripContributors.length, 0)),
            splitBy: [currentUserName]);

  void copyWith(TransitFacade transitModelFacade) {
    tripId = transitModelFacade.tripId;
    id = transitModelFacade.id;
    transitOption = transitModelFacade.transitOption;
    departureDateTime = transitModelFacade.departureDateTime;
    arrivalDateTime = transitModelFacade.arrivalDateTime;
    departureLocation = transitModelFacade.departureLocation;
    arrivalLocation = transitModelFacade.arrivalLocation;
    expense = transitModelFacade.expense;
    confirmationId = transitModelFacade.confirmationId;
    operator = transitModelFacade.operator;
    notes = transitModelFacade.notes;
  }

  @override
  String toString() {
    var dateTime =
        '${DateFormat.MMMM().format(departureDateTime!).substring(0, 3)} ${departureDateTime!.day}';
    return '${departureLocation!.toString()} to ${arrivalLocation!.toString()} on $dateTime';
  }

  TransitFacade clone() {
    return TransitFacade(
        tripId: tripId,
        transitOption: transitOption,
        departureDateTime: departureDateTime,
        arrivalDateTime: arrivalDateTime,
        departureLocation: departureLocation?.clone(),
        arrivalLocation: arrivalLocation?.clone(),
        expense: expense.clone(),
        confirmationId: confirmationId,
        id: id,
        operator: operator,
        notes: notes);
  }

  static ExpenseCategory getExpenseCategory(TransitOption transitOptions) {
    switch (transitOptions) {
      case TransitOption.PublicTransport:
      case TransitOption.Train:
      case TransitOption.Cruise:
      case TransitOption.Ferry:
      case TransitOption.Bus:
        {
          return ExpenseCategory.PublicTransit;
        }
      case TransitOption.RentedVehicle:
        {
          return ExpenseCategory.CarRental;
        }
      case TransitOption.Flight:
        {
          return ExpenseCategory.Flights;
        }
      case TransitOption.Taxi:
        {
          return ExpenseCategory.Taxi;
        }
      default:
        {
          return ExpenseCategory.PublicTransit;
        }
    }
  }

  bool isFlightOperatorValid() {
    if (transitOption == TransitOption.Flight) {
      var splitOptions = operator?.split(' ');
      if (splitOptions != null &&
          splitOptions.length == 3 &&
          !splitOptions.any((e) => e.isEmpty)) {
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [
        tripId,
        transitOption,
        departureDateTime,
        arrivalDateTime,
        departureLocation,
        arrivalLocation,
        expense,
        confirmationId,
        id,
        operator,
        notes
      ];
}

//added new entries, so maintain the place where logos are added corresponding to each category
enum TransitOption {
  Bus,
  Flight,
  RentedVehicle,
  Train,
  Walk,
  Ferry,
  Cruise,
  Vehicle,
  PublicTransport,
  Taxi
}
