import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/core/model_types.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

part 'sight.freezed.dart';

/// Represents a sight/attraction to visit on a specific day.
///
/// Uses freezed union types for draft/strict separation:
/// - [Sight.draft]: For forms where name can be empty
/// - [Sight.strict]: For persisted data where name is validated
@freezed
class Sight with _$Sight implements ExpenseLinkedTripEntity<Sight> {
  const Sight._();

  /// Draft constructor for forms
  const factory Sight.draft({
    required String tripId,
    required DateTime day,
    required Expense expense,
    String? id,
    @Default('') String name,
    Location? location,
    DateTime? visitTime,
    String? description,
  }) = SightDraft;

  /// Strict constructor for persisted data
  const factory Sight.strict({
    required String tripId,
    required String id,
    required DateTime day,
    required String name,
    required Expense expense,
    Location? location,
    DateTime? visitTime,
    String? description,
  }) = SightStrict;

  /// Creates a new sight entry for UI forms
  factory Sight.newEntry({
    required String tripId,
    required DateTime day,
    required String defaultCurrency,
    required Iterable<String> contributors,
  }) =>
      Sight.draft(
        tripId: tripId,
        day: day,
        expense: Expense.newEntry(
          tripId: tripId,
          defaultCurrency: defaultCurrency,
          allTripContributors: contributors,
          category: ExpenseCategory.sightseeing,
        ),
      );

  @override
  Sight clone() => copyWith();

  @override
  bool validate() => name.isNotEmpty && name.length >= 3;

  @override
  String toString() {
    var sightDescription = name;
    if (visitTime != null) {
      sightDescription += ' on ${visitTime!.dayDateMonthFormat}';
    }
    return sightDescription;
  }

  /// Convert to strict model after persistence
  SightStrict toStrict({required String id}) {
    return switch (this) {
      SightDraft(
        :final tripId,
        :final day,
        :final expense,
        :final name,
        :final location,
        :final visitTime,
        :final description,
      ) =>
        Sight.strict(
          tripId: tripId,
          id: id,
          day: day,
          name: name,
          expense: expense,
          location: location,
          visitTime: visitTime,
          description: description,
        ) as SightStrict,
      SightStrict() => this as SightStrict,
      _ => throw StateError('Unknown Sight type'),
    };
  }
}

// Legacy alias for backward compatibility
typedef SightFacade = Sight;
