import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';

import 'firestore_helpers.dart';
import 'location.dart';

abstract class TripMetadataModifier {
  Future<bool> updateTotalExpenditure(double amount);
}

class TripMetaData
    with EquatableMixin
    implements TripMetaDataFacade, TripMetadataModifier {
  @override
  final String id;

  @override
  DateTime get startDate => _startDate;
  static const String _startDateField = 'startDate';
  DateTime _startDate;

  @override
  DateTime get endDate => _endDate;
  static const String _endDateField = 'endDate';
  DateTime _endDate;

  @override
  String get name => _name;
  static const String _nameField = 'name';
  String _name;

  @override
  UnmodifiableListView<String> get contributors =>
      UnmodifiableListView<String>(_contributors);
  static const String _contributorsField = 'contributors';
  List<String> _contributors;

  @override
  final LocationFacade location;
  static const String _locationField = 'location';

  @override
  double get totalExpenditure => _totalExpenditure ?? 0;
  static const _totalExpenditureField = 'totalExpenditure';
  static const _defaultCurrency = 'INR';
  double? _totalExpenditure;

  @override
  CurrencyWithValue get budget =>
      _budget ?? CurrencyWithValue(currency: _defaultCurrency, amount: 0);
  static const _budgetField = 'budget';
  CurrencyWithValue? _budget;

  @override
  Future<bool> updateTotalExpenditure(double amount) async {
    var tripMetadataDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsMetadataCollection)
        .doc(id);

    if (amount == _totalExpenditure) {
      return true;
    }

    var didUpdate = false;
    await tripMetadataDocumentReference
        .set({_totalExpenditureField: amount}, SetOptions(merge: true)).then(
            (value) {
      didUpdate = true;
      _totalExpenditure = amount;
    }).onError((error, stackTrace) {
      didUpdate = false;
    });
    return didUpdate;
  }

  static Future<TripMetaData?> createFromUserInput(
      {required TripMetadataUpdator tripMetadataUpdator}) async {
    var tripMetadataCollection = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsMetadataCollection);
    var tripMetadata = TripMetaData._withoutId(
        startDate: tripMetadataUpdator.startDate!,
        endDate: tripMetadataUpdator.endDate!,
        name: tripMetadataUpdator.name!,
        location: tripMetadataUpdator.location!,
        contributors: tripMetadataUpdator.contributors!);
    try {
      var tripMetadataDocument =
          await tripMetadataCollection.add(tripMetadata._toJson());
      return TripMetaData._withId(
          startDate: tripMetadata.startDate,
          endDate: tripMetadata.endDate,
          name: tripMetadata.name,
          location: tripMetadata.location,
          id: tripMetadataDocument.id,
          contributors: tripMetadata.contributors,
          totalExpenditure: tripMetadata.totalExpenditure);
    } catch (exception) {
      return null;
    }
  }

  Future<bool> update(
      {required TripMetadataUpdator tripMetadataUpdator}) async {
    Map<String, dynamic> json = {};
    FirestoreHelpers.updateJson(
        _endDate, tripMetadataUpdator.endDate, _endDateField, json);
    FirestoreHelpers.updateJson(
        _startDate, tripMetadataUpdator.startDate, _startDateField, json);

    FirestoreHelpers.updateJson(_totalExpenditure,
        tripMetadataUpdator.totalExpenditure, _totalExpenditureField, json);
    FirestoreHelpers.updateJson(
        _budget, tripMetadataUpdator.budget, _budgetField, json);
    FirestoreHelpers.updateJson(_contributors, tripMetadataUpdator.contributors,
        _contributorsField, json);
    FirestoreHelpers.updateJson(
        _name, tripMetadataUpdator.name, _nameField, json);
    FirestoreHelpers.updateJson(
        _locationField, tripMetadataUpdator.location, _locationField, json);
    var didUpdate = json.isNotEmpty;
    await _getDocumentReference()
        .set(json, SetOptions(merge: true))
        .then((value) {
      didUpdate = true;
      _endDate = tripMetadataUpdator.endDate!;
      _startDate = tripMetadataUpdator.startDate!;
      _totalExpenditure = tripMetadataUpdator.totalExpenditure!;
      _name = tripMetadataUpdator.name!;
      _contributors = tripMetadataUpdator.contributors!;
      _budget = tripMetadataUpdator.budget;
    }).catchError((error, stackTrace) {
      didUpdate = false;
    });
    return didUpdate;
  }

  static TripMetaData fromDocumentSnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot) {
    var documentData = documentSnapshot.data();
    var startDateTime = (documentData[_startDateField] as Timestamp).toDate();
    var endDateTime = (documentData[_endDateField] as Timestamp).toDate();
    var location = Location.fromDocument(documentData[_locationField]);
    var contributors = List<String>.from(documentData[_contributorsField]);
    var budgetValue = documentData[_budgetField];
    CurrencyWithValue? budget;
    if (budgetValue != null) {
      budget = CurrencyWithValue.fromDocumentData(budgetValue);
    }
    return TripMetaData._withId(
        startDate: startDateTime,
        endDate: endDateTime,
        name: documentData[_nameField],
        location: location,
        id: documentSnapshot.id,
        totalExpenditure: documentData[_totalExpenditureField],
        contributors: contributors,
        budget: budget);
  }

  TripMetaData._withId(
      {required DateTime startDate,
      required DateTime endDate,
      required String name,
      required this.location,
      required this.id,
      required List<String> contributors,
      double? totalExpenditure,
      CurrencyWithValue? budget})
      : _startDate = startDate,
        _endDate = endDate,
        _name = name,
        _contributors = contributors,
        _totalExpenditure = totalExpenditure,
        _budget = budget;

  TripMetaData._withoutId(
      {required DateTime startDate,
      required DateTime endDate,
      required String name,
      required this.location,
      required List<String> contributors})
      : _startDate = startDate,
        _endDate = endDate,
        _name = name,
        _contributors = contributors,
        id = '';

  DocumentReference _getDocumentReference() {
    return FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsMetadataCollection)
        .doc(id);
  }

  Map<String, dynamic> _toJson() {
    return {
      _startDateField: Timestamp.fromDate(_startDate),
      _endDateField: Timestamp.fromDate(_endDate),
      _contributorsField: _contributors,
      _locationField: (location as Location).toJson(),
      _nameField: _name,
      _totalExpenditureField: _totalExpenditure
    };
  }

  @override
  List<Object?> get props => [
        _name,
        location,
        _contributors,
        _startDate,
        _endDate,
        id,
        _totalExpenditure
      ];
}

abstract class TripMetaDataFacade {
  String get id;

  DateTime get startDate;

  DateTime get endDate;

  String get name;

  UnmodifiableListView<String> get contributors;

  LocationFacade get location;

  double get totalExpenditure;

  CurrencyWithValue get budget;
}
