import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'budgeting/expense_category.dart';
import 'budgeting/money.dart';

class LodgingFacade extends Equatable implements TripEntity {
  LocationFacade? location;

  DateTime? checkinDateTime;

  DateTime? checkoutDateTime;

  @override
  String? id;

  final String tripId;

  String? confirmationId;

  ExpenseFacade expense;

  String notes;

  LodgingFacade(
      {required this.location,
      required this.checkinDateTime,
      required this.checkoutDateTime,
      String? id,
      required this.tripId,
      this.confirmationId,
      required this.expense,
      String? notes})
      : id = id ?? '',
        notes = notes ?? '';

  LodgingFacade.newUiEntry(
      {required this.tripId,
      String? notes,
      required List<String> allTripContributors,
      required String currentUserName,
      required String defaultCurrency})
      : notes = notes ?? '',
        expense = ExpenseFacade(
            tripId: tripId,
            title: ' ',
            totalExpense: Money(currency: defaultCurrency, amount: 0),
            category: ExpenseCategory.lodging,
            paidBy: Map.fromIterables(allTripContributors,
                List.filled(allTripContributors.length, 0)),
            splitBy: allTripContributors.toList());

  void copyWith(LodgingFacade lodgingModelFacade) {
    location = lodgingModelFacade.location;
    checkinDateTime = DateTime(
        lodgingModelFacade.checkinDateTime!.year,
        lodgingModelFacade.checkinDateTime!.month,
        lodgingModelFacade.checkinDateTime!.day);
    checkoutDateTime = DateTime(
        lodgingModelFacade.checkoutDateTime!.year,
        lodgingModelFacade.checkoutDateTime!.month,
        lodgingModelFacade.checkoutDateTime!.day);
    confirmationId = lodgingModelFacade.confirmationId;
    expense = lodgingModelFacade.expense;
    notes = lodgingModelFacade.notes;
  }

  LodgingFacade clone() {
    return LodgingFacade(
        location: location?.clone(),
        checkinDateTime: DateTime(checkinDateTime!.year, checkinDateTime!.month,
            checkinDateTime!.day),
        checkoutDateTime: DateTime(checkoutDateTime!.year,
            checkoutDateTime!.month, checkoutDateTime!.day),
        id: id,
        tripId: tripId,
        confirmationId: confirmationId,
        expense: expense.clone(),
        notes: notes);
  }

  bool validate() {
    return location != null &&
        checkinDateTime != null &&
        checkoutDateTime != null &&
        expense.validate();
  }

  @override
  String toString() {
    var checkInDayDescription =
        '${DateFormat.MMMM().format(checkinDateTime!).substring(0, 3)} ${checkinDateTime!.day}';
    var checkOutDayDescription =
        '${DateFormat.MMMM().format(checkoutDateTime!).substring(0, 3)} ${checkoutDateTime!.day}';
    return 'Stay at ${location!.toString()} from $checkInDayDescription to $checkOutDayDescription';
  }

  @override
  List<Object?> get props => [
        location,
        checkinDateTime,
        checkoutDateTime,
        id,
        tripId,
        confirmationId,
        expense,
        notes
      ];
}
