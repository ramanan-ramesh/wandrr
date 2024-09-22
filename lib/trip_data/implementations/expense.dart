import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/app_data/models/repository_pattern.dart';
import 'package:wandrr/trip_data/implementations/collection_names.dart';
import 'package:wandrr/trip_data/implementations/firestore_helpers.dart';
import 'package:wandrr/trip_data/models/expense.dart';
import 'package:wandrr/trip_data/models/money.dart';

import 'location.dart';

class ExpenseModelImplementation extends ExpenseFacade
    implements RepositoryPattern<ExpenseFacade> {
  static const _titleField = 'title';
  static const _descriptionField = 'description';
  static const _categoryField = 'category';
  static const _paidByField = 'paidBy';
  static const _splitByField = 'splitBy';
  static const _locationField = 'location';
  static const _totalExpenseField = 'totalExpense';
  static const _dateTimeField = 'dateTime';

  ExpenseModelImplementation.fromModelFacade(
      {required ExpenseFacade expenseModelFacade})
      : super(
            tripId: expenseModelFacade.tripId,
            title: expenseModelFacade.title,
            totalExpense: expenseModelFacade.totalExpense,
            paidBy: expenseModelFacade.paidBy,
            splitBy: expenseModelFacade.splitBy,
            description: expenseModelFacade.description,
            id: expenseModelFacade.id,
            location: expenseModelFacade.location == null
                ? null
                : LocationModelImplementation.fromModelFacade(
                    locationModelFacade: expenseModelFacade.location!),
            dateTime: expenseModelFacade.dateTime,
            category: expenseModelFacade.category);

  ExpenseModelImplementation(
      {required super.tripId,
      required super.title,
      required super.totalExpense,
      required super.category,
      required super.paidBy,
      required super.splitBy,
      super.description,
      super.id,
      LocationModelImplementation? location,
      super.dateTime})
      : super(location: location);

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripCollectionName)
      .doc(tripId)
      .collection(FirestoreCollections.expenseCollectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() {
    var json = {
      _totalExpenseField: totalExpense.toString(),
      _paidByField: paidBy,
      _locationField: (location as RepositoryPattern?)?.toJson(),
      _titleField: title,
      _categoryField: category.name,
      _descriptionField: description,
      _splitByField: splitBy,
    };
    if (dateTime != null) {
      json[_dateTimeField] = Timestamp.fromDate(dateTime!);
    }
    return json;
  }

  @override
  Future<bool> tryUpdate(ExpenseFacade toUpdate) async {
    Map<String, dynamic> json = {};
    FirestoreHelpers.updateJson(
        totalExpense, toUpdate.totalExpense, _totalExpenseField, json);
    FirestoreHelpers.updateJson(paidBy, toUpdate.paidBy, _paidByField, json);
    FirestoreHelpers.updateJson(
        dateTime, toUpdate.dateTime, _dateTimeField, json);
    FirestoreHelpers.updateJson(
        category.name, toUpdate.category.name, _categoryField, json);
    FirestoreHelpers.updateJson(splitBy, toUpdate.splitBy, _splitByField, json);
    FirestoreHelpers.updateJson(title, toUpdate.title, _titleField, json);
    FirestoreHelpers.updateJson(
        location, toUpdate.location, _locationField, json);
    FirestoreHelpers.updateJson(
        description, toUpdate.description, _descriptionField, json);

    var didUpdate = json.isNotEmpty;
    await documentReference.set(json, SetOptions(merge: true)).then((value) {
      didUpdate = true;
      copyWith(toUpdate);
    }).catchError((error, stackTrace) {
      didUpdate = false;
    });
    return didUpdate;
  }

  static ExpenseModelImplementation fromDocumentSnapshot(
      {required String tripId, required DocumentSnapshot documentSnapshot}) {
    var expenseValue = documentSnapshot[_totalExpenseField] as String;
    var expenseValues = expenseValue.split(' ');
    var cost = double.parse(expenseValues.first);
    var currency = expenseValues.elementAt(1);

    var category = ExpenseCategory.values.firstWhere(
        (element) => documentSnapshot[_categoryField] == element.name);

    Timestamp? dateTimeValue;
    var documentData = documentSnapshot.data() as Map<String, dynamic>;
    if (documentData.containsKey(_dateTimeField)) {
      if (documentSnapshot[_dateTimeField] != null) {
        dateTimeValue = documentSnapshot[_dateTimeField] as Timestamp;
      }
    }

    List<String> splitBy = List.from(documentSnapshot[_splitByField]);

    LocationModelImplementation? location;
    if (documentData.containsKey(_locationField)) {
      if (documentSnapshot[_locationField] != null) {
        location = LocationModelImplementation.fromJson(
            json: documentSnapshot[_locationField], tripId: tripId);
      }
    }

    return ExpenseModelImplementation(
        totalExpense: Money(currency: currency, amount: cost),
        tripId: tripId,
        paidBy: Map.from(documentSnapshot[_paidByField]),
        dateTime: dateTimeValue?.toDate(),
        category: category,
        splitBy: splitBy,
        id: documentSnapshot.id,
        title: documentSnapshot[_titleField],
        location: location,
        description: documentSnapshot[_descriptionField]);
  }

  static ExpenseModelImplementation fromJson(
      {required String tripId, required Map<String, dynamic> json}) {
    var expenseValue = json[_totalExpenseField] as String;
    var expenseValues = expenseValue.split(' ');
    var cost = double.parse(expenseValues.first);
    var currency = expenseValues.elementAt(1);

    var category = ExpenseCategory.values
        .firstWhere((element) => json[_categoryField] == element.name);

    Timestamp? dateTimeValue;
    if (json.containsKey(_dateTimeField)) {
      if (json[_dateTimeField] != null) {
        dateTimeValue = json[_dateTimeField] as Timestamp;
      }
    }

    List<String> splitBy = List.from(json[_splitByField]);

    LocationModelImplementation? location;
    if (json.containsKey(_locationField)) {
      if (json[_locationField] != null) {
        location = LocationModelImplementation.fromJson(
            json: json[_locationField], tripId: tripId);
      }
    }

    var paidByValue = Map<String, dynamic>.from(json[_paidByField]);
    var paidBy = <String, double>{};
    for (var paidByEntry in paidByValue.entries) {
      var amount = paidByEntry.value;
      paidBy[paidByEntry.key] = double.parse(amount.toString());
    }

    return ExpenseModelImplementation(
        totalExpense: Money(currency: currency, amount: cost),
        tripId: tripId,
        paidBy: paidBy,
        dateTime: dateTimeValue?.toDate(),
        category: category,
        splitBy: splitBy,
        title: json[_titleField],
        location: location,
        description: json[_descriptionField]);
  }

  @override
  ExpenseFacade get facade => clone();
}
