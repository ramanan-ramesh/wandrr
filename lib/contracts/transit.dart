import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/firestore_helpers.dart';
import 'package:wandrr/contracts/location.dart';

abstract class TransitFacade {
  String get tripId;

  String get id;

  TransitOptions get transitOption;

  LocationFacade get departureLocation;

  DateTime get departureDateTime;

  LocationFacade get arrivalLocation;

  DateTime get arrivalDateTime;

  String? get operator;

  String? get confirmationId;

  String? get notes;

  ExpenseFacade get expense;
}

enum TransitOptions {
  Bus,
  Flight,
  RentedVehicle,
  Train,
  Walk,
  Ferry,
  Cruise,
  Vehicle,
  PublicTransport
}

class Transit with EquatableMixin implements TransitFacade {
  @override
  final String tripId;

  @override
  String id;

  @override
  LocationFacade get departureLocation => _departureLocation;
  Location _departureLocation;
  static const _departureLocationField = 'departureLocation';

  @override
  DateTime get departureDateTime => _departureDateTime;
  DateTime _departureDateTime;
  static const _departureDateTimeField = 'departureDateTime';

  @override
  LocationFacade get arrivalLocation => _arrivalLocation;
  Location _arrivalLocation;
  static const _arrivalLocationField = 'arrivalLocation';

  @override
  DateTime get arrivalDateTime => _arrivalDateTime;
  DateTime _arrivalDateTime;
  static const _arrivalDateTimeField = 'arrivalDateTime';

  @override
  final TransitOptions transitOption;
  static const _transitOptionField = 'transitOption';

  @override
  String? get operator => _operator;
  String? _operator;
  static const _operatorField = 'operator';

  @override
  String? get confirmationId => _confirmationId;
  String? _confirmationId;
  static const _confirmationIdField = 'confirmationId';

  @override
  ExpenseFacade get expense => _expense;
  Expense _expense;
  static const _expenseField = 'expense';

  @override
  String? get notes => _notes;
  String? _notes;
  static const _notesField = 'notes';

  static Future<Transit?> createFromUserInput(
      {required TransitUpdator transitUpdator}) async {
    var transitCollectionReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(transitUpdator.tripId)
        .collection(FirestoreCollections.transitCollection);
    var expenseUpdator = transitUpdator.expenseUpdator!;
    var transit = Transit._create(
        tripId: transitUpdator.tripId!,
        transitOption: transitUpdator.transitOption!,
        departureDateTime: transitUpdator.departureDateTime!,
        arrivalDateTime: transitUpdator.arrivalDateTime!,
        departureLocation: transitUpdator.departureLocation! as Location,
        arrivalLocation: transitUpdator.arrivalLocation! as Location,
        confirmationId: transitUpdator.confirmationId,
        operator: transitUpdator.operator,
        notes: transitUpdator.notes,
        expense: Expense.createLinkedExpense(
            totalExpense: expenseUpdator.totalExpense!,
            category: expenseUpdator.category!,
            tripId: transitUpdator.tripId!,
            paidBy: expenseUpdator.paidBy!,
            splitBy: expenseUpdator.splitBy!));
    try {
      var transitDocument =
          await transitCollectionReference.add(transit.toJson());
      transit.id = transitDocument.id;
      return transit;
    } catch (exception) {
      return null;
    }
  }

  Transit.fromDocumentSnapshot(
      {required String tripId,
      required QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot})
      : this._create(
            id: documentSnapshot.id,
            tripId: tripId,
            notes: documentSnapshot[_notesField],
            transitOption: TransitOptions.values.firstWhere((element) =>
                element.name == documentSnapshot[_transitOptionField]),
            expense: Expense.fromLinkedDocument(
                tripId, documentSnapshot[_expenseField]),
            confirmationId: documentSnapshot[_confirmationIdField],
            departureDateTime:
                (documentSnapshot[_departureDateTimeField] as Timestamp)
                    .toDate(),
            arrivalDateTime:
                (documentSnapshot[_arrivalDateTimeField] as Timestamp).toDate(),
            arrivalLocation:
                Location.fromDocument(documentSnapshot[_arrivalLocationField]),
            departureLocation: Location.fromDocument(
                documentSnapshot[_departureLocationField]),
            operator: documentSnapshot[_operatorField]);

  Future<bool> update({required TransitUpdator transitUpdator}) async {
    var expenseUpdator = transitUpdator.expenseUpdator!;
    var expenseToUpdate = Expense.create(
        tripId: expenseUpdator.tripId,
        totalExpense: expenseUpdator.totalExpense!,
        paidBy: expenseUpdator.paidBy!,
        splitBy: expenseUpdator.splitBy!,
        category: expenseUpdator.category!,
        dateTime: expenseUpdator.dateTime,
        location: expenseUpdator.location as Location?,
        title: expenseUpdator.title!,
        description: expenseUpdator.description);
    Map<String, dynamic> json = {};
    FirestoreHelpers.updateJson(_departureLocation,
        transitUpdator.departureLocation, _departureLocationField, json);
    FirestoreHelpers.updateJson(_arrivalLocation,
        transitUpdator.arrivalLocation, _arrivalLocationField, json);
    FirestoreHelpers.updateJson(_expense, expenseToUpdate, _expenseField, json);
    FirestoreHelpers.updateJson(_departureDateTime,
        transitUpdator.departureDateTime, _departureDateTimeField, json);
    FirestoreHelpers.updateJson(_arrivalDateTime,
        transitUpdator.arrivalDateTime, _arrivalDateTimeField, json);
    FirestoreHelpers.updateJson(_confirmationId, transitUpdator.confirmationId,
        _confirmationIdField, json);
    FirestoreHelpers.updateJson(
        _operator, transitUpdator.operator, _operatorField, json);
    FirestoreHelpers.updateJson(
        _notes, transitUpdator.notes, _notesField, json);
    if (json.isEmpty) {
      return false;
    }
    var didUpdate = json.isNotEmpty;
    await _getDocumentReference()
        .set(json, SetOptions(merge: true))
        .then((value) {
      didUpdate = true;
      _notes = transitUpdator.notes;
      _expense = expenseToUpdate;
      _confirmationId = transitUpdator.confirmationId;
      _arrivalDateTime = transitUpdator.arrivalDateTime!;
      _departureDateTime = transitUpdator.departureDateTime!;
      _operator = transitUpdator.operator;
      _departureLocation = transitUpdator.departureLocation! as Location;
      _arrivalLocation = transitUpdator.arrivalLocation! as Location;
    }).catchError((error, stackTrace) {
      didUpdate = false;
    });
    return didUpdate;
  }

  Transit._create(
      {required this.tripId,
      required this.transitOption,
      required DateTime departureDateTime,
      required DateTime arrivalDateTime,
      required Location departureLocation,
      required Location arrivalLocation,
      required Expense expense,
      String? confirmationId,
      String? id,
      String? operator,
      String? notes})
      : _expense = expense,
        id = id ?? '',
        _confirmationId = confirmationId,
        _departureDateTime = departureDateTime,
        _departureLocation = departureLocation,
        _arrivalDateTime = arrivalDateTime,
        _arrivalLocation = arrivalLocation,
        _operator = operator,
        _notes = notes;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      _transitOptionField: transitOption.name,
      _expenseField: _expense.toJson(),
      _departureDateTimeField: Timestamp.fromDate(_departureDateTime),
      _arrivalDateTimeField: Timestamp.fromDate(_arrivalDateTime),
      _departureLocationField: _departureLocation.toJson(),
      _arrivalLocationField: _arrivalLocation.toJson(),
      _confirmationIdField: _confirmationId,
      _operatorField: _operator,
      _notesField: _notes
    };

    return json;
  }

  DocumentReference _getDocumentReference() {
    return FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(tripId)
        .collection(FirestoreCollections.transitCollection)
        .doc(id);
  }

  @override
  String toString() {
    var dateTime =
        '${DateFormat.MMMM().format(_departureDateTime).substring(0, 3)} ${_departureDateTime.day}';
    return '${departureLocation.toString()} to ${arrivalLocation.toString()} on $dateTime';
  }

  @override
  List<Object?> get props => [
        tripId,
        _operator,
        _expense,
        _confirmationId,
        id,
        _departureLocation,
        _arrivalLocation,
        _departureDateTime,
        _arrivalDateTime,
        transitOption,
        _notes
      ];
}
