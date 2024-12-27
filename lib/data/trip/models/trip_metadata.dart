import 'package:equatable/equatable.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/presentation/app/extensions.dart';

import 'money.dart';

class TripMetadataFacade extends Equatable implements TripEntity {
  @override
  String? id;

  DateTime? startDate;

  DateTime? endDate;

  String name;

  List<String> contributors;

  Money budget;

  TripMetadataFacade(
      {required this.id,
      required this.startDate,
      required this.endDate,
      required this.name,
      required this.contributors,
      required this.budget});

  TripMetadataFacade.newUiEntry({required String defaultCurrency})
      : name = '',
        contributors = [],
        budget = Money(currency: defaultCurrency, amount: 0);

  void copyWith(TripMetadataFacade tripMetadataModel) {
    id = tripMetadataModel.id;
    startDate = tripMetadataModel.startDate;
    endDate = tripMetadataModel.endDate;
    name = tripMetadataModel.name;
    contributors = List.from(tripMetadataModel.contributors);
    budget = tripMetadataModel.budget;
  }

  TripMetadataFacade clone() {
    return TripMetadataFacade(
        id: id,
        startDate: startDate,
        endDate: endDate,
        name: name,
        contributors: contributors,
        budget: budget);
  }

  bool isValid() {
    var hasValidName = name.isNotEmpty;
    var hasValidDateRange = endDate != null &&
        startDate != null &&
        endDate!.compareTo(startDate!) > 0 &&
        endDate!.calculateDaysInBetween(startDate!) >= 1;

    return hasValidName && hasValidDateRange;
  }

  @override
  List<Object?> get props =>
      [id, startDate, endDate, name, contributors, budget];
}
