import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/firestore_helpers.dart';
import 'package:wandrr/data/trip/models/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

class TripMetadataModelImplementation extends TripMetadataFacade
    implements LeafRepositoryItem<TripMetadataFacade> {
  static const String _startDateField = 'startDate';
  static const String _endDateField = 'endDate';
  static const String _nameField = 'name';
  static const String _contributorsField = 'contributors';
  static const _budgetField = 'budget';
  static const _defaultCurrency = 'INR';

  @override
  DocumentReference get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripMetadataCollectionName)
      .doc(id);

  //TODO: Id not expected to be valid. This is just to add ModelFacade object to DB.
  TripMetadataModelImplementation.fromModelFacade(
      {required TripMetadataFacade tripMetadataModelFacade})
      : super(
            id: tripMetadataModelFacade.id,
            startDate: tripMetadataModelFacade.startDate,
            endDate: tripMetadataModelFacade.endDate,
            name: tripMetadataModelFacade.name,
            contributors: List.from(tripMetadataModelFacade.contributors),
            budget: tripMetadataModelFacade.budget);

  static TripMetadataModelImplementation fromDocumentSnapshot(
      DocumentSnapshot documentSnapshot) {
    var documentData = documentSnapshot.data() as Map<String, dynamic>;
    var startDateTime = (documentData[_startDateField] as Timestamp).toDate();
    var endDateTime = (documentData[_endDateField] as Timestamp).toDate();
    var contributors = List<String>.from(documentData[_contributorsField]);
    var budgetValue = documentData[_budgetField] as String?;
    Money budget;
    if (budgetValue != null && budgetValue.isNotEmpty) {
      budget = Money.fromDocumentData(budgetValue);
    } else {
      budget = Money(currency: _defaultCurrency, amount: 0);
    }

    return TripMetadataModelImplementation._(
        id: documentSnapshot.id,
        startDate: startDateTime,
        endDate: endDateTime,
        name: documentData[_nameField],
        contributors: contributors,
        budget: budget);
  }

  //expects a valid database object
  @override
  Map<String, dynamic> toJson() {
    return {
      _startDateField: Timestamp.fromDate(startDate!),
      _endDateField: Timestamp.fromDate(endDate!),
      _contributorsField: contributors,
      _nameField: name,
      _budgetField: budget.toString()
    };
  }

  @override
  Future<bool> tryUpdate(TripMetadataFacade toUpdate) async {
    Map<String, dynamic> json = {};
    FirestoreHelpers.updateJson(endDate, toUpdate.endDate, _endDateField, json);
    FirestoreHelpers.updateJson(
        startDate, toUpdate.startDate, _startDateField, json);
    FirestoreHelpers.updateJson(budget, toUpdate.budget, _budgetField, json);
    FirestoreHelpers.updateJson(
        contributors, toUpdate.contributors, _contributorsField, json);
    FirestoreHelpers.updateJson(name, toUpdate.name, _nameField, json);
    var didUpdate = json.isNotEmpty;
    if (json.isNotEmpty) {
      await documentReference.set(json, SetOptions(merge: true)).then((value) {
        didUpdate = true;
        copyWith(toUpdate);
      }).catchError((error, stackTrace) {
        didUpdate = false;
      });
    }
    return didUpdate;
  }

  @override
  TripMetadataFacade get facade => clone();

  TripMetadataModelImplementation._(
      {required super.id,
      required super.startDate,
      required super.endDate,
      required super.name,
      required super.contributors,
      required super.budget});
}
