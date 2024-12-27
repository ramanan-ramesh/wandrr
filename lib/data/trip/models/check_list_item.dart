import 'package:equatable/equatable.dart';

class CheckListItem extends Equatable {
  String item;

  bool isChecked;

  CheckListItem({required this.item, required this.isChecked});

  CheckListItem clone() {
    return CheckListItem(item: item, isChecked: isChecked);
  }

  @override
  List<Object?> get props => [item, isChecked];
}
