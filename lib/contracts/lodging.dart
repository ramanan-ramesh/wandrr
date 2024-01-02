import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/contracts/collection_names.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/firestore_helpers.dart';
import 'package:wandrr/contracts/location.dart';

abstract class LodgingFacade {
  LocationFacade get location;

  DateTime get checkinDateTime;

  DateTime get checkoutDateTime;

  String get id;

  String get tripId;

  String? get confirmationId;

  ExpenseFacade get expense;

  String? get notes;
}

class Lodging with EquatableMixin implements LodgingFacade {
  @override
  String tripId;

  @override
  String id;

  @override
  Location get location => _location;
  Location _location;
  static const _locationField = 'location';

  @override
  String? get confirmationId => _confirmationId;
  String? _confirmationId;
  static const _confirmationIdField = 'confirmationId';

  @override
  ExpenseFacade get expense => _expense;
  Expense _expense;
  static const _expenseField = 'expense';

  @override
  DateTime get checkinDateTime => _checkinDateTime;
  DateTime _checkinDateTime;
  static const _checkinDateTimeField = 'checkinDateTime';

  @override
  DateTime get checkoutDateTime => _checkoutDateTime;
  DateTime _checkoutDateTime;
  static const _checkoutDateTimeField = 'checkoutDateTime';

  @override
  String? get notes => _notes;
  String? _notes;
  static const _notesField = 'notes';

  static Future<Lodging?> createFromUserInput(
      {required LodgingUpdator lodgingUpdator}) async {
    var lodgingCollectionReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(lodgingUpdator.tripId)
        .collection(FirestoreCollections.lodgingCollection);
    var expenseUpdator = lodgingUpdator.expenseUpdator!;
    var lodging = Lodging._create(
        tripId: lodgingUpdator.tripId!,
        checkinDateTime: lodgingUpdator.checkinDateTime!,
        checkoutDateTime: lodgingUpdator.checkoutDateTime!,
        location: lodgingUpdator.location! as Location,
        confirmationId: lodgingUpdator.confirmationId,
        notes: lodgingUpdator.notes,
        expense: Expense.createLinkedExpense(
            totalExpense: expenseUpdator.totalExpense!,
            tripId: lodgingUpdator.tripId!,
            paidBy: expenseUpdator.paidBy!,
            category: expenseUpdator.category!,
            splitBy: expenseUpdator.splitBy!));
    try {
      var lodgingDocument =
          await lodgingCollectionReference.add(lodging.toJson());
      lodging.id = lodgingDocument.id;
      return lodging;
    } catch (exception) {
      return null;
    }
  }

  Lodging._create({
    required this.tripId,
    required DateTime checkinDateTime,
    required DateTime checkoutDateTime,
    required Location location,
    required Expense expense,
    String? id,
    String? notes,
    String? confirmationId,
  })  : _checkinDateTime = checkinDateTime,
        _checkoutDateTime = checkoutDateTime,
        _location = location,
        id = id ?? '',
        _notes = notes,
        _expense = expense,
        _confirmationId = confirmationId;

  DocumentReference _getDocumentReference() {
    return FirebaseFirestore.instance
        .collection(FirestoreCollections.tripsCollection)
        .doc(tripId)
        .collection(FirestoreCollections.lodgingCollection)
        .doc(id);
  }

  Future<bool> update({required LodgingUpdator lodgingUpdator}) async {
    var expenseUpdator = lodgingUpdator.expenseUpdator!;
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
    FirestoreHelpers.updateJson(_checkinDateTime,
        lodgingUpdator.checkinDateTime, _checkinDateTimeField, json);
    FirestoreHelpers.updateJson(_checkoutDateTime,
        lodgingUpdator.checkoutDateTime, _checkoutDateTimeField, json);
    FirestoreHelpers.updateJson(
        _location, lodgingUpdator.location, _locationField, json);
    FirestoreHelpers.updateJson(_confirmationId, lodgingUpdator.confirmationId,
        _confirmationIdField, json);
    FirestoreHelpers.updateJson(
        _notes, lodgingUpdator.notes, _notesField, json);
    FirestoreHelpers.updateJson(_expense, expenseToUpdate, _expenseField, json);

    var didUpdateLodging = json.isNotEmpty;
    await _getDocumentReference()
        .set(json, SetOptions(merge: true))
        .then((value) {
      didUpdateLodging = true;
      _checkinDateTime = lodgingUpdator.checkinDateTime!;
      _checkoutDateTime = lodgingUpdator.checkoutDateTime!;
      _location = lodgingUpdator.location! as Location;
      _confirmationId = lodgingUpdator.id;
      _notes = lodgingUpdator.notes;
      _expense = expenseToUpdate;
    }).catchError((error, stackTrace) {
      didUpdateLodging = false;
    });
    return didUpdateLodging;
  }

  static Lodging fromDocumentSnapshot(
      {required String tripId,
      required QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot}) {
    var checkinDateTime =
        (documentSnapshot[_checkinDateTimeField] as Timestamp).toDate();
    var checkoutDateTime =
        (documentSnapshot[_checkoutDateTimeField] as Timestamp).toDate();
    var location = Location.fromDocument(documentSnapshot[_locationField]);
    var expense =
        Expense.fromLinkedDocument(tripId, documentSnapshot[_expenseField]);
    return Lodging._create(
        tripId: tripId,
        id: documentSnapshot.id,
        checkinDateTime: checkinDateTime,
        checkoutDateTime: checkoutDateTime,
        location: location,
        notes: documentSnapshot[_notesField],
        expense: expense,
        confirmationId: documentSnapshot[_confirmationIdField]);
  }

  Map<String, dynamic> toJson() {
    return {
      _locationField: _location.toJson(),
      _expenseField: _expense.toJson(),
      _checkinDateTimeField: Timestamp.fromDate(_checkinDateTime),
      _checkoutDateTimeField: Timestamp.fromDate(_checkoutDateTime),
      _confirmationIdField: _confirmationId,
      _notesField: _notes
    };
  }

  @override
  String toString() {
    return 'Stay at ${_location.context.name} from ${_getShortenedDate(_checkinDateTime)} to ${_getShortenedDate(_checkoutDateTime)}';
  }

  String _getShortenedDate(DateTime dateTime) {
    return '${DateFormat.MMMM().format(_checkinDateTime).substring(0, 3)} ${dateTime.day}';
  }

  @override
  List<Object?> get props => [
        id,
        _confirmationId,
        _expense,
        tripId,
        _location,
        _notes,
        _checkoutDateTime,
        _checkinDateTime
      ];
}
