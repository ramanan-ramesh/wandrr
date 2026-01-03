import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/core/model_types.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

part 'lodging.freezed.dart';

/// Represents a lodging/accommodation in a trip.
///
/// Uses freezed union types for draft/strict separation:
/// - [Lodging.draft]: For forms where some fields can be nullable
/// - [Lodging.strict]: For persisted data where required fields are non-null
@freezed
class Lodging with _$Lodging implements ExpenseLinkedTripEntity<Lodging> {
  const Lodging._();

  /// Draft constructor for forms - location, times can be nullable
  const factory Lodging.draft({
    required String tripId,
    required Expense expense,
    String? id,
    Location? location,
    DateTime? checkinDateTime,
    DateTime? checkoutDateTime,
    String? confirmationId,
    String? notes,
  }) = LodgingDraft;

  /// Strict constructor for persisted data - all required fields non-null
  const factory Lodging.strict({
    required String tripId,
    required String id,
    required Location location,
    required DateTime checkinDateTime,
    required DateTime checkoutDateTime,
    required Expense expense,
    String? confirmationId,
    String? notes,
  }) = LodgingStrict;

  /// Creates a new lodging entry for UI forms
  factory Lodging.newEntry({
    required String tripId,
    required Iterable<String> allTripContributors,
    required String defaultCurrency,
  }) =>
      Lodging.draft(
        tripId: tripId,
        expense: Expense.newEntry(
          tripId: tripId,
          allTripContributors: allTripContributors,
          defaultCurrency: defaultCurrency,
          category: ExpenseCategory.lodging,
        ),
      );

  @override
  Lodging clone() => copyWith();

  @override
  bool validate() =>
      location != null &&
      checkinDateTime != null &&
      checkoutDateTime != null &&
      expense.validate();

  @override
  String toString() {
    if (checkinDateTime != null &&
        checkoutDateTime != null &&
        location != null) {
      final checkInDayDescription =
          '${checkinDateTime!.monthFormat} ${checkinDateTime!.day}';
      final checkOutDayDescription =
          '${checkoutDateTime!.monthFormat} ${checkoutDateTime!.day}';
      return 'Stay at $location from $checkInDayDescription to $checkOutDayDescription';
    }
    return 'Unnamed Entry';
  }

  /// Convert to strict model after persistence
  LodgingStrict toStrict({required String id}) {
    return switch (this) {
      LodgingDraft(
        :final tripId,
        :final expense,
        :final location,
        :final checkinDateTime,
        :final checkoutDateTime,
        :final confirmationId,
        :final notes,
      ) =>
        Lodging.strict(
          tripId: tripId,
          id: id,
          location: location!,
          checkinDateTime: checkinDateTime!,
          checkoutDateTime: checkoutDateTime!,
          expense: expense,
          confirmationId: confirmationId,
          notes: notes,
        ) as LodgingStrict,
      LodgingStrict() => this as LodgingStrict,
      _ => throw StateError('Unknown Lodging type'),
    };
  }
}

// Legacy alias for backward compatibility
typedef LodgingFacade = Lodging;
