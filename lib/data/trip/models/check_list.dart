import 'package:equatable/equatable.dart';

import 'check_list_item.dart';

class CheckListFacade extends Equatable {
  String? title;
  List<CheckListItem> items;
  String tripId;

  CheckListFacade({this.title, required this.items, required this.tripId});

  CheckListFacade.newUiEntry(
      {this.title, required this.items, required this.tripId});

  void copyWith(CheckListFacade checkListModelFacade) {
    title = checkListModelFacade.title;
    items = List.from(
        checkListModelFacade.items.map((checkList) => checkList.clone()));
    tripId = checkListModelFacade.tripId;
  }

  CheckListFacade clone() {
    return CheckListFacade(
        items: List.from(items.map((item) => item.clone())),
        tripId: tripId,
        title: title);
  }

  @override
  List<Object?> get props => [title, items, tripId];
}
