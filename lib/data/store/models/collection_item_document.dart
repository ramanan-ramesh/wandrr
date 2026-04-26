import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class CollectionItem<T> {
  Map<String, dynamic> toJson();

  T get facade;
}

abstract interface class CollectionDocument<T> extends CollectionItem<T> {
  String? id;

  DocumentReference get documentReference;
}
