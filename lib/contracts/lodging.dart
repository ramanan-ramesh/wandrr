import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/location.dart';
import 'package:wandrr/contracts/trip_data.dart';

//#ui access sorted
class LodgingModelFacade extends Equatable implements TripEntity {
  LocationModelFacade? location;

  DateTime? checkinDateTime;

  DateTime? checkoutDateTime;

  @override
  String? id;

  String tripId;

  String? confirmationId;

  ExpenseModelFacade expense;

  String notes;

  LodgingModelFacade(
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

  LodgingModelFacade.newUiEntry(
      {required this.tripId,
      String? notes,
      required List<String> allTripContributors,
      required String currentUserName,
      required String defaultCurrency})
      : notes = notes ?? '',
        expense = ExpenseModelFacade(
            tripId: tripId,
            title: ' ',
            totalExpense:
                CurrencyWithValue(currency: defaultCurrency, amount: 0),
            category: ExpenseCategory.Lodging,
            paidBy: Map.fromIterables(allTripContributors,
                List.filled(allTripContributors.length, 0)),
            splitBy: [currentUserName]);

  void copyWith(LodgingModelFacade lodgingModelFacade) {
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

  LodgingModelFacade clone() {
    return LodgingModelFacade(
        location: location?.clone(),
        checkinDateTime: checkinDateTime,
        checkoutDateTime: checkoutDateTime,
        id: id,
        tripId: tripId,
        confirmationId: confirmationId,
        expense: expense.clone(),
        notes: notes);
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
