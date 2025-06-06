import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/trip/models/expense.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'money.dart';

class TransitFacade extends Equatable implements TripEntity {
  final String tripId;

  @override
  String? id;

  TransitOption transitOption;

  LocationFacade? departureLocation;

  DateTime? departureDateTime;

  LocationFacade? arrivalLocation;

  DateTime? arrivalDateTime;

  String? operator;

  String? confirmationId;

  String? notes;

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
            splitBy: allTripContributors.toList());

  void copyWith(TransitFacade transitModelFacade) {
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
      case TransitOption.publicTransport:
      case TransitOption.train:
      case TransitOption.cruise:
      case TransitOption.ferry:
      case TransitOption.bus:
        {
          return ExpenseCategory.publicTransit;
        }
      case TransitOption.rentedVehicle:
        {
          return ExpenseCategory.carRental;
        }
      case TransitOption.flight:
        {
          return ExpenseCategory.flights;
        }
      case TransitOption.taxi:
        {
          return ExpenseCategory.taxi;
        }
      default:
        {
          return ExpenseCategory.publicTransit;
        }
    }
  }

  bool _isFlightOperatorValid() {
    if (transitOption == TransitOption.flight) {
      var splitOptions = operator?.split(' ');
      if (splitOptions != null &&
          splitOptions.length >= 3 &&
          !splitOptions.any((e) => e.isEmpty)) {
        return true;
      }
      return false;
    }
    return true;
  }

  bool isValid() {
    var areLocationsValid =
        departureLocation != null && arrivalLocation != null;
    var areDateTimesValid = departureDateTime != null &&
        arrivalDateTime != null &&
        departureDateTime!.compareTo(arrivalDateTime!) < 0;
    var isTransitCarrierValid =
        transitOption == TransitOption.flight ? _isFlightOperatorValid() : true;
    return areLocationsValid &&
        areDateTimesValid &&
        isTransitCarrierValid &&
        expense.isValid();
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
  bus,
  flight,
  rentedVehicle,
  train,
  walk,
  ferry,
  cruise,
  vehicle,
  publicTransport,
  taxi
}
