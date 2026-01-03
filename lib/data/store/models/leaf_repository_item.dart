import 'package:cloud_firestore/cloud_firestore.dart';

/// Interface for repository items that can be stored in Firestore.
///
/// This interface provides the bridge between model layer and repository layer:
/// - [T] is the model type (e.g., Transit, Lodging, Expense)
/// - [id] is mutable to allow setting after Firestore add operation
/// - [documentReference] provides the Firestore path for this item
/// - [toJson] serializes the model for Firestore storage
/// - [facade] returns the model representation for UI consumption
abstract interface class LeafRepositoryItem<T> {
  /// The document ID in Firestore.
  /// May be null before persistence, non-null after.
  String? id;

  /// The Firestore document reference for this item.
  DocumentReference get documentReference;

  /// Converts this item to a JSON map for Firestore storage.
  Map<String, dynamic> toJson();

  /// Returns the model facade for UI consumption.
  T get facade;
}
