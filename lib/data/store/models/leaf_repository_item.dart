import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

//TODO: Consider extending T, so that every class that implements LeafRepositoryItem also implements T implicitly.
// Right no, all implementations of LeafRepositoryItem also implement T.
abstract interface class LeafRepositoryItem<T> {
  String? id;

  DocumentReference get documentReference;

  Map<String, dynamic> toJson();

  FutureOr<bool> tryUpdate(T toUpdate);

  T get facade;
}
