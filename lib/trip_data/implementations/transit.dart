import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/app_data/models/repository_pattern.dart';
import 'package:wandrr/trip_data/implementations/collection_names.dart';
import 'package:wandrr/trip_data/implementations/expense.dart';
import 'package:wandrr/trip_data/implementations/firestore_helpers.dart';
import 'package:wandrr/trip_data/implementations/location.dart';
import 'package:wandrr/trip_data/models/transit.dart';

class TransitImplementation extends TransitFacade
    implements RepositoryPattern<TransitFacade> {
  static const _departureLocationField = 'departureLocation';
  static const _departureDateTimeField = 'departureDateTime';
  static const _arrivalLocationField = 'arrivalLocation';
  static const _arrivalDateTimeField = 'arrivalDateTime';
  static const _transitOptionField = 'transitOption';
  static const _operatorField = 'operator';
  static const _confirmationIdField = 'confirmationId';
  static const _expenseField = 'totalExpense';
  static const _notesField = 'notes';

  TransitImplementation(
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
            departureLocation: departureLocation);

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
            notes: transitModelFacade.notes);

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripCollectionName)
      .doc(tripId)
      .collection(FirestoreCollections.transitCollectionName)
      .doc(id);

  static TransitImplementation fromDocumentSnapshot(
      String tripId, DocumentSnapshot documentSnapshot) {
    return TransitImplementation(
        id: documentSnapshot.id,
        tripId: tripId,
        notes: documentSnapshot[_notesField],
        transitOption: TransitOption.values.firstWhere(
            (element) => element.name == documentSnapshot[_transitOptionField]),
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
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      _transitOptionField: transitOption.name,
      _expenseField: (expense as RepositoryPattern?)?.toJson(),
      _departureDateTimeField: Timestamp.fromDate(departureDateTime!),
      _arrivalDateTimeField: Timestamp.fromDate(arrivalDateTime!),
      _departureLocationField:
          (departureLocation as RepositoryPattern?)?.toJson(),
      _arrivalLocationField: (arrivalLocation as RepositoryPattern?)?.toJson(),
      _confirmationIdField: confirmationId,
      _operatorField: operator,
      _notesField: notes
    };
  }

  @override
  Future<bool> tryUpdate(TransitFacade toUpdate) async {
    Map<String, dynamic> json = {};
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
    if (json.isEmpty) {
      return false;
    }
    var didUpdate = json.isNotEmpty;
    await documentReference
        .set(json, SetOptions(merge: true))
        .catchError((error, stackTrace) {
      didUpdate = false;
    });
    return didUpdate;
  }

  @override
  TransitFacade get facade => clone();
}
