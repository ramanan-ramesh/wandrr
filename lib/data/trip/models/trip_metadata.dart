import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';

import 'budgeting/money.dart';

// ignore: must_be_immutable
class TripMetadataFacade extends Equatable
    implements TripEntity<TripMetadataValidationError> {
  @override
  String? id;

  DateTime? startDate;

  DateTime? endDate;

  String name;

  String thumbnailTag;

  List<String> contributors;

  Money budget;

  TripMetadataFacade(
      {required this.id,
      required this.startDate,
      required this.endDate,
      required this.name,
      required this.contributors,
      required this.thumbnailTag,
      required this.budget});

  TripMetadataFacade.newUiEntry(
      {required String defaultCurrency, required this.thumbnailTag})
      : name = '',
        contributors = [],
        budget = Money(currency: defaultCurrency, amount: 0);

  @override
  TripMetadataFacade clone() => TripMetadataFacade(
      id: id,
      startDate: startDate != null
          ? DateTime(startDate!.year, startDate!.month, startDate!.day)
          : null,
      endDate: endDate != null
          ? DateTime(endDate!.year, endDate!.month, endDate!.day)
          : null,
      name: name,
      contributors: List.from(contributors),
      thumbnailTag: thumbnailTag,
      budget: budget);

  void copyWith(TripMetadataFacade tripMetadataModel) {
    startDate = tripMetadataModel.startDate != null
        ? DateTime(
            tripMetadataModel.startDate!.year,
            tripMetadataModel.startDate!.month,
            tripMetadataModel.startDate!.day)
        : null;
    endDate = tripMetadataModel.endDate != null
        ? DateTime(tripMetadataModel.endDate!.year,
            tripMetadataModel.endDate!.month, tripMetadataModel.endDate!.day)
        : null;
    name = tripMetadataModel.name;
    contributors = List.from(tripMetadataModel.contributors);
    budget = tripMetadataModel.budget;
  }

  @override
  Iterable<TripMetadataValidationError> getValidationErrors() {
    final errors = <TripMetadataValidationError>[];
    if (name.isEmpty) {
      errors.add(TripMetadataValidationError.missingTitle);
    }
    if (startDate == null) {
      errors.add(TripMetadataValidationError.missingStartDate);
    }
    if (endDate == null) {
      errors.add(TripMetadataValidationError.missingEndDate);
    }
    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
      errors.add(TripMetadataValidationError.invalidDateRange);
    }
    return errors;
  }

  // Sort contributors before comparison so order differences (e.g. from
  // different Firestore read orders) don't produce false inequality.
  @override
  List<Object?> get props => [
        id,
        startDate,
        endDate,
        name,
        ([...contributors]..sort()),
        budget,
      ];
}
