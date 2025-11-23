import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'budgeting/expense_category.dart';

// ignore: must_be_immutable
class LodgingFacade extends Equatable
    implements ExpenseLinkedTripEntity<LodgingFacade> {
  LocationFacade? location;

  DateTime? checkinDateTime;

  DateTime? checkoutDateTime;

  @override
  String? id;

  final String tripId;

  String? confirmationId;

  @override
  ExpenseFacade expense;

  String? notes;

  LodgingFacade(
      {required this.location,
      required this.checkinDateTime,
      required this.checkoutDateTime,
      required this.tripId,
      required this.expense,
      this.id,
      this.confirmationId,
      this.notes});

  LodgingFacade.newUiEntry(
      {required this.tripId,
      required Iterable<String> allTripContributors,
      required String defaultCurrency,
      this.notes})
      : expense = ExpenseFacade(
            tripId: tripId,
            title: ' ',
            currency: defaultCurrency,
            category: ExpenseCategory.lodging,
            paidBy: Map.fromIterables(allTripContributors,
                List.filled(allTripContributors.length, 0)),
            splitBy: allTripContributors.toList());

  @override
  LodgingFacade clone() => LodgingFacade(
      location: location?.clone(),
      checkinDateTime: checkinDateTime?.copyWith(),
      checkoutDateTime: checkoutDateTime?.copyWith(),
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

  @override
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
          '${checkinDateTime!.monthFormat} ${checkinDateTime!.day}';
      var checkOutDayDescription =
          '${checkoutDateTime!.monthFormat} ${checkoutDateTime!.day}';
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
