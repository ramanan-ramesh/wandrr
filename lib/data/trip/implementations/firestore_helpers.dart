import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wandrr/data/app/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/expense.dart';
import 'package:wandrr/data/trip/implementations/location.dart';
import 'package:wandrr/data/trip/models/expense.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/money.dart';
import 'package:wandrr/data/trip/models/transit.dart';

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

  static void updateJson(Object? currentValue, Object? valueToSet, String key,
      Map<String, dynamic> json) {
    var shouldWriteToJson = false;
    if (valueToSet is List && currentValue is List) {
      if (!(const ListEquality().equals(currentValue, valueToSet))) {
        shouldWriteToJson = true;
      }
    } else if (valueToSet is Map && currentValue is Map) {
      if (!mapEquals(currentValue, valueToSet)) {
        shouldWriteToJson = true;
      }
    }
    if (!(valueToSet == currentValue)) {
      currentValue = valueToSet;
      shouldWriteToJson = true;
    }
    if (shouldWriteToJson) {
      if (valueToSet is DateTime) {
        json[key] = (Timestamp.fromDate(valueToSet));
      } else if (valueToSet is Money) {
        json[key] = valueToSet.toString();
      } else if (valueToSet is LeafRepositoryItem) {
        json[key] = valueToSet.toJson();
      } else if (valueToSet is ExpenseCategory) {
        //Not required
        json[key] = valueToSet.name;
      } else if (valueToSet is TransitOption) {
        json[key] = valueToSet.name;
      } else if (valueToSet is Map<String, Money>) {
        json[key] = {
          for (var mapEntry in valueToSet.entries)
            mapEntry.key: mapEntry.value.toString()
        };
      } else if (valueToSet is List<LeafRepositoryItem>) {
        json[key] = List.generate(
            valueToSet.length, (index) => valueToSet.elementAt(index).toJson());
      } else if (valueToSet is LocationFacade) {
        json[key] = LocationModelImplementation.fromModelFacade(
                locationModelFacade: valueToSet, parentId: null)
            .toJson();
      } else if (valueToSet is ExpenseFacade) {
        json[key] = ExpenseModelImplementation.fromModelFacade(
                expenseModelFacade: valueToSet)
            .toJson();
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
