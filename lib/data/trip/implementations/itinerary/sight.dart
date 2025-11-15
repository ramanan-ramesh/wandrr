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
      expense: facade.expense.clone(),
      description: facade.description,
      day: facade.day,
    );
  }

  factory SightModelImplementation.fromJson(
    Map<String, dynamic> json,
    DateTime day,
    String tripId,
  ) {
    return SightModelImplementation._(
      tripId: tripId,
      name: json[_nameField] as String,
      day: day,
      location: json[_locationField] != null
          ? LocationModelImplementation.fromJson(
              json: json[_locationField] as Map<String, dynamic>,
              tripId: tripId,
            )
          : null,
      visitTime: json[_visitTimeField] != null
          ? (json[_visitTimeField] as Timestamp).toDate()
          : null,
      expense: ExpenseModelImplementation.fromJson(
        json: json[_expenseField] as Map<String, dynamic>,
        tripId: tripId,
      ),
      description: json[_descriptionField] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      _nameField: name,
      _locationField: (location as LeafRepositoryItem?)?.toJson(),
      _visitTimeField: visitTime?.toIso8601String(),
      _expenseField: (expense as ExpenseModelImplementation).toJson(),
      _descriptionField: description,
    };
  }

  @override
  SightFacade get facade => this;

  @override
  DocumentReference<Object?> get documentReference =>
      throw UnimplementedError();

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
