import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

import 'check_list_item.dart';

// ignore: must_be_immutable
class CheckListFacade extends Equatable implements TripEntity<CheckListFacade> {
  String? title;
  final List<CheckListItem> items;
  final String tripId;

  @override
  String? id;

  CheckListFacade(
      {required this.items, required this.tripId, this.title, this.id});

  CheckListFacade.newUiEntry(
      {required this.items, required this.tripId, this.title, this.id});

  CheckListFacade clone() => CheckListFacade(
      items: List.from(items.map((item) => item.clone())),
      tripId: tripId,
      title: title);

  @override
  List<Object?> get props => [title, items, tripId];

  @override
  bool validate() {
    return (title?.isNotEmpty ?? false) &&
        items.isNotEmpty &&
        items.every((item) => item.item.isNotEmpty);
  }
}
