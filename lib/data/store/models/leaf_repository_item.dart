import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class LeafRepositoryItem<T> {
  Map<String, dynamic> toJson();

  T get facade;
}

abstract interface class RepositoryDocument<T> extends LeafRepositoryItem<T> {
  String? id;

  DocumentReference get documentReference;
}
