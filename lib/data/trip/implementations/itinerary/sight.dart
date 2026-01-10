import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/budgeting/expense.dart';
import 'package:wandrr/data/trip/implementations/location.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';

class SightModelImplementation extends SightFacade
    implements LeafRepositoryItem<SightFacade> {
  static const String _nameField = 'name';
  static const String _locationField = 'location';
  static const String _visitTimeField = 'visitTime';
  static const String _expenseField = 'expense';
  static const String _descriptionField = 'description';

  factory SightModelImplementation.fromModelFacade(SightFacade facade) {
    return SightModelImplementation._(
      tripId: facade.tripId,
      id: facade.id,
      name: facade.name,
      location: facade.location != null
          ? LocationModelImplementation.fromModelFacade(
              locationModelFacade: facade.location!)
          : null,
      visitTime: facade.visitTime?.copyWith(),
      expense: ExpenseModelImplementation.fromModelFacade(
        expenseModelFacade: facade.expense,
      ),
      description: facade.description,
      day: facade.day,
    );
  }

  factory SightModelImplementation.fromJson(
    Map<String, dynamic> json,
    DateTime day,
    int index,
    String tripId,
  ) {
    var visitTime = json[_visitTimeField] != null
        ? (json[_visitTimeField] as Timestamp).toDate()
        : null;
    var location = json[_locationField] != null
        ? LocationModelImplementation.fromJson(
            json: json[_locationField] as Map<String, dynamic>)
        : null;
    return SightModelImplementation._(
      tripId: tripId,
      name: json[_nameField] as String,
      day: day,
      location: location,
      visitTime: visitTime,
      expense: ExpenseModelImplementation.fromJson(
          json[_expenseField] as Map<String, dynamic>),
      description: json[_descriptionField] as String?,
      id: index.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      _nameField: name,
      if (location != null)
        _locationField: (location as LeafRepositoryItem?)?.toJson(),
      if (visitTime != null)
        _visitTimeField:
            visitTime != null ? Timestamp.fromDate(visitTime!) : null,
      _expenseField: (expense as ExpenseModelImplementation).toJson(),
      if (description != null) _descriptionField: description,
    };
  }

  @override
  SightFacade get facade => this;

  SightModelImplementation._({
    required super.tripId,
    required super.name,
    required super.day,
    required super.expense,
    super.id,
    super.location,
    super.visitTime,
    super.description,
  });
}
