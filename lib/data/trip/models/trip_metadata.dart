import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/core/model_types.dart';

part 'trip_metadata.freezed.dart';

/// Represents trip metadata (name, dates, contributors, budget).
///
/// Uses freezed union types for draft/strict separation:
/// - [TripMetadata.draft]: For forms where dates can be nullable
/// - [TripMetadata.strict]: For persisted data where required fields are non-null
@freezed
class TripMetadata with _$TripMetadata implements TripEntity<TripMetadata> {
  const TripMetadata._();

  /// Draft constructor for forms - dates and id can be nullable
  const factory TripMetadata.draft({
    required String name,
    required String thumbnailTag,
    required List<String> contributors,
    required Money budget,
    String? id,
    DateTime? startDate,
    DateTime? endDate,
  }) = TripMetadataDraft;

  /// Strict constructor for persisted data - all required fields non-null
  const factory TripMetadata.strict({
    required String id,
    required String name,
    required String thumbnailTag,
    required List<String> contributors,
    required Money budget,
    required DateTime startDate,
    required DateTime endDate,
  }) = TripMetadataStrict;

  /// Creates a new trip metadata entry for UI forms
  factory TripMetadata.newEntry({
    required String defaultCurrency,
    required String thumbnailTag,
  }) =>
      TripMetadata.draft(
        name: '',
        thumbnailTag: thumbnailTag,
        contributors: [],
        budget: Money(currency: defaultCurrency, amount: 0),
      );

  @override
  TripMetadata clone() => copyWith();

  @override
  bool validate() {
    final hasValidName = name.isNotEmpty;
    final hasValidDateRange = endDate != null &&
        startDate != null &&
        endDate!.compareTo(startDate!) >= 0;
    return hasValidName && hasValidDateRange;
  }

  /// Convert to strict model after persistence
  TripMetadataStrict toStrict({required String id}) {
    return switch (this) {
      TripMetadataDraft(
        :final name,
        :final thumbnailTag,
        :final contributors,
        :final budget,
        :final startDate,
        :final endDate,
      ) =>
        TripMetadata.strict(
          id: id,
          name: name,
          thumbnailTag: thumbnailTag,
          contributors: contributors,
          budget: budget,
          startDate: startDate!,
          endDate: endDate!,
        ) as TripMetadataStrict,
      TripMetadataStrict() => this as TripMetadataStrict,
      _ => throw StateError('Unknown TripMetadata type'),
    };
  }
}

// Legacy alias for backward compatibility
typedef TripMetadataFacade = TripMetadata;
