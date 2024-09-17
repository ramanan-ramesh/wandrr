import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class RepositoryPattern<T> {
  String? id;

  DocumentReference get documentReference;

  Map<String, dynamic> toJson();

  FutureOr<bool> tryUpdate(T toUpdate);

  T get facade;

  T clone();
}

abstract interface class Dispose {
  Future dispose();
}
