import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/budgeting/expense.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
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
      String tripId, DocumentSnapshot documentSnapshot) {
    var documentData = documentSnapshot.data() as Map<String, dynamic>;
    return TransitImplementation._(
        id: documentSnapshot.id,
        tripId: tripId,
        notes: documentData[_notesField],
        transitOption: TransitOption.values.firstWhere(
            (element) => element.name == documentData[_transitOptionField]),
        expense: ExpenseModelImplementation.fromJson(
            tripId: tripId,
            json: documentData[_expenseField] as Map<String, dynamic>),
        confirmationId: documentData[_confirmationIdField],
        departureDateTime:
            (documentData[_departureDateTimeField] as Timestamp).toDate(),
        arrivalDateTime:
            (documentData[_arrivalDateTimeField] as Timestamp).toDate(),
        arrivalLocation: LocationModelImplementation.fromJson(
            json: documentData[_arrivalLocationField]),
        departureLocation: LocationModelImplementation.fromJson(
            json: documentData[_departureLocationField]),
        operator: documentData[_operatorField]);
  }

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripCollectionName)
      .doc(tripId)
      .collection(FirestoreCollections.transitCollectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() {
    return {
      _transitOptionField: transitOption.name,
      _expenseField: (expense as LeafRepositoryItem).toJson(),
      _departureDateTimeField: Timestamp.fromDate(departureDateTime!),
      _arrivalDateTimeField: Timestamp.fromDate(arrivalDateTime!),
      _departureLocationField:
          (departureLocation as LeafRepositoryItem?)?.toJson(),
      _arrivalLocationField: (arrivalLocation as LeafRepositoryItem?)?.toJson(),
      if (confirmationId != null && confirmationId!.isNotEmpty)
        _confirmationIdField: confirmationId,
      if (operator != null && operator!.isNotEmpty) _operatorField: operator,
      if (notes != null && notes!.isNotEmpty) _notesField: notes
    };
  }

  @override
  TransitFacade get facade => clone();

  TransitImplementation._(
      {required super.tripId,
      required super.transitOption,
      required DateTime super.departureDateTime,
      required DateTime super.arrivalDateTime,
      required LocationModelImplementation departureLocation,
      required LocationModelImplementation arrivalLocation,
      required ExpenseModelImplementation expense,
      required String super.id,
      super.confirmationId,
      super.operator,
      super.notes})
      : super(
            arrivalLocation: arrivalLocation,
            expense: expense,
            departureLocation: departureLocation) {
    expense.dateTime = departureDateTime;
  }
}
