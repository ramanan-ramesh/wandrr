import 'package:equatable/equatable.dart';
import 'package:wandrr/contracts/trip_entity.dart';
import 'package:wandrr/contracts/trip_entity_facades/expense.dart';

class TripMetadataFacade extends Equatable implements TripEntity {
  @override
  String? id;

  DateTime? startDate;

  DateTime? endDate;

  String name;

  List<String> contributors;

  double totalExpenditure;

  CurrencyWithValue budget;

  TripMetadataFacade(
      {required this.id,
      required this.startDate,
      required this.endDate,
      required this.name,
      required this.contributors,
      required this.totalExpenditure,
      required this.budget});

  TripMetadataFacade.newUiEntry({required String defaultCurrency})
      : name = '',
        contributors = [],
        totalExpenditure = 0,
        budget = CurrencyWithValue(currency: defaultCurrency, amount: 0);

  void copyWith(TripMetadataFacade tripMetadataModel) {
    id = tripMetadataModel.id;
    startDate = tripMetadataModel.startDate;
    endDate = tripMetadataModel.endDate;
    name = tripMetadataModel.name;
    contributors = List.from(tripMetadataModel.contributors);
    totalExpenditure = tripMetadataModel.totalExpenditure;
    budget = tripMetadataModel.budget;
  }

  TripMetadataFacade clone() {
    return TripMetadataFacade(
        id: id,
        startDate: startDate,
        endDate: endDate,
        name: name,
        contributors: contributors,
        totalExpenditure: totalExpenditure,
        budget: budget);
  }

  @override
  List<Object?> get props =>
      [id, startDate, endDate, name, contributors, totalExpenditure, budget];
}
