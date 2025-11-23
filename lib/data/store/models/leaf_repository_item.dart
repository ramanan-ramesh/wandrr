import 'package:cloud_firestore/cloud_firestore.dart';

//TODO: Consider extending T, so that every class that implements LeafRepositoryItem also implements T implicitly.
abstract interface class LeafRepositoryItem<T> {
  String? id;

  DocumentReference get documentReference;

  Map<String, dynamic> toJson();

  T get facade;
}
