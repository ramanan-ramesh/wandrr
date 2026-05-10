import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';

import 'budgeting/expense_category.dart';

// ignore: must_be_immutable
class TransitFacade extends Equatable
    implements ExpenseBearingTripEntity<TransitValidationError> {
  final String tripId;

  @override
  String? id;

  /// If set, this leg is part of a multi-leg journey.
  /// All legs with the same journeyId are connected.
  /// If null, this is a standalone transit leg.
  String? journeyId;

  TransitOption transitOption;

  LocationFacade? departureLocation;

  DateTime? departureDateTime;

  LocationFacade? arrivalLocation;

  DateTime? arrivalDateTime;

  String? operator;

  String? confirmationId;

  String? notes;

  String? departurePlatform;

  String? arrivalPlatform;

  Map<String, String>? seatNumbers;

  @override
  ExpenseFacade expense;

  @override
  ExpenseCategory get category => getExpenseCategory(transitOption);

  @override
  set category(ExpenseCategory value) {}

  @override
  String get title => toString();

  @override
  set title(String value) {}

  TransitFacade(
      {required this.tripId,
      required this.transitOption,
      required this.departureDateTime,
      required this.arrivalDateTime,
      required this.departureLocation,
      required this.arrivalLocation,
      required this.expense,
      this.journeyId,
      this.confirmationId,
      this.id,
      this.operator,
      this.departurePlatform,
      this.arrivalPlatform,
      this.seatNumbers,
      String? notes})
      : notes = notes ?? '';

  TransitFacade.newUiEntry(
      {required this.tripId,
      required this.transitOption,
      required Iterable<String> allTripContributors,
      required String defaultCurrency,
      this.journeyId,
      String? notes})
      : notes = notes ?? '',
        expense = ExpenseFacade(
            currency: defaultCurrency,
            paidBy: Map.fromIterables(allTripContributors,
                List.filled(allTripContributors.length, 0)),
            splitBy: allTripContributors.toList());

  @override
  TransitFacade clone() => TransitFacade(
      tripId: tripId,
      transitOption: transitOption,
      departureDateTime: departureDateTime?.copyWith(),
      arrivalDateTime: arrivalDateTime?.copyWith(),
      departureLocation: departureLocation?.clone(),
      arrivalLocation: arrivalLocation?.clone(),
      expense: expense.clone(),
      journeyId: journeyId,
      confirmationId: confirmationId,
      id: id,
      operator: operator,
      notes: notes,
      departurePlatform: departurePlatform,
      arrivalPlatform: arrivalPlatform,
      seatNumbers: seatNumbers != null ? Map.from(seatNumbers!) : null);

  void copyWith(TransitFacade transitModelFacade) {
    transitOption = transitModelFacade.transitOption;
    departureDateTime = transitModelFacade.departureDateTime;
    arrivalDateTime = transitModelFacade.arrivalDateTime;
    departureLocation = transitModelFacade.departureLocation;
    arrivalLocation = transitModelFacade.arrivalLocation;
    expense = transitModelFacade.expense;
    journeyId = transitModelFacade.journeyId;
    confirmationId = transitModelFacade.confirmationId;
    operator = transitModelFacade.operator;
    notes = transitModelFacade.notes;
    departurePlatform = transitModelFacade.departurePlatform;
    arrivalPlatform = transitModelFacade.arrivalPlatform;
    seatNumbers = transitModelFacade.seatNumbers != null
        ? Map.from(transitModelFacade.seatNumbers!)
        : null;
  }

  @override
  String toString() {
    if (departureDateTime != null &&
        departureLocation != null &&
        arrivalLocation != null) {
      var dateTime =
          '${departureDateTime!.monthFormat} ${departureDateTime!.day}';
      return '${departureLocation!} to ${arrivalLocation!} on $dateTime';
    }
    return 'Unnamed Entry';
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

  @override
  Iterable<TransitValidationError> getValidationErrors() {
    final errors = <TransitValidationError>[];
    if (departureLocation == null) {
      errors.add(TransitValidationError.missingDepartureLocation);
    }
    if (arrivalLocation == null) {
      errors.add(TransitValidationError.missingArrivalLocation);
    }
    if (departureDateTime == null) {
      errors.add(TransitValidationError.missingDepartureTime);
    }
    if (arrivalDateTime == null) {
      errors.add(TransitValidationError.missingArrivalTime);
    }
    if (departureDateTime != null &&
        arrivalDateTime != null &&
        departureDateTime!.compareTo(arrivalDateTime!) >= 0) {
      errors.add(TransitValidationError.invalidTimeSequence);
    }
    if (transitOption == TransitOption.flight && !_isFlightOperatorValid()) {
      errors.add(TransitValidationError.invalidFlightOperator);
    }
    if (!expense.isValid) {
      errors.add(TransitValidationError.expenseInvalid);
    }
    return errors;
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

  // Normalise nullable-but-semantically-empty values so that a field written
  // as null by one code path and "" / {} by another compares equal.
  static String? _n(String? s) => (s == null || s.isEmpty) ? null : s;
  static Map<K, V>? _nm<K, V>(Map<K, V>? m) =>
      (m == null || m.isEmpty) ? null : m;

  @override
  List<Object?> get props => [
        tripId,
        transitOption,
        departureDateTime,
        arrivalDateTime,
        departureLocation,
        arrivalLocation,
        expense,
        _n(journeyId),
        _n(confirmationId),
        id,
        _n(operator),
        _n(notes),
        _n(departurePlatform),
        _n(arrivalPlatform),
        _nm(seatNumbers),
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
