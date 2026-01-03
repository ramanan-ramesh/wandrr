/// Core model types and interfaces for the trip data layer.
///
/// This module defines the separation between:
/// - **Draft Models**: Used in forms/UI where fields can be nullable during creation
/// - **Strict Models**: Used after persistence where all required fields are non-null
/// - **Repository Converters**: Handle Firestore serialization/deserialization
library;

/// Base interface for all trip entities.
/// Provides common functionality for cloning and validation.
abstract class TripEntity<T> {
  /// The unique identifier for this entity.
  /// - `null` for new draft entities before persistence
  /// - Non-null string for persisted entities
  String? get id;

  /// Creates a deep copy of this entity.
  T clone();

  /// Validates whether this entity is ready for persistence.
  bool validate();
}

/// Interface for trip entities that have an associated expense.
/// Note: With immutable freezed models, use copyWith to update expense.
abstract class ExpenseLinkedTripEntity<T> implements TripEntity<T> {
  /// The expense associated with this entity (transit, lodging, sight).
  dynamic get expense;
}

/// Marker interface for strict (persisted) models.
/// These models guarantee non-null required fields.
abstract class StrictModel {
  /// The guaranteed non-null identifier for persisted models.
  String get id;
}

/// Extension to convert draft models to strict models after validation.
extension DraftToStrict<Draft extends TripEntity<Draft>> on Draft {
  /// Validates the draft and throws if invalid.
  void ensureValid() {
    if (!validate()) {
      throw StateError('Cannot convert invalid draft to strict model');
    }
  }
}
