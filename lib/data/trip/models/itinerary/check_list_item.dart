import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_list_item.freezed.dart';

/// Represents a single item in a checklist.
/// Uses freezed for immutability and copyWith support.
@freezed
class CheckListItem with _$CheckListItem {
  const CheckListItem._();

  const factory CheckListItem({
    required String item,
    required bool isChecked,
  }) = _CheckListItem;

  /// Create a new empty checklist item for forms
  factory CheckListItem.empty() =>
      const CheckListItem(item: '', isChecked: false);

  /// Validates the checklist item
  bool get isValid => item.isNotEmpty;
}
