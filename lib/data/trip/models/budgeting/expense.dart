import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wandrr/data/trip/models/core/model_types.dart';

import 'expense_category.dart';
import 'money.dart';

part 'expense.freezed.dart';

/// Represents an expense in a trip.
///
/// Uses freezed union types for draft/strict separation:
/// - [Expense.draft]: For forms where some fields can be nullable
/// - [Expense.strict]: For persisted data where required fields are non-null
///
/// Note: Expense implements ExpenseLinkedTripEntity where expense returns itself.
/// This allows standalone expenses to be used alongside entities that contain expenses.
@freezed
class Expense
    with _$Expense
    implements TripEntity<Expense>, ExpenseLinkedTripEntity<Expense> {
  const Expense._();

  /// The expense is itself (for ExpenseLinkedTripEntity interface)
  @override
  Expense get expense => this;

  /// Draft constructor for forms - id and dateTime can be null
  const factory Expense.draft({
    required String tripId,
    required String currency,
    required ExpenseCategory category,
    required Map<String, double> paidBy,
    required List<String> splitBy,
    String? id,
    @Default('') String title,
    String? description,
    DateTime? dateTime,
  }) = ExpenseDraft;

  /// Strict constructor for persisted data
  const factory Expense.strict({
    required String tripId,
    required String id,
    required String currency,
    required ExpenseCategory category,
    required Map<String, double> paidBy,
    required List<String> splitBy,
    @Default('') String title,
    String? description,
    DateTime? dateTime,
  }) = ExpenseStrict;

  /// Creates a new expense entry for UI forms
  factory Expense.newEntry({
    required String tripId,
    required Iterable<String> allTripContributors,
    required String defaultCurrency,
    ExpenseCategory? category,
  }) =>
      Expense.draft(
        tripId: tripId,
        currency: defaultCurrency,
        category: category ?? ExpenseCategory.other,
        paidBy: Map.fromIterables(
          allTripContributors,
          List.filled(allTripContributors.length, 0),
        ),
        splitBy: allTripContributors.toList(),
      );

  /// Computes total expense from paidBy amounts
  Money get totalExpense {
    double total = 0;
    paidBy.forEach((key, value) => total += value);
    return Money(amount: total, currency: currency);
  }

  @override
  Expense clone() => copyWith();

  @override
  bool validate() => paidBy.isNotEmpty && splitBy.isNotEmpty;

  /// Convert to strict model after persistence
  ExpenseStrict toStrict({required String id}) {
    return switch (this) {
      ExpenseDraft(
        :final tripId,
        :final currency,
        :final category,
        :final paidBy,
        :final splitBy,
        :final title,
        :final description,
        :final dateTime,
      ) =>
        Expense.strict(
          tripId: tripId,
          id: id,
          currency: currency,
          category: category,
          paidBy: paidBy,
          splitBy: splitBy,
          title: title,
          description: description,
          dateTime: dateTime,
        ) as ExpenseStrict,
      ExpenseStrict() => this as ExpenseStrict,
      _ => throw StateError('Unknown Expense type'),
    };
  }
}

// Legacy alias for backward compatibility
typedef ExpenseFacade = Expense;
