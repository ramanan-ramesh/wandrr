import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';

class ExpenseModelImplementation extends ExpenseFacade
    implements LeafRepositoryItem<ExpenseFacade> {
  static const _currencyField = 'currency';
  static const _paidByField = 'paidBy';
  static const _splitByField = 'splitBy';
  static const _dateTimeField = 'dateTime';
  static const _descriptionField = 'description';

  ExpenseModelImplementation.fromModelFacade(
      {required ExpenseFacade expenseModelFacade})
      : super(
            currency: expenseModelFacade.currency,
            paidBy: expenseModelFacade.paidBy,
            splitBy: expenseModelFacade.splitBy,
            description: expenseModelFacade.description,
            dateTime: expenseModelFacade.dateTime);

  static ExpenseModelImplementation fromJson(Map<String, dynamic> json) {
    var currency = json[_currencyField] as String;
    var splitBy = List<String>.from(json[_splitByField]);
    var paidBy = <String, double>{};
    for (final paidByEntry in json[_paidByField].entries) {
      var amount = paidByEntry.value;
      paidBy[paidByEntry.key] = double.parse(amount.toString());
    }
    Timestamp? dateTimeValue;
    if (json.containsKey(_dateTimeField)) {
      if (json[_dateTimeField] != null) {
        dateTimeValue = json[_dateTimeField] as Timestamp;
      }
    }
    return ExpenseModelImplementation._(
        currency: currency,
        paidBy: paidBy,
        splitBy: splitBy,
        description: json[_descriptionField],
        dateTime: dateTimeValue?.toDate());
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      _currencyField: currency,
      _paidByField: paidBy,
      _splitByField: splitBy,
      if (description != null && description!.isNotEmpty)
        _descriptionField: description,
      if (dateTime != null) _dateTimeField: Timestamp.fromDate(dateTime!),
    };
  }

  @override
  ExpenseFacade get facade => clone();

  ExpenseModelImplementation._({
    required super.currency,
    required super.paidBy,
    required super.splitBy,
    super.description,
    super.dateTime,
  });
}

class StandaloneExpenseModelImplementation extends StandaloneExpense
    implements RepositoryDocument<StandaloneExpense> {
  static const _titleField = 'title';
  static const _categoryField = 'category';

  StandaloneExpenseModelImplementation.fromModelFacade(
      {required StandaloneExpense expenseModelFacade})
      : super(
            tripId: expenseModelFacade.tripId,
            expense: ExpenseModelImplementation.fromModelFacade(
                expenseModelFacade: expenseModelFacade.expense),
            title: expenseModelFacade.title,
            id: expenseModelFacade.id,
            category: expenseModelFacade.category);

  static StandaloneExpenseModelImplementation fromDocumentSnapshot(
      {required String tripId, required DocumentSnapshot documentSnapshot}) {
    var documentData = documentSnapshot.data() as Map<String, dynamic>;
    var category = ExpenseCategory.values
        .firstWhere((element) => documentData[_categoryField] == element.name);

    return StandaloneExpenseModelImplementation._(
        tripId: tripId,
        category: category,
        id: documentSnapshot.id,
        title: documentData[_titleField],
        expense: ExpenseModelImplementation.fromJson(documentData));
  }

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripCollectionName)
      .doc(tripId)
      .collection(FirestoreCollections.expenseCollectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() {
    return {
      if (title.isNotEmpty) _titleField: title,
      _categoryField: category.name,
      ...(expense as LeafRepositoryItem).toJson(),
    };
  }

  static StandaloneExpenseModelImplementation fromJson(
      {required String tripId, required Map<String, dynamic> json}) {
    var category = ExpenseCategory.values
        .firstWhere((element) => json[_categoryField] == element.name);

    return StandaloneExpenseModelImplementation._(
        tripId: tripId,
        category: category,
        title: json[_titleField] ?? '',
        expense: ExpenseModelImplementation.fromJson(json));
  }

  @override
  StandaloneExpense get facade => clone();

  StandaloneExpenseModelImplementation._({
    required super.tripId,
    required super.title,
    required super.category,
    required super.expense,
    super.id,
  });
}
