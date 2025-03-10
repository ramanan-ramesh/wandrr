import 'package:equatable/equatable.dart';

import 'check_list_item.dart';

class CheckListFacade extends Equatable {
  String? title;
  final List<CheckListItem> items;
  final String tripId;

  CheckListFacade({this.title, required this.items, required this.tripId});

  CheckListFacade.newUiEntry(
      {this.title, required this.items, required this.tripId});

  CheckListFacade clone() {
    return CheckListFacade(
        items: List.from(items.map((item) => item.clone())),
        tripId: tripId,
        title: title);
  }

  @override
  List<Object?> get props => [title, items, tripId];
}
