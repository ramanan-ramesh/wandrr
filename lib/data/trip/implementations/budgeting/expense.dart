import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/firestore_converters.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';

/// Repository implementation for Expense model.
/// Wraps Expense model with Firestore-specific serialization.
// ignore: must_be_immutable
class ExpenseRepositoryItem implements LeafRepositoryItem<Expense> {
  final Expense _expense;

  @override
  String? id;

  ExpenseRepositoryItem.fromModel(Expense expense)
      : _expense = expense,
        id = expense.id;

  /// Factory constructor for creating from a model facade
  factory ExpenseRepositoryItem.fromModelFacade({
    required Expense expenseModelFacade,
  }) {
    return ExpenseRepositoryItem.fromModel(expenseModelFacade);
  }

  static ExpenseRepositoryItem fromDocumentSnapshot({
    required String tripId,
    required DocumentSnapshot documentSnapshot,
  }) {
    final documentData = documentSnapshot.data() as Map<String, dynamic>;
    final expense = ExpenseFirestoreConverter.fromFirestore(
      documentData,
      tripId,
      id: documentSnapshot.id,
    );
    return ExpenseRepositoryItem.fromModel(expense);
  }

  /// Creates from JSON (for embedded expenses in transit/lodging)
  static ExpenseRepositoryItem fromJson({
    required String tripId,
    required Map<String, dynamic> json,
  }) {
    final expense = ExpenseFirestoreConverter.fromFirestore(json, tripId);
    return ExpenseRepositoryItem.fromModel(expense);
  }

  @override
  DocumentReference<Object?> get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripCollectionName)
      .doc(_expense.tripId)
      .collection(FirestoreCollections.expenseCollectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() =>
      ExpenseFirestoreConverter.toFirestore(_expense);

  @override
  Expense get facade {
    if (id != null) {
      return _expense.copyWith(id: id!);
    }
    return _expense;
  }
}

// Legacy alias for backward compatibility
typedef ExpenseModelImplementation = ExpenseRepositoryItem;
