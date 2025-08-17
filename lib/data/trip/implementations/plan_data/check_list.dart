import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/models/plan_data/check_list.dart';
import 'package:wandrr/data/trip/models/plan_data/check_list_item.dart';

class CheckListModelImplementation extends CheckListFacade
    implements LeafRepositoryItem<CheckListFacade> {
  static const _itemsField = 'items';
  static const _titleField = 'title';
  static const _itemField = 'item';
  static const _isCheckedField = 'status';

  @override
  CheckListFacade get facade => clone();

  @override
  String? id;

  @override
  DocumentReference<Object?> get documentReference =>
      throw UnimplementedError();

  CheckListModelImplementation.fromModelFacade(
      {required CheckListFacade checkListModelFacade})
      : super(
            items: List.from(checkListModelFacade.items),
            title: checkListModelFacade.title,
            tripId: checkListModelFacade.tripId);

  @override
  Map<String, dynamic> toJson() => {
        _titleField: title,
        _itemsField: items
            .map((checkListItem) => {
                  _itemField: checkListItem.item,
                  _isCheckedField: checkListItem.isChecked
                })
            .toList()
      };

  @override
  Future<bool> tryUpdate(CheckListFacade toUpdate) async => true;

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
      {required super.items, required super.tripId, super.title});
}
