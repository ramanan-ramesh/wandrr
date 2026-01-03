import 'package:freezed_annotation/freezed_annotation.dart';

import 'check_list_item.dart';

part 'check_list.freezed.dart';

/// Represents a checklist with items.
///
/// Uses freezed union types for draft/strict separation:
/// - [CheckList.draft]: For forms where title can be null
/// - [CheckList.strict]: For persisted data where title is required
@freezed
class CheckList with _$CheckList {
  const CheckList._();

  /// Draft constructor for forms - title is nullable
  const factory CheckList.draft({
    required String tripId,
    String? id,
    String? title,
    @Default([]) List<CheckListItem> items,
  }) = CheckListDraft;

  /// Strict constructor for persisted data - all required fields non-null
  const factory CheckList.strict({
    required String tripId,
    required String id,
    required String title,
    required List<CheckListItem> items,
  }) = CheckListStrict;

  /// Creates a new empty checklist for UI entry
  factory CheckList.newEntry({required String tripId}) => CheckList.draft(
        tripId: tripId,
        items: [CheckListItem.empty()],
      );

  /// Validates the checklist
  bool get isValid {
    return switch (this) {
      CheckListDraft(:final title, :final items) => title != null &&
          title.length >= 3 &&
          items.isNotEmpty &&
          items.every((item) => item.isValid),
      CheckListStrict(:final title, :final items) => title.length >= 3 &&
          items.isNotEmpty &&
          items.every((item) => item.isValid),
      _ => false,
    };
  }

  /// Converts draft to strict after persistence
  CheckListStrict toStrict({required String id}) {
    return switch (this) {
      CheckListDraft(:final tripId, :final title, :final items) =>
        CheckList.strict(
          tripId: tripId,
          id: id,
          title: title ?? '',
          items: items,
        ) as CheckListStrict,
      CheckListStrict() => this as CheckListStrict,
      _ => throw StateError('Unknown CheckList type'),
    };
  }
}

// Legacy alias for backward compatibility
typedef CheckListFacade = CheckList;
