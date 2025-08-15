import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/firestore_helpers.dart';
import 'package:wandrr/data/trip/implementations/location.dart';
import 'package:wandrr/data/trip/models/lodging.dart';

import 'expense.dart';

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
            notes: lodgingModelFacade.notes) {
    expense.dateTime = checkinDateTime;
  }

  static LodgingModelImplementation fromDocumentSnapshot(
      {required String tripId, required DocumentSnapshot documentSnapshot}) {
    var documentData = documentSnapshot.data() as Map<String, dynamic>;
    var checkinDateTime =
        (documentData[_checkinDateTimeField] as Timestamp).toDate();
    var checkoutDateTime =
        (documentData[_checkoutDateTimeField] as Timestamp).toDate();
    var location = LocationModelImplementation.fromJson(
        json: documentData[_locationField], tripId: tripId);
    var expense = ExpenseModelImplementation.fromJson(
        tripId: tripId,
        json: documentSnapshot[_expenseField] as Map<String, dynamic>);
    return LodgingModelImplementation._(
        tripId: tripId,
        id: documentSnapshot.id,
        checkinDateTime: checkinDateTime,
        checkoutDateTime: checkoutDateTime,
        location: location,
        notes: documentData[_notesField],
        expense: expense,
        confirmationId: documentData[_confirmationIdField]);
  }

  LodgingModelImplementation._(
      {required LocationModelImplementation location,
      required super.checkinDateTime,
      required super.checkoutDateTime,
      required super.tripId,
      required ExpenseModelImplementation expense,
      super.confirmationId,
      super.id,
      super.notes})
      : super(location: location, expense: expense) {
    expense.dateTime = checkinDateTime;
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
      _confirmationIdField: confirmationId,
      _notesField: notes
    };
  }

  @override
  Future<bool> tryUpdate(LodgingFacade toUpdate) async {
    Map<String, dynamic> json = {};
    FirestoreHelpers.updateJson(
        checkinDateTime, toUpdate.checkinDateTime, _checkinDateTimeField, json);
    FirestoreHelpers.updateJson(checkoutDateTime, toUpdate.checkoutDateTime,
        _checkoutDateTimeField, json);
    FirestoreHelpers.updateJson(
        location, toUpdate.location, _locationField, json);
    FirestoreHelpers.updateJson(
        confirmationId, toUpdate.confirmationId, _confirmationIdField, json);
    FirestoreHelpers.updateJson(notes, toUpdate.notes, _notesField, json);
    FirestoreHelpers.updateJson(expense, toUpdate.expense, _expenseField, json);

    var didUpdateLodging = json.isNotEmpty;
    documentReference.set(json, SetOptions(merge: true)).then((value) {
      didUpdateLodging = true;
      copyWith(toUpdate);
    }).catchError((error, stackTrace) {
      didUpdateLodging = false;
    });
    return didUpdateLodging;
  }

  @override
  LodgingFacade get facade => clone();
}
