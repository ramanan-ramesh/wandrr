import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:wandrr/contracts/communicators.dart';

import 'collection_names.dart';
import 'firestore_helpers.dart';

class CheckListItem extends Equatable {
  static const _itemField = 'item';
  String item;

  static const _isCheckedField = 'status';
  bool isChecked;

  CheckListItem.fromDocumentSnapshot(Map<String, dynamic> json)
      : item = json[_itemField],
        isChecked = json[_isCheckedField];

  Map<String, dynamic> toJson() {
    return {_itemField: _itemField, _isCheckedField: isChecked};
  }

  CheckListItem({required this.item, required this.isChecked});

  @override
  List<Object?> get props => [item, isChecked];
}

abstract class CheckListFacade extends Equatable {
  String? get title;
  UnmodifiableListView<CheckListItem> get items;
  String get id;
}

class CheckList with EquatableMixin implements CheckListFacade {
  static const _itemsField = 'items';
  List<CheckListItem> _items;
  @override
  UnmodifiableListView<CheckListItem> get items => UnmodifiableListView(_items);

  static const _titleField = 'title';
  String? _title;
  @override
  String? get title => _title;

  @override
  final String id;

  static Future<CheckListFacade?> createFromUserInput(
      {required CheckListUpdator checkListUpdator}) async {
    var checkListsCollection = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(checkListUpdator.tripId)
        .collection(FirestoreCollections.planDataListCollection)
        .doc(checkListUpdator.planDataId!)
        .collection(FirestoreCollections.checkListsCollection);
    var tempNoteObject = CheckList._create(
        id: '', title: checkListUpdator.title, items: checkListUpdator.items!);
    var checkListDocument =
        await checkListsCollection.add(tempNoteObject.toJson());
    return CheckList._create(
        id: checkListDocument.id,
        title: checkListUpdator.title,
        items: checkListUpdator.items!);
  }

  Future<bool> update({required CheckListUpdator checkListUpdator}) async {
    var checkListDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(checkListUpdator.tripId)
        .collection(FirestoreCollections.planDataListCollection)
        .doc(checkListUpdator.planDataId!)
        .collection(FirestoreCollections.checkListsCollection)
        .doc(checkListUpdator.id!);

    Map<String, dynamic> json = {};
    FirestoreHelpers.updateJson(
        _title, checkListUpdator.title, _titleField, json);
    FirestoreHelpers.updateJson(
        _items, checkListUpdator.items, _itemsField, json);
    return await FirestoreHelpers.tryUpdateDocumentField(
        documentReference: checkListDocumentReference,
        json: toJson(),
        onSuccess: () {
          _title = checkListUpdator.title;
          _items = checkListUpdator.items!;
        });
  }

  Map<String, dynamic> toJson() {
    return {_titleField: title, _itemsField: _items};
  }

  static CheckList fromDocumentSnapshot(
      {required QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot}) {
    return CheckList._create(
        items: List.from(documentSnapshot[_itemsField])
            .map((e) => CheckListItem.fromDocumentSnapshot(e))
            .toList(),
        id: documentSnapshot.id,
        title: documentSnapshot[_titleField]);
  }

  CheckList._create(
      {required List<CheckListItem> items, String? title, required this.id})
      : _title = title,
        _items = items;

  @override
  List<Object?> get props => [_items, _title, id];

  @override
  bool? get stringify => false;
}
