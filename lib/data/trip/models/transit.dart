import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/core/model_types.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/location/location.dart';

part 'transit.freezed.dart';

/// Represents a transit (travel segment) in a trip.
///
/// Uses freezed union types for draft/strict separation:
/// - [Transit.draft]: For forms where locations and times can be nullable
/// - [Transit.strict]: For persisted data where all required fields are non-null
@freezed
class Transit with _$Transit implements ExpenseLinkedTripEntity<Transit> {
  const Transit._();

  /// Draft constructor for forms - locations and times nullable
  const factory Transit.draft({
    required String tripId,
    required TransitOption transitOption,
    required Expense expense,
    String? id,
    Location? departureLocation,
    DateTime? departureDateTime,
    Location? arrivalLocation,
    DateTime? arrivalDateTime,
    String? operator,
    String? confirmationId,
    @Default('') String notes,
  }) = TransitDraft;

  /// Strict constructor for persisted data - all required fields non-null
  const factory Transit.strict({
    required String tripId,
    required String id,
    required TransitOption transitOption,
    required Location departureLocation,
    required DateTime departureDateTime,
    required Location arrivalLocation,
    required DateTime arrivalDateTime,
    required Expense expense,
    String? operator,
    String? confirmationId,
    @Default('') String notes,
  }) = TransitStrict;

  /// Creates a new transit entry for UI forms
  factory Transit.newEntry({
    required String tripId,
    required TransitOption transitOption,
    required Iterable<String> allTripContributors,
    required String defaultCurrency,
  }) =>
      Transit.draft(
        tripId: tripId,
        transitOption: transitOption,
        expense: Expense.newEntry(
          tripId: tripId,
          allTripContributors: allTripContributors,
          defaultCurrency: defaultCurrency,
          category: getExpenseCategory(transitOption),
        ),
      );

  static ExpenseCategory getExpenseCategory(TransitOption transitOption) {
    switch (transitOption) {
      case TransitOption.publicTransport:
      case TransitOption.train:
      case TransitOption.cruise:
      case TransitOption.ferry:
      case TransitOption.bus:
        return ExpenseCategory.publicTransit;
      case TransitOption.rentedVehicle:
        return ExpenseCategory.carRental;
      case TransitOption.flight:
        return ExpenseCategory.flights;
      case TransitOption.taxi:
        return ExpenseCategory.taxi;
      default:
        return ExpenseCategory.publicTransit;
    }
  }

  @override
  Transit clone() => copyWith();

  @override
  bool validate() {
    final areLocationsValid =
        departureLocation != null && arrivalLocation != null;
    final areDateTimesValid = departureDateTime != null &&
        arrivalDateTime != null &&
        departureDateTime!.compareTo(arrivalDateTime!) < 0;

    bool isTransitCarrierValid = true;
    if (transitOption == TransitOption.flight) {
      isTransitCarrierValid = _isFlightOperatorValid();
    }

    return areLocationsValid &&
        areDateTimesValid &&
        isTransitCarrierValid &&
        expense.validate();
  }

  bool _isFlightOperatorValid() {
    if (transitOption == TransitOption.flight) {
      final splitOptions = operator?.split(' ');
      if (splitOptions != null &&
          splitOptions.length >= 3 &&
          !splitOptions.any((e) => e.isEmpty)) {
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  String toString() {
    if (departureDateTime != null &&
        departureLocation != null &&
        arrivalLocation != null) {
      final dateTime =
          '${departureDateTime!.monthFormat} ${departureDateTime!.day}';
      return '$departureLocation to $arrivalLocation on $dateTime';
    }
    return 'Unnamed Entry';
  }

  /// Convert to strict model after persistence
  TransitStrict toStrict({required String id}) {
    return switch (this) {
      TransitDraft(
        :final tripId,
        :final transitOption,
        :final expense,
        :final departureLocation,
        :final departureDateTime,
        :final arrivalLocation,
        :final arrivalDateTime,
        :final operator,
        :final confirmationId,
        :final notes,
      ) =>
        Transit.strict(
          tripId: tripId,
          id: id,
          transitOption: transitOption,
          departureLocation: departureLocation!,
          departureDateTime: departureDateTime!,
          arrivalLocation: arrivalLocation!,
          arrivalDateTime: arrivalDateTime!,
          expense: expense,
          operator: operator,
          confirmationId: confirmationId,
          notes: notes,
        ) as TransitStrict,
      TransitStrict() => this as TransitStrict,
      _ => throw StateError('Unknown Transit type'),
    };
  }
}

/// Transit options for categorizing transport types
enum TransitOption {
  bus,
  flight,
  rentedVehicle,
  train,
  walk,
  ferry,
  cruise,
  vehicle,
  publicTransport,
  taxi
}

// Legacy alias for backward compatibility
typedef TransitFacade = Transit;
