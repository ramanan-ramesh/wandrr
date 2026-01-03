import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/expense_category.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list_item.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/location/location_context.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

/// Converts Firestore Timestamp to/from DateTime
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime dateTime) => Timestamp.fromDate(dateTime);
}

/// Converts nullable Firestore Timestamp to/from DateTime
class NullableTimestampConverter
    implements JsonConverter<DateTime?, Timestamp?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Timestamp? timestamp) => timestamp?.toDate();

  @override
  Timestamp? toJson(DateTime? dateTime) =>
      dateTime != null ? Timestamp.fromDate(dateTime) : null;
}

/// Converts GeoPoint to/from Location coordinates
class GeoPointConverter
    implements JsonConverter<Map<String, double>, GeoPoint> {
  const GeoPointConverter();

  @override
  Map<String, double> fromJson(GeoPoint geoPoint) => {
        'latitude': geoPoint.latitude,
        'longitude': geoPoint.longitude,
      };

  @override
  GeoPoint toJson(Map<String, double> coords) =>
      GeoPoint(coords['latitude']!, coords['longitude']!);
}

/// Converter for Money to/from Firestore string format
class MoneyConverter implements JsonConverter<Money, String> {
  const MoneyConverter();

  @override
  Money fromJson(String value) => Money.fromDocumentData(value);

  @override
  String toJson(Money money) => money.toString();
}

/// Converter for ExpenseCategory enum
class ExpenseCategoryConverter
    implements JsonConverter<ExpenseCategory, String> {
  const ExpenseCategoryConverter();

  @override
  ExpenseCategory fromJson(String value) =>
      ExpenseCategory.values.firstWhere((e) => e.name == value);

  @override
  String toJson(ExpenseCategory category) => category.name;
}

/// Converter for TransitOption enum
class TransitOptionConverter implements JsonConverter<TransitOption, String> {
  const TransitOptionConverter();

  @override
  TransitOption fromJson(String value) =>
      TransitOption.values.firstWhere((e) => e.name == value);

  @override
  String toJson(TransitOption option) => option.name;
}

/// Repository converter for Expense model - handles Firestore serialization
class ExpenseFirestoreConverter {
  static const _titleField = 'title';
  static const _descriptionField = 'description';
  static const _categoryField = 'category';
  static const _paidByField = 'paidBy';
  static const _splitByField = 'splitBy';
  static const _currencyField = 'currency';
  static const _dateTimeField = 'dateTime';

  static Expense fromFirestore(Map<String, dynamic> json, String tripId,
      {String? id}) {
    final currency = json[_currencyField] as String;
    final category = ExpenseCategory.values
        .firstWhere((e) => json[_categoryField] == e.name);

    Timestamp? dateTimeValue;
    if (json.containsKey(_dateTimeField) && json[_dateTimeField] != null) {
      dateTimeValue = json[_dateTimeField] as Timestamp;
    }

    final splitBy = List<String>.from(json[_splitByField]);
    final paidByValue = Map<String, dynamic>.from(json[_paidByField]);
    final paidBy = <String, double>{};
    for (final paidByEntry in paidByValue.entries) {
      paidBy[paidByEntry.key] = double.parse(paidByEntry.value.toString());
    }

    if (id != null) {
      return Expense.strict(
        tripId: tripId,
        id: id,
        currency: currency,
        category: category,
        paidBy: paidBy,
        splitBy: splitBy,
        title: json[_titleField] ?? '',
        description: json[_descriptionField],
        dateTime: dateTimeValue?.toDate(),
      );
    }

    return Expense.draft(
      tripId: tripId,
      id: id,
      currency: currency,
      category: category,
      paidBy: paidBy,
      splitBy: splitBy,
      title: json[_titleField] ?? '',
      description: json[_descriptionField],
      dateTime: dateTimeValue?.toDate(),
    );
  }

  static Map<String, dynamic> toFirestore(Expense expense) {
    return {
      _currencyField: expense.currency,
      _paidByField: expense.paidBy,
      if (expense.title.isNotEmpty) _titleField: expense.title,
      _categoryField: expense.category.name,
      if (expense.description != null && expense.description!.isNotEmpty)
        _descriptionField: expense.description,
      _splitByField: expense.splitBy,
      if (expense.dateTime != null)
        _dateTimeField: Timestamp.fromDate(expense.dateTime!),
    };
  }
}

/// Repository converter for Location model
class LocationFirestoreConverter {
  static const String _contextField = 'context';
  static const String _latitudeLongitudeField = 'latLon';

  static Location fromFirestore(Map<String, dynamic> json, {String? id}) {
    final geoPoint = json[_latitudeLongitudeField] as GeoPoint;
    final locationContext =
        LocationContext.createInstance(json: json[_contextField]);
    return Location(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      id: id,
      context: locationContext,
    );
  }

  static Map<String, dynamic> toFirestore(Location location) {
    final geoPoint = GeoPoint(location.latitude, location.longitude);
    return {
      _latitudeLongitudeField: geoPoint,
      _contextField: location.context.toJson(),
    };
  }
}

/// Repository converter for Transit model
class TransitFirestoreConverter {
  static const _departureLocationField = 'departureLocation';
  static const _departureDateTimeField = 'departureDateTime';
  static const _arrivalLocationField = 'arrivalLocation';
  static const _arrivalDateTimeField = 'arrivalDateTime';
  static const _transitOptionField = 'transitOption';
  static const _operatorField = 'operator';
  static const _confirmationIdField = 'confirmationId';
  static const _expenseField = 'totalExpense';
  static const _notesField = 'notes';

  static Transit fromFirestore(
      Map<String, dynamic> json, String tripId, String id) {
    return Transit.strict(
      id: id,
      tripId: tripId,
      notes: json[_notesField] ?? '',
      transitOption: TransitOption.values
          .firstWhere((e) => e.name == json[_transitOptionField]),
      expense: ExpenseFirestoreConverter.fromFirestore(
        json[_expenseField] as Map<String, dynamic>,
        tripId,
      ),
      confirmationId: json[_confirmationIdField],
      departureDateTime: (json[_departureDateTimeField] as Timestamp).toDate(),
      arrivalDateTime: (json[_arrivalDateTimeField] as Timestamp).toDate(),
      arrivalLocation: LocationFirestoreConverter.fromFirestore(
        json[_arrivalLocationField] as Map<String, dynamic>,
      ),
      departureLocation: LocationFirestoreConverter.fromFirestore(
        json[_departureLocationField] as Map<String, dynamic>,
      ),
      operator: json[_operatorField],
    );
  }

  static Map<String, dynamic> toFirestore(Transit transit) {
    return {
      _transitOptionField: transit.transitOption.name,
      _expenseField: ExpenseFirestoreConverter.toFirestore(transit.expense),
      _departureDateTimeField: Timestamp.fromDate(transit.departureDateTime!),
      _arrivalDateTimeField: Timestamp.fromDate(transit.arrivalDateTime!),
      _departureLocationField: transit.departureLocation != null
          ? LocationFirestoreConverter.toFirestore(transit.departureLocation!)
          : null,
      _arrivalLocationField: transit.arrivalLocation != null
          ? LocationFirestoreConverter.toFirestore(transit.arrivalLocation!)
          : null,
      if (transit.confirmationId != null && transit.confirmationId!.isNotEmpty)
        _confirmationIdField: transit.confirmationId,
      if (transit.operator != null && transit.operator!.isNotEmpty)
        _operatorField: transit.operator,
      if (transit.notes.isNotEmpty) _notesField: transit.notes,
    };
  }
}

/// Repository converter for Lodging model
class LodgingFirestoreConverter {
  static const _locationField = 'location';
  static const _confirmationIdField = 'confirmationId';
  static const _expenseField = 'expense';
  static const _checkinDateTimeField = 'checkinDateTime';
  static const _checkoutDateTimeField = 'checkoutDateTime';
  static const _notesField = 'notes';

  static Lodging fromFirestore(
      Map<String, dynamic> json, String tripId, String id) {
    return Lodging.strict(
      tripId: tripId,
      id: id,
      checkinDateTime: (json[_checkinDateTimeField] as Timestamp).toDate(),
      checkoutDateTime: (json[_checkoutDateTimeField] as Timestamp).toDate(),
      location: LocationFirestoreConverter.fromFirestore(
        json[_locationField] as Map<String, dynamic>,
      ),
      notes: json[_notesField],
      expense: ExpenseFirestoreConverter.fromFirestore(
        json[_expenseField] as Map<String, dynamic>,
        tripId,
      ),
      confirmationId: json[_confirmationIdField],
    );
  }

  static Map<String, dynamic> toFirestore(Lodging lodging) {
    return {
      _locationField: lodging.location != null
          ? LocationFirestoreConverter.toFirestore(lodging.location!)
          : null,
      _expenseField: ExpenseFirestoreConverter.toFirestore(lodging.expense),
      _checkinDateTimeField: Timestamp.fromDate(lodging.checkinDateTime!),
      _checkoutDateTimeField: Timestamp.fromDate(lodging.checkoutDateTime!),
      if (lodging.confirmationId != null && lodging.confirmationId!.isNotEmpty)
        _confirmationIdField: lodging.confirmationId,
      if (lodging.notes != null && lodging.notes!.isNotEmpty)
        _notesField: lodging.notes,
    };
  }
}

/// Repository converter for TripMetadata model
class TripMetadataFirestoreConverter {
  static const String _startDateField = 'startDate';
  static const String _endDateField = 'endDate';
  static const String _nameField = 'name';
  static const String _contributorsField = 'contributors';
  static const String _thumbnailTagField = 'thumbnailTag';
  static const _budgetField = 'budget';

  static TripMetadata fromFirestore(DocumentSnapshot documentSnapshot) {
    final json = documentSnapshot.data() as Map<String, dynamic>;
    final startDateTime = (json[_startDateField] as Timestamp).toDate();
    final endDateTime = (json[_endDateField] as Timestamp).toDate();
    final contributors = List<String>.from(json[_contributorsField]);
    final budgetValue = json[_budgetField] as String;
    final thumbNailTag = json[_thumbnailTagField] as String;
    final budget = Money.fromDocumentData(budgetValue);

    return TripMetadata.strict(
      id: documentSnapshot.id,
      startDate: startDateTime,
      endDate: endDateTime,
      name: json[_nameField],
      contributors: contributors,
      thumbnailTag: thumbNailTag,
      budget: budget,
    );
  }

  static Map<String, dynamic> toFirestore(TripMetadata tripMetadata) {
    return {
      _startDateField: Timestamp.fromDate(tripMetadata.startDate!),
      _endDateField: Timestamp.fromDate(tripMetadata.endDate!),
      _contributorsField: tripMetadata.contributors,
      _nameField: tripMetadata.name,
      _budgetField: tripMetadata.budget.toString(),
      _thumbnailTagField: tripMetadata.thumbnailTag,
    };
  }
}

/// Repository converter for Sight model
class SightFirestoreConverter {
  static const String _nameField = 'name';
  static const String _locationField = 'location';
  static const String _visitTimeField = 'visitTime';
  static const String _expenseField = 'expense';
  static const String _descriptionField = 'description';

  static Sight fromFirestore(
    Map<String, dynamic> json,
    DateTime day,
    String tripId, {
    String? id,
  }) {
    final visitTime = json[_visitTimeField] != null
        ? (json[_visitTimeField] as Timestamp).toDate()
        : null;
    final location = json[_locationField] != null
        ? LocationFirestoreConverter.fromFirestore(
            json[_locationField] as Map<String, dynamic>)
        : null;

    if (id != null) {
      return Sight.strict(
        tripId: tripId,
        id: id,
        name: json[_nameField] as String,
        day: day,
        location: location,
        visitTime: visitTime,
        expense: ExpenseFirestoreConverter.fromFirestore(
          json[_expenseField] as Map<String, dynamic>,
          tripId,
        ),
        description: json[_descriptionField] as String?,
      );
    }

    return Sight.draft(
      tripId: tripId,
      id: id,
      name: json[_nameField] as String,
      day: day,
      location: location,
      visitTime: visitTime,
      expense: ExpenseFirestoreConverter.fromFirestore(
        json[_expenseField] as Map<String, dynamic>,
        tripId,
      ),
      description: json[_descriptionField] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(Sight sight) {
    return {
      _nameField: sight.name,
      if (sight.location != null)
        _locationField: LocationFirestoreConverter.toFirestore(sight.location!),
      if (sight.visitTime != null)
        _visitTimeField: Timestamp.fromDate(sight.visitTime!),
      _expenseField: ExpenseFirestoreConverter.toFirestore(sight.expense),
      if (sight.description != null) _descriptionField: sight.description,
    };
  }
}

/// Repository converter for CheckList model
class CheckListFirestoreConverter {
  static const _itemsField = 'items';
  static const _titleField = 'title';
  static const _itemField = 'item';
  static const _isCheckedField = 'status';

  static CheckList fromFirestore(
    Map<String, dynamic> json,
    String tripId, {
    String? id,
  }) {
    final items = List<Map<String, dynamic>>.from(json[_itemsField])
        .map(
          (e) => CheckListItem(
            item: e[_itemField] as String,
            isChecked: e[_isCheckedField] as bool,
          ),
        )
        .toList();

    if (id != null) {
      return CheckList.strict(
        tripId: tripId,
        id: id,
        title: json[_titleField] as String,
        items: items,
      );
    }

    return CheckList.draft(
      tripId: tripId,
      id: id,
      title: json[_titleField] as String?,
      items: items,
    );
  }

  static Map<String, dynamic> toFirestore(CheckList checkList) {
    // Access title directly - it's available on the base CheckList type
    final titleValue = checkList.title;

    return {
      _titleField: titleValue,
      _itemsField: checkList.items
          .where((item) => item.item.isNotEmpty)
          .map((item) => {
                _itemField: item.item,
                _isCheckedField: item.isChecked,
              })
          .toList(),
    };
  }
}

/// Repository converter for ItineraryPlanData model
class ItineraryPlanDataFirestoreConverter {
  static const String _sightsField = 'sights';
  static const String _notesField = 'notes';
  static const String _checkListsField = 'checkLists';

  static ItineraryPlanData fromFirestore(
    DocumentSnapshot documentSnapshot,
    String tripId,
    DateTime day,
  ) {
    final data = documentSnapshot.data();
    if (data is! Map<String, dynamic>) {
      throw Exception('Document data is invalid');
    }

    return ItineraryPlanData(
      tripId: tripId,
      id: documentSnapshot.id,
      day: day,
      sights: (data[_sightsField] as List?)
              ?.map((json) => SightFirestoreConverter.fromFirestore(
                    json as Map<String, dynamic>,
                    day,
                    tripId,
                  ))
              .toList() ??
          [],
      notes: (data[_notesField] as List?)
              ?.map((noteValue) => noteValue.toString())
              .toList() ??
          [],
      checkLists: (data[_checkListsField] as List?)
              ?.map((json) => CheckListFirestoreConverter.fromFirestore(
                    json as Map<String, dynamic>,
                    tripId,
                  ))
              .toList() ??
          [],
    );
  }

  static Map<String, dynamic> toFirestore(ItineraryPlanData planData) {
    return {
      if (planData.sights.isNotEmpty)
        _sightsField:
            planData.sights.map(SightFirestoreConverter.toFirestore).toList(),
      if (planData.notes.isNotEmpty) _notesField: planData.notes,
      if (planData.checkLists.isNotEmpty)
        _checkListsField: planData.checkLists
            .map(CheckListFirestoreConverter.toFirestore)
            .toList(),
    };
  }
}
