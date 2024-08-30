import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/contracts/check_list.dart';
import 'package:wandrr/contracts/check_list_item.dart';
import 'package:wandrr/contracts/repository_pattern.dart';

class CheckListModelImplementation extends CheckListModelFacade
    implements RepositoryPattern<CheckListModelFacade> {
  static const _itemsField = 'items';
  static const _titleField = 'title';
  static const _itemField = 'item';
  static const _isCheckedField = 'status';

  @override
  CheckListModelFacade get facade => this;

  @override
  String? id;

  @override
  DocumentReference<Object?> get documentReference =>
      throw UnimplementedError();

  CheckListModelImplementation.fromModelFacade(
      {required CheckListModelFacade checkListModelFacade})
      : super(
            items: List.from(checkListModelFacade.items),
            title: checkListModelFacade.title,
            tripId: checkListModelFacade.tripId);

  @override
  Map<String, dynamic> toJson() {
    return {
      _titleField: title,
      _itemsField: items
          .map((checkListItem) => {
                _itemField: checkListItem.item,
                _isCheckedField: checkListItem.isChecked
              })
          .toList()
    };
  }

  @override
  Future<bool> tryUpdate(CheckListModelFacade toUpdate) async {
    return true;
  }

  static CheckListModelImplementation fromDocumentData(
      {required Map<String, dynamic> documentData, required String tripId}) {
    var items = List<Map<String, dynamic>>.from(documentData[_itemsField]).map(
        (e) =>
            CheckListItem(item: e[_itemField], isChecked: e[_isCheckedField]));
    return CheckListModelImplementation._(
        items: List.from(items),
        title: documentData[_titleField],
        tripId: tripId);
  }

  CheckListModelImplementation._(
      {required super.items, super.title, required super.tripId});
}
