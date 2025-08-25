import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/budgeting/expense.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/firestore_helpers.dart';
import 'package:wandrr/data/trip/implementations/location.dart';
import 'package:wandrr/data/trip/models/transit.dart';

// ignore: must_be_immutable
class TransitImplementation extends TransitFacade
    implements LeafRepositoryItem<TransitFacade> {
  static const _departureLocationField = 'departureLocation';
  static const _departureDateTimeField = 'departureDateTime';
  static const _arrivalLocationField = 'arrivalLocation';
  static const _arrivalDateTimeField = 'arrivalDateTime';
  static const _transitOptionField = 'transitOption';
  static const _operatorField = 'operator';
  static const _confirmationIdField = 'confirmationId';
  static const _expenseField = 'totalExpense';
  static const _notesField = 'notes';

  TransitImplementation.fromModelFacade(
      {required TransitFacade transitModelFacade})
      : super(
            tripId: transitModelFacade.tripId,
            transitOption: transitModelFacade.transitOption,
            departureDateTime: transitModelFacade.departureDateTime,
            arrivalDateTime: transitModelFacade.arrivalDateTime,
            departureLocation: transitModelFacade.departureLocation == null
                ? null
                : LocationModelImplementation.fromModelFacade(
                    locationModelFacade: transitModelFacade.departureLocation!),
            arrivalLocation: transitModelFacade.arrivalLocation == null
                ? null
                : LocationModelImplementation.fromModelFacade(
                    locationModelFacade: transitModelFacade.arrivalLocation!),
            expense: ExpenseModelImplementation.fromModelFacade(
                expenseModelFacade: transitModelFacade.expense),
            confirmationId: transitModelFacade.confirmationId,
            id: transitModelFacade.id,
            operator: transitModelFacade.operator,
            notes: transitModelFacade.notes) {
    expense.dateTime = departureDateTime;
  }

  static TransitImplementation fromDocumentSnapshot(
          String tripId, DocumentSnapshot documentSnapshot) =>
      TransitImplementation._(
          id: documentSnapshot.id,
          tripId: tripId,
          notes: documentSnapshot[_notesField],
          transitOption: TransitOption.values.firstWhere((element) =>
              element.name == documentSnapshot[_transitOptionField]),
          expense: ExpenseModelImplementation.fromJson(
              tripId: tripId,
              json: documentSnapshot[_expenseField] as Map<String, dynamic>),
          confirmationId: documentSnapshot[_confirmationIdField],
          departureDateTime:
              (documentSnapshot[_departureDateTimeField] as Timestamp).toDate(),
          arrivalDateTime:
              (documentSnapshot[_arrivalDateTimeField] as Timestamp).toDate(),
          arrivalLocation: LocationModelImplementation.fromJson(
              json: documentSnapshot[_arrivalLocationField], tripId: tripId),
          departureLocation: LocationModelImplementation.fromJson(
              json: documentSnapshot[_departureLocationField], tripId: tripId),
          operator: documentSnapshot[_operatorField]);

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripCollectionName)
      .doc(tripId)
      .collection(FirestoreCollections.transitCollectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() => {
        _transitOptionField: transitOption.name,
        _expenseField: (expense as LeafRepositoryItem?)?.toJson(),
        _departureDateTimeField: Timestamp.fromDate(departureDateTime!),
        _arrivalDateTimeField: Timestamp.fromDate(arrivalDateTime!),
        _departureLocationField:
            (departureLocation as LeafRepositoryItem?)?.toJson(),
        _arrivalLocationField:
            (arrivalLocation as LeafRepositoryItem?)?.toJson(),
        _confirmationIdField: confirmationId,
        _operatorField: operator,
        _notesField: notes
      };

  @override
  Future<bool> tryUpdate(TransitFacade toUpdate) async {
    var json = <String, dynamic>{};
    FirestoreHelpers.updateJson(departureLocation, toUpdate.departureLocation,
        _departureLocationField, json);
    FirestoreHelpers.updateJson(
        arrivalLocation, toUpdate.arrivalLocation, _arrivalLocationField, json);
    FirestoreHelpers.updateJson(expense, toUpdate.expense, _expenseField, json);
    FirestoreHelpers.updateJson(departureDateTime, toUpdate.departureDateTime,
        _departureDateTimeField, json);
    FirestoreHelpers.updateJson(
        arrivalDateTime, toUpdate.arrivalDateTime, _arrivalDateTimeField, json);
    FirestoreHelpers.updateJson(
        confirmationId, toUpdate.confirmationId, _confirmationIdField, json);
    FirestoreHelpers.updateJson(
        operator, toUpdate.operator, _operatorField, json);
    FirestoreHelpers.updateJson(notes, toUpdate.notes, _notesField, json);
    FirestoreHelpers.updateJson(
        transitOption, toUpdate.transitOption, _transitOptionField, json);
    return await FirestoreHelpers.tryUpdateDocumentField(
        documentReference: documentReference,
        json: json,
        onSuccess: () {
          copyWith(toUpdate);
        });
  }

  @override
  TransitFacade get facade => clone();

  TransitImplementation._(
      {required super.tripId,
      required super.transitOption,
      required super.departureDateTime,
      required super.arrivalDateTime,
      required LocationModelImplementation departureLocation,
      required LocationModelImplementation arrivalLocation,
      required ExpenseModelImplementation expense,
      super.confirmationId,
      super.id,
      super.operator,
      super.notes})
      : super(
            arrivalLocation: arrivalLocation,
            expense: expense,
            departureLocation: departureLocation) {
    expense.dateTime = departureDateTime;
  }
}
