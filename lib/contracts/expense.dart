import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/firestore_helpers.dart';
import 'package:wandrr/contracts/location.dart';

class CurrencyWithValue extends Equatable {
  String currency;
  double amount;

  CurrencyWithValue({required this.currency, required this.amount});

  static CurrencyWithValue fromDocumentData(String documentData) {
    var splittedStrings = documentData.split(' ');
    return CurrencyWithValue(
        currency: splittedStrings.elementAt(1),
        amount: double.parse(splittedStrings.first));
  }

  @override
  String toString() {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  @override
  List<Object?> get props => [currency, amount];
}

abstract class ExpenseFacade {
  String get tripId;

  String get title;

  String? get description;

  String? get id;

  CurrencyWithValue get totalExpense;

  ExpenseCategory get category;

  Map<String, double> get paidBy;

  List<String> get splitBy;

  LocationFacade? get location;

  DateTime? get dateTime;
}

// TODO: If new member is added, should he automatically share all expenses
class Expense with EquatableMixin implements ExpenseFacade {
  @override
  String tripId;

  @override
  String? id;

  @override
  String get title => _title ?? '';
  String? _title;
  static const _titleField = 'title';

  @override
  String? get description => _description;
  String? _description;
  static const _descriptionField = 'description';

  @override
  ExpenseCategory get category => _category ?? _defaultCategory;
  ExpenseCategory _category;
  static const _categoryField = 'category';
  static const _defaultCategory = ExpenseCategory.Other;

  @override
  Map<String, double> get paidBy => _paidBy;
  Map<String, double> _paidBy;
  static const _paidByField = 'paidBy';

  @override
  List<String> get splitBy => _splitBy ?? [];
  List<String>? _splitBy;
  static const _splitByField = 'splitBy';

  @override
  LocationFacade? get location => _location;
  Location? _location;
  static const _locationField = 'location';

  @override
  CurrencyWithValue get totalExpense => _totalExpense;
  CurrencyWithValue _totalExpense;
  static const _totalExpenseField = 'totalExpense';

  @override
  DateTime? get dateTime => _dateTime;
  DateTime? _dateTime;
  static const _dateTimeField = 'dateTime';

  Expense.createLinkedExpense(
      {required CurrencyWithValue totalExpense,
      required String tripId,
      required Map<String, double> paidBy,
      DateTime? dateTime,
      required ExpenseCategory category,
      required List<String> splitBy,
      String? title,
      Location? location,
      String? description})
      : this.create(
            totalExpense: totalExpense,
            tripId: tripId,
            paidBy: paidBy,
            category: category,
            splitBy: splitBy,
            title: title,
            dateTime: dateTime,
            description: description);

  static Future<Expense?> createFromUserInput(
      {required ExpenseUpdator expenseUpdator}) async {
    var expense = Expense.create(
        tripId: expenseUpdator.tripId,
        totalExpense: expenseUpdator.totalExpense!,
        paidBy: expenseUpdator.paidBy!,
        splitBy: expenseUpdator.splitBy!,
        category: expenseUpdator.category!,
        dateTime: expenseUpdator.dateTime,
        location: expenseUpdator.location as Location?,
        title: expenseUpdator.title!,
        description: expenseUpdator.description);
    var expensesCollectionReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(expenseUpdator.tripId)
        .collection(FirestoreCollections.expensesCollection);
    try {
      var expenseDocument =
          await expensesCollectionReference.add(expense.toJson());
      expense.id = expenseDocument.id;
      return expense;
    } catch (Exception) {
      return null;
    }
  }

  static Expense fromDocumentSnapshot(
      {required String tripId,
      required QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot}) {
    var expenseValue = documentSnapshot[_totalExpenseField] as String;
    var expenseValues = expenseValue.split(' ');
    var cost = double.parse(expenseValues.first);
    var currency = expenseValues.elementAt(1);

    var category = ExpenseCategory.values.firstWhere(
        (element) => documentSnapshot[_categoryField] == element.name);

    Timestamp? dateTimeValue;
    if (documentSnapshot.data().containsKey(_dateTimeField)) {
      if (documentSnapshot[_dateTimeField] != null) {
        dateTimeValue = documentSnapshot[_dateTimeField] as Timestamp;
      }
    }

    List<String> splitBy = List.from(documentSnapshot[_splitByField]);

    Location? location;
    if (documentSnapshot.data().containsKey(_locationField)) {
      if (documentSnapshot[_locationField] != null) {
        location = Location.fromDocument(documentSnapshot[_locationField]);
      }
    }

    return Expense.create(
        totalExpense: CurrencyWithValue(currency: currency, amount: cost),
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

  static Expense fromLinkedDocument(
      String tripId, Map<String, dynamic> linkedDocument) {
    var expenseValue = linkedDocument[_totalExpenseField] as String;
    var expenseValues = expenseValue.split(' ');
    var cost = double.parse(expenseValues.first);
    var currency = expenseValues.elementAt(1);

    var category = ExpenseCategory.values.firstWhere(
        (element) => linkedDocument[_categoryField] == element.name);

    var dateTimeValue = linkedDocument[_dateTimeField] as Timestamp?;

    List<String> splitBy = [];
    splitBy.addAll(List.from(linkedDocument[_splitByField]) ?? []);

    var locationValue = linkedDocument[_locationField];
    var location =
        locationValue == null ? null : Location.fromDocument(locationValue);

    return Expense.create(
        totalExpense: CurrencyWithValue(currency: currency, amount: cost),
        tripId: tripId,
        paidBy: Map.from(linkedDocument[_paidByField]),
        dateTime: dateTimeValue?.toDate(),
        category: category,
        splitBy: splitBy,
        location: location,
        description: linkedDocument[_descriptionField]);
  }

  //TODO: Updating a transit or lodging related expense will not work
  Future<bool> update({required ExpenseUpdator expenseUpdator}) async {
    Map<String, dynamic> json = {};
    FirestoreHelpers.updateJson(
        _totalExpense, expenseUpdator.totalExpense, _totalExpenseField, json);
    FirestoreHelpers.updateJson(
        _paidBy, expenseUpdator.paidBy, _paidByField, json);
    FirestoreHelpers.updateJson(
        _dateTime, expenseUpdator.dateTime, _dateTimeField, json);
    FirestoreHelpers.updateJson(
        _category, expenseUpdator.category, _categoryField, json);
    FirestoreHelpers.updateJson(
        _splitBy, expenseUpdator.splitBy, _splitByField, json);
    FirestoreHelpers.updateJson(
        _title, expenseUpdator.title, _titleField, json);
    FirestoreHelpers.updateJson(
        _location, expenseUpdator.location, _locationField, json);
    FirestoreHelpers.updateJson(
        _description, expenseUpdator.description, _descriptionField, json);

    var didUpdate = json.isNotEmpty;
    await _getDocumentReference()
        .set(json, SetOptions(merge: true))
        .then((value) {
      didUpdate = true;
      _totalExpense = expenseUpdator.totalExpense!;
      _paidBy = expenseUpdator.paidBy!;
      _dateTime = expenseUpdator.dateTime;
      _category = expenseUpdator.category!;
      _splitBy = expenseUpdator.splitBy!;
      _title = expenseUpdator.title;
      _location = expenseUpdator.location != null
          ? (expenseUpdator.location as Location)
          : null;
      _description = expenseUpdator.description;
    }).catchError((error, stackTrace) {
      didUpdate = false;
    });
    return didUpdate;
  }

  Map<String, dynamic> toJson() {
    var json = {
      _totalExpenseField: _totalExpense.toString(),
      _paidByField: _paidBy,
      _locationField: _location?.toJson(),
      _titleField: _title,
      _categoryField: _category.name,
      _descriptionField: _description,
      _splitByField: _splitBy,
    };
    if (_dateTime != null) {
      json[_dateTimeField] = Timestamp.fromDate(_dateTime!);
    }
    return json;
  }

  //TODO: Accept CurrencyWithvalue rather than cost and currency?
  Expense.create(
      {required CurrencyWithValue totalExpense,
      required this.tripId,
      required Map<String, double> paidBy,
      DateTime? dateTime,
      required ExpenseCategory category,
      required List<String> splitBy,
      this.id,
      String? title,
      Location? location,
      String? description})
      : _totalExpense = totalExpense,
        _title = title,
        _dateTime = dateTime,
        _location = location,
        _splitBy = splitBy,
        _description = description,
        _category = category,
        _paidBy = paidBy;

  DocumentReference _getDocumentReference() {
    return FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(tripId)
        .collection(FirestoreCollections.expensesCollection)
        .doc(id);
  }

  @override
  List<Object?> get props =>
      [title, id, tripId, _paidBy, _category, _totalExpense, _location];
}

enum ExpenseCategory {
  Other,
  Flights,
  Lodging,
  CarRental,
  PublicTransit,
  Food,
  Drinks,
  Sightseeing,
  Activities,
  Shopping,
  Fuel,
  Groceries
}
