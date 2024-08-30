import 'package:equatable/equatable.dart';

import 'check_list_item.dart';

class CheckListModelFacade extends Equatable {
  String? title;
  List<CheckListItem> items;
  String tripId;

  CheckListModelFacade({this.title, required this.items, required this.tripId});

  CheckListModelFacade.newUiEntry(
      {this.title, required this.items, required this.tripId});

  void copyWith(CheckListModelFacade checkListModelFacade) {
    title = checkListModelFacade.title;
    items = List.from(
        checkListModelFacade.items.map((checkList) => checkList.clone()));
    tripId = checkListModelFacade.tripId;
  }

  CheckListModelFacade clone() {
    return CheckListModelFacade(
        items: List.from(items.map((item) => item.clone())),
        tripId: tripId,
        title: title);
  }

  @override
  List<Object?> get props => [title, items, tripId];
}
