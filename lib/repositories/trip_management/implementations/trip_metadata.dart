import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/firestore_helpers.dart';
import 'package:wandrr/contracts/repository_pattern.dart';
import 'package:wandrr/contracts/trip_metadata.dart';

class TripMetadataModelImplementation extends TripMetadataModelFacade
    implements RepositoryPattern<TripMetadataModelFacade> {
  static const String _startDateField = 'startDate';
  static const String _endDateField = 'endDate';
  static const String _nameField = 'name';
  static const String _contributorsField = 'contributors';
  static const _totalExpenditureField = 'totalExpenditure';
  static const _budgetField = 'budget';
  static const _defaultCurrency = 'INR';

  @override
  DocumentReference get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripsMetadataCollection)
      .doc(id);

  //TODO: Id not expected to be valid. This is just to add ModelFacade object to DB.
  TripMetadataModelImplementation.fromModelFacade(
      {required TripMetadataModelFacade tripMetadataModelFacade})
      : super(
            id: tripMetadataModelFacade.id,
            startDate: tripMetadataModelFacade.startDate,
            endDate: tripMetadataModelFacade.endDate,
            name: tripMetadataModelFacade.name,
            contributors: List.from(tripMetadataModelFacade.contributors),
            totalExpenditure: tripMetadataModelFacade.totalExpenditure,
            budget: tripMetadataModelFacade.budget);

  static TripMetadataModelImplementation fromDocumentSnapshot(
      DocumentSnapshot documentSnapshot) {
    var documentData = documentSnapshot.data() as Map<String, dynamic>;
    var startDateTime = (documentData[_startDateField] as Timestamp).toDate();
    var endDateTime = (documentData[_endDateField] as Timestamp).toDate();
    var contributors = List<String>.from(documentData[_contributorsField]);
    var budgetValue = documentData[_budgetField] as String?;
    CurrencyWithValue budget;
    if (budgetValue != null && budgetValue.isNotEmpty) {
      budget = CurrencyWithValue.fromDocumentData(budgetValue);
    } else {
      budget = CurrencyWithValue(currency: _defaultCurrency, amount: 0);
    }
    return TripMetadataModelImplementation._(
        id: documentSnapshot.id,
        startDate: startDateTime,
        endDate: endDateTime,
        name: documentData[_nameField],
        contributors: contributors,
        totalExpenditure: documentData[_totalExpenditureField],
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
      _totalExpenditureField: totalExpenditure,
      _budgetField: budget.toString()
    };
  }

  @override
  Future<bool> tryUpdate(TripMetadataModelFacade toUpdate) async {
    Map<String, dynamic> json = {};
    FirestoreHelpers.updateJson(endDate, toUpdate.endDate, _endDateField, json);
    FirestoreHelpers.updateJson(
        startDate, toUpdate.startDate, _startDateField, json);
    FirestoreHelpers.updateJson(totalExpenditure, toUpdate.totalExpenditure,
        _totalExpenditureField, json);
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
  TripMetadataModelFacade get facade => clone();

  TripMetadataModelImplementation._(
      {required super.id,
      required super.startDate,
      required super.endDate,
      required super.name,
      required super.contributors,
      required super.totalExpenditure,
      required super.budget});
}
