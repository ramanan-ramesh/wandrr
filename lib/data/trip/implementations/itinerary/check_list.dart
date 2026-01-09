import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list_item.dart';

// ignore: must_be_immutable
class CheckListModelImplementation extends CheckListFacade
    implements LeafRepositoryItem<CheckListFacade> {
  static const _itemsField = 'items';
  static const _titleField = 'title';
  static const _itemField = 'item';
  static const _isCheckedField = 'status';

  CheckListModelImplementation.fromModelFacade(
      CheckListFacade checkListModelFacade)
      : super(
            items: List.from(checkListModelFacade.items),
            title: checkListModelFacade.title!,
            tripId: checkListModelFacade.tripId);

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

  @override
  CheckListFacade get facade => clone();

  @override
  String? id;

  @override
  Map<String, dynamic> toJson() {
    return {
      _titleField: title!,
      _itemsField: items.where((item) => item.item.isNotEmpty).map(
          (checkListItem) => <String, dynamic>{
                _itemField: checkListItem.item,
                _isCheckedField: checkListItem.isChecked
              })
    };
  }

  CheckListModelImplementation._(
      {required super.items,
      required super.tripId,
      required String super.title});
}
