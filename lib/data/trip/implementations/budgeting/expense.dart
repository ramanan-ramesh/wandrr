import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/firestore_helpers.dart';
import 'package:wandrr/data/trip/implementations/location.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';

class ExpenseModelImplementation extends ExpenseFacade
    implements LeafRepositoryItem<ExpenseFacade> {
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

  static ExpenseModelImplementation fromDocumentSnapshot(
      {required String tripId, required DocumentSnapshot documentSnapshot}) {
    var documentData = documentSnapshot.data() as Map<String, dynamic>;
    var expenseValue = documentData[_totalExpenseField] as String;
    var expenseValues = expenseValue.split(' ');
    var cost = double.parse(expenseValues.first);
    var currency = expenseValues.elementAt(1);

    var category = ExpenseCategory.values
        .firstWhere((element) => documentData[_categoryField] == element.name);

    var dateTimeValue = documentData.containsKey(_dateTimeField)
        ? documentData[_dateTimeField] as Timestamp
        : null;

    var splitBy = List<String>.from(documentData[_splitByField]);

    var location = documentData.containsKey(_locationField)
        ? null
        : LocationModelImplementation.fromJson(
            json: documentData[_locationField], tripId: tripId);

    var paidBy = <String, double>{};
    for (final paidByEntry in documentData[_paidByField].entries) {
      var amount = paidByEntry.value;
      paidBy[paidByEntry.key] = double.parse(amount.toString());
    }

    return ExpenseModelImplementation._(
        totalExpense: Money(currency: currency, amount: cost),
        tripId: tripId,
        paidBy: paidBy,
        dateTime: dateTimeValue?.toDate(),
        category: category,
        splitBy: splitBy,
        id: documentSnapshot.id,
        title: documentData[_titleField],
        location: location,
        description: documentData.containsKey(_descriptionField)
            ? documentData[_descriptionField]
            : null);
  }

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
      _locationField: (location as LeafRepositoryItem?)?.toJson(),
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
    var json = <String, dynamic>{};
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

    return await FirestoreHelpers.tryUpdateDocumentField(
        documentReference: documentReference,
        json: json,
        onSuccess: () {
          copyWith(toUpdate);
        });
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

    var splitBy = List<String>.from(json[_splitByField]);

    LocationModelImplementation? location;
    if (json.containsKey(_locationField)) {
      if (json[_locationField] != null) {
        location = LocationModelImplementation.fromJson(
            json: json[_locationField], tripId: tripId);
      }
    }

    var paidByValue = Map<String, dynamic>.from(json[_paidByField]);
    var paidBy = <String, double>{};
    for (final paidByEntry in paidByValue.entries) {
      var amount = paidByEntry.value;
      paidBy[paidByEntry.key] = double.parse(amount.toString());
    }

    return ExpenseModelImplementation._(
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

  ExpenseModelImplementation._(
      {required super.tripId,
      required super.title,
      required super.totalExpense,
      required super.category,
      required super.paidBy,
      required super.splitBy,
      super.description,
      super.id,
      super.location,
      super.dateTime});
}
