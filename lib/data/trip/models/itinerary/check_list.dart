import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';

import 'check_list_item.dart';

// ignore: must_be_immutable
class CheckListFacade extends Equatable
    implements TripEntity<CheckListValidationError> {
  String? title;
  final List<CheckListItem> items;
  final String tripId;

  @override
  String? id;

  CheckListFacade(
      {required this.items, required this.tripId, this.title, this.id});

  CheckListFacade.newUiEntry(
      {required this.items, required this.tripId, this.title, this.id});

  @override
  CheckListFacade clone() => CheckListFacade(
      items: List.from(items.map((item) => item.clone())),
      tripId: tripId,
      title: title);

  @override
  List<Object?> get props => [title, items, tripId];

  @override
  Iterable<CheckListValidationError> getValidationErrors() {
    final errors = <CheckListValidationError>[];
    if (title == null || title!.isEmpty) {
      errors.add(CheckListValidationError.missingTitle);
    }
    if (items.isEmpty) {
      errors.add(CheckListValidationError.itemsEmpty);
    } else if (items.any((item) => item.item.isEmpty)) {
      errors.add(CheckListValidationError.itemEmpty);
    }
    return errors;
  }
}
