import 'package:equatable/equatable.dart';

import 'check_list_item.dart';

class CheckListFacade extends Equatable {
  String? title;
  final List<CheckListItem> items;
  final String tripId;

  CheckListFacade({required this.items, required this.tripId, this.title});

  CheckListFacade.newUiEntry(
      {required this.items, required this.tripId, this.title});

  CheckListFacade clone() => CheckListFacade(
      items: List.from(items.map((item) => item.clone())),
      tripId: tripId,
      title: title);

  @override
  List<Object?> get props => [title, items, tripId];
}
