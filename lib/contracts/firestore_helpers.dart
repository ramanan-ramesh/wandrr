import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wandrr/contracts/check_list.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/location.dart';

class FirestoreHelpers {
  static Future<bool> tryUpdateDocumentField(
      {required DocumentReference documentReference,
      required Map<String, dynamic> json,
      Function? onSuccess}) async {
    var didErrorOccur = false;
    if (json.isEmpty) {
      return false;
    }
    await documentReference
        .set(json, SetOptions(merge: true))
        .then((value) => onSuccess?.call())
        .catchError((error, stackTrace) => didErrorOccur = true);
    return !didErrorOccur;
  }

  static Future<bool> tryDeleteDocumentReference(
      {required DocumentReference documentReference,
      Function? onSuccess}) async {
    var didErrorOccur = false;
    await documentReference
        .delete()
        .then((value) => onSuccess?.call())
        .catchError((error, stackTrace) => didErrorOccur = true);
    return !didErrorOccur;
  }

  static void updateJson(Object? currentValue, Object? valueToSet, String key,
      Map<String, dynamic> json) {
    var shouldWriteToJson = false;
    if (valueToSet is List && currentValue is List) {
      if (!(const ListEquality().equals(currentValue, valueToSet))) {
        shouldWriteToJson = true;
      }
      return;
    } else if (valueToSet is Map<String, CurrencyWithValue> &&
        currentValue is Map<String, CurrencyWithValue>) {
      if (!mapEquals(currentValue, valueToSet)) {
        shouldWriteToJson = true;
      }
    }
    if (!(valueToSet == currentValue)) {
      currentValue = valueToSet;
      shouldWriteToJson = true;
    }
    if (shouldWriteToJson) {
      if (valueToSet is Location) {
        json[key] = valueToSet.toJson();
      } else if (valueToSet is DateTime) {
        json[key] = (Timestamp.fromDate(valueToSet));
      } else if (valueToSet is CurrencyWithValue) {
        json[key] = valueToSet.toString();
      } else if (valueToSet is Expense) {
        json[key] = valueToSet.toJson();
      } else if (valueToSet is ExpenseCategory) {
        json[key] = valueToSet.name;
      } else if (valueToSet is Map<String, CurrencyWithValue>) {
        json[key] = {
          for (var mapEntry in valueToSet.entries)
            mapEntry.key: mapEntry.value.toString()
        };
      } else if (valueToSet is List<CheckListItem>) {
        json[key] = List.generate(
            valueToSet.length, (index) => valueToSet.elementAt(index).toJson());
      } else {
        json[key] = valueToSet;
      }
    }
  }

  static void updateJsonWithValue(Object? currentValue, Object? valueToCompare,
      String key, Object valueToSet, Map<String, dynamic> json) {
    if (valueToCompare is List? && currentValue is List?) {
      if (!(const ListEquality().equals(currentValue, valueToCompare))) {
        json[key] = valueToSet;
      }
      return;
    }
    if (!(valueToCompare == currentValue)) {
      json[key] = valueToSet;
    }
  }
}
