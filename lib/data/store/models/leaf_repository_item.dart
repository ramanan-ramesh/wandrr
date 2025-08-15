import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class LeafRepositoryItem<T> {
  String? id;

  DocumentReference get documentReference;

  Map<String, dynamic> toJson();

  FutureOr<bool> tryUpdate(T toUpdate);

  T get facade;
}

abstract interface class Dispose {
  Future dispose();
}
