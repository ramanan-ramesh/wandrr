import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_validation_result.dart';

import 'budgeting/money.dart';

// ignore: must_be_immutable
class TripMetadataFacade extends Equatable
    implements TripEntity<TripMetadataValidationResult> {
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
  bool validate() => getValidationErrors().isEmpty;

  @override
  Iterable<TripMetadataValidationResult> getValidationErrors() {
    final errors = <TripMetadataValidationResult>[];
    if (name.isEmpty) {
      errors.add(TripMetadataValidationResult.missingTitle);
    }
    if (startDate == null) {
      errors.add(TripMetadataValidationResult.missingStartDate);
    }
    if (endDate == null) {
      errors.add(TripMetadataValidationResult.missingEndDate);
    }
    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
      errors.add(TripMetadataValidationResult.invalidDateRange);
    }
    return errors;
  }

  @override
  List<Object?> get props =>
      [id, startDate, endDate, name, contributors, budget];
}
