import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/trip/models/expense.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'money.dart';

class LodgingFacade extends Equatable implements TripEntity {
  LocationFacade? location;

  DateTime? checkinDateTime;

  DateTime? checkoutDateTime;

  @override
  String? id;

  String tripId;

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
            category: ExpenseCategory.Lodging,
            paidBy: Map.fromIterables(allTripContributors,
                List.filled(allTripContributors.length, 0)),
            splitBy: allTripContributors.toList());

  void copyWith(LodgingFacade lodgingModelFacade) {
    tripId = lodgingModelFacade.tripId;
    location = lodgingModelFacade.location;
    checkinDateTime = lodgingModelFacade.checkinDateTime;
    checkoutDateTime = lodgingModelFacade.checkoutDateTime;
    id = lodgingModelFacade.id;
    tripId = lodgingModelFacade.tripId;
    confirmationId = lodgingModelFacade.confirmationId;
    expense = lodgingModelFacade.expense;
    notes = lodgingModelFacade.notes;
  }

  LodgingFacade clone() {
    return LodgingFacade(
        location: location?.clone(),
        checkinDateTime: checkinDateTime,
        checkoutDateTime: checkoutDateTime,
        id: id,
        tripId: tripId,
        confirmationId: confirmationId,
        expense: expense.clone(),
        notes: notes);
  }

  bool isValid() {
    return location != null &&
        checkinDateTime != null &&
        checkoutDateTime != null &&
        expense.isValid();
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
