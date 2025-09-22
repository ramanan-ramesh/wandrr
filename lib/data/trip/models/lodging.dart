import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'budgeting/expense_category.dart';
import 'budgeting/money.dart';

// ignore: must_be_immutable
class LodgingFacade extends Equatable implements TripEntity<LodgingFacade> {
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
      required this.tripId,
      required this.expense,
      String? id,
      this.confirmationId,
      String? notes})
      : id = id ?? '',
        notes = notes ?? '';

  LodgingFacade.newUiEntry(
      {required this.tripId,
      required Iterable<String> allTripContributors,
      required String defaultCurrency,
      String? notes})
      : notes = notes ?? '',
        expense = ExpenseFacade(
            tripId: tripId,
            title: ' ',
            totalExpense: Money(currency: defaultCurrency, amount: 0),
            category: ExpenseCategory.lodging,
            paidBy: Map.fromIterables(allTripContributors,
                List.filled(allTripContributors.length, 0)),
            splitBy: allTripContributors.toList());

  @override
  LodgingFacade clone() => LodgingFacade(
      location: location?.clone(),
      checkinDateTime: DateTime(
          checkinDateTime!.year, checkinDateTime!.month, checkinDateTime!.day),
      checkoutDateTime: DateTime(checkoutDateTime!.year,
          checkoutDateTime!.month, checkoutDateTime!.day),
      id: id,
      tripId: tripId,
      confirmationId: confirmationId,
      expense: expense.clone(),
      notes: notes);

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

  bool validate() =>
      location != null &&
      checkinDateTime != null &&
      checkoutDateTime != null &&
      expense.validate();

  @override
  String toString() {
    if (checkinDateTime != null &&
        checkoutDateTime != null &&
        location != null) {
      var checkInDayDescription =
          '${DateFormat.MMMM().format(checkinDateTime!).substring(0, 3)} ${checkinDateTime!.day}';
      var checkOutDayDescription =
          '${DateFormat.MMMM().format(checkoutDateTime!).substring(0, 3)} ${checkoutDateTime!.day}';
      return 'Stay at ${location!} from $checkInDayDescription to $checkOutDayDescription';
    }
    return 'Unnamed Entry';
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
