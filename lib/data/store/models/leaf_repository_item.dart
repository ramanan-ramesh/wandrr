import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class LeafRepositoryItem<T> {
  String? id;

  DocumentReference get documentReference;

  Map<String, dynamic> toJson();

  T get facade;
}
