import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/location.dart';
import 'package:wandrr/data/trip/models/lodging.dart';

import 'budgeting/expense.dart';

// ignore: must_be_immutable
class LodgingModelImplementation extends LodgingFacade
    implements LeafRepositoryItem<LodgingFacade> {
  static const _locationField = 'location';
  static const _confirmationIdField = 'confirmationId';
  static const _expenseField = 'expense';
  static const _checkinDateTimeField = 'checkinDateTime';
  static const _checkoutDateTimeField = 'checkoutDateTime';
  static const _notesField = 'notes';

  LodgingModelImplementation.fromModelFacade(
      {required LodgingFacade lodgingModelFacade})
      : super(
            location: lodgingModelFacade.location == null
                ? null
                : LocationModelImplementation.fromModelFacade(
                    locationModelFacade: lodgingModelFacade.location!),
            checkinDateTime: lodgingModelFacade.checkinDateTime,
            checkoutDateTime: lodgingModelFacade.checkoutDateTime,
            tripId: lodgingModelFacade.tripId,
            expense: ExpenseModelImplementation.fromModelFacade(
                expenseModelFacade: lodgingModelFacade.expense),
            confirmationId: lodgingModelFacade.confirmationId,
            id: lodgingModelFacade.id,
            notes: lodgingModelFacade.notes);

  static LodgingModelImplementation fromDocumentSnapshot(
      {required String tripId, required DocumentSnapshot documentSnapshot}) {
    var documentData = documentSnapshot.data() as Map<String, dynamic>;
    return LodgingModelImplementation._(
        tripId: tripId,
        id: documentSnapshot.id,
        checkinDateTime:
            (documentData[_checkinDateTimeField] as Timestamp).toDate(),
        checkoutDateTime:
            (documentData[_checkoutDateTimeField] as Timestamp).toDate(),
        location: LocationModelImplementation.fromJson(
            json: documentData[_locationField], tripId: tripId),
        notes: documentData[_notesField],
        expense: ExpenseModelImplementation.fromJson(
            tripId: tripId,
            json: documentData[_expenseField] as Map<String, dynamic>),
        confirmationId: documentData[_confirmationIdField]);
  }

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripCollectionName)
      .doc(tripId)
      .collection(FirestoreCollections.lodgingCollectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() {
    return {
      _locationField: (location as LeafRepositoryItem).toJson(),
      _expenseField: (expense as LeafRepositoryItem).toJson(),
      _checkinDateTimeField: Timestamp.fromDate(checkinDateTime!),
      _checkoutDateTimeField: Timestamp.fromDate(checkoutDateTime!),
      if (confirmationId != null && confirmationId!.isNotEmpty)
        _confirmationIdField: confirmationId,
      if (notes != null && notes!.isNotEmpty) _notesField: notes
    };
  }

  @override
  LodgingFacade get facade => clone();

  LodgingModelImplementation._(
      {required LocationModelImplementation location,
      required DateTime super.checkinDateTime,
      required DateTime super.checkoutDateTime,
      required super.tripId,
      required ExpenseModelImplementation expense,
      required String super.id,
      super.confirmationId,
      super.notes})
      : super(location: location, expense: expense);
}
