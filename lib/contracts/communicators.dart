import 'package:equatable/equatable.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/contracts/check_list.dart';
import 'package:wandrr/contracts/lodging.dart';
import 'package:wandrr/contracts/note.dart';
import 'package:wandrr/contracts/plan_data.dart';
import 'package:wandrr/contracts/trip_metadata.dart';

import 'expense.dart';
import 'location.dart';
import 'transit.dart';

class TripMetadataUpdator {
  DateTime? startDate;
  DateTime? endDate;
  String? name;
  String? id;
  List<String>? contributors;
  double? totalExpenditure;
  CurrencyWithValue? budget;
  DataState typeOfOperation;
  LocationFacade? location;

  TripMetadataUpdator.fromTripMetadata(
      {required TripMetaDataFacade tripMetaDataFacade})
      : startDate = tripMetaDataFacade.startDate,
        endDate = tripMetaDataFacade.endDate,
        name = tripMetaDataFacade.name,
        id = tripMetaDataFacade.id,
        contributors = List.of(tripMetaDataFacade.contributors),
        totalExpenditure = tripMetaDataFacade.totalExpenditure,
        budget = CurrencyWithValue(
            currency: tripMetaDataFacade.budget.currency,
            amount: tripMetaDataFacade.budget.amount),
        typeOfOperation = DataState.None,
        location = tripMetaDataFacade.location.clone();

  TripMetadataUpdator.create(
      {required DateTime this.startDate,
      required DateTime this.endDate,
      required String this.name,
      required List<String> this.contributors,
      required Location this.location})
      : typeOfOperation = DataState.Created;

  TripMetadataUpdator.update(
      {required DateTime this.startDate,
      required DateTime this.endDate,
      required String this.name,
      required List<String> this.contributors,
      required String this.id,
      required CurrencyWithValue this.budget,
      required double this.totalExpenditure,
      required Location this.location})
      : typeOfOperation = DataState.Updated;

  TripMetadataUpdator.delete({required String this.id})
      : typeOfOperation = DataState.Deleted;
}

class TransitUpdator extends Equatable {
  DateTime? departureDateTime, arrivalDateTime;
  TransitOptions? transitOption;
  ExpenseUpdator? expenseUpdator;
  String? confirmationId;
  LocationFacade? departureLocation, arrivalLocation;
  String? operator;
  String? id;
  String? tripId;
  DataState dataState;
  String? notes;

  TransitUpdator clone() {
    return TransitUpdator._create(
        tripId: tripId,
        dataState: dataState,
        departureLocation: departureLocation,
        arrivalLocation: arrivalLocation,
        transitOption: transitOption,
        expenseUpdator: expenseUpdator?.clone(),
        departureDateTime: departureDateTime,
        arrivalDateTime: arrivalDateTime,
        notes: notes,
        id: id,
        confirmationId: confirmationId,
        operator: operator);
  }

  TransitUpdator._create(
      {this.departureLocation,
      this.arrivalLocation,
      this.transitOption,
      this.expenseUpdator,
      this.departureDateTime,
      this.arrivalDateTime,
      this.notes,
      required this.tripId,
      this.id,
      this.confirmationId,
      this.operator,
      required this.dataState});

  TransitUpdator.fromTransit({required TransitFacade transit})
      : this._create(
            tripId: transit.tripId,
            departureLocation: transit.departureLocation,
            arrivalLocation: transit.arrivalLocation,
            arrivalDateTime: transit.arrivalDateTime,
            transitOption: transit.transitOption,
            expenseUpdator:
                ExpenseUpdator.fromTransitExpense(transitFacade: transit),
            departureDateTime: transit.departureDateTime,
            id: transit.id,
            confirmationId: transit.confirmationId,
            operator: transit.operator,
            notes: transit.notes,
            dataState: DataState.Created);

  TransitUpdator.createNewUIEntry({required String this.tripId})
      : dataState = DataState.None,
        transitOption = TransitOptions.PublicTransport;

  @override
  List<Object?> get props => [
        operator,
        confirmationId,
        id,
        notes,
        departureDateTime,
        arrivalDateTime,
        expenseUpdator,
        arrivalLocation,
        departureLocation,
        transitOption,
        tripId
      ];
}

class LodgingUpdator extends Equatable {
  LocationFacade? location;
  String? confirmationId;
  ExpenseUpdator? expenseUpdator;
  DateTime? checkinDateTime;
  DateTime? checkoutDateTime;
  String? id;
  String? notes;
  String? tripId;
  DataState dataState;

  LodgingUpdator._create(
      {this.location,
      this.confirmationId,
      this.expenseUpdator,
      this.checkinDateTime,
      this.id,
      this.notes,
      required this.tripId,
      this.checkoutDateTime,
      required this.dataState});

  LodgingUpdator.fromLodging({required LodgingFacade lodging})
      : this._create(
            location: lodging.location,
            confirmationId: lodging.confirmationId,
            expenseUpdator:
                ExpenseUpdator.fromLodgingExpense(lodgingFacade: lodging),
            checkinDateTime: lodging.checkinDateTime,
            id: lodging.id,
            notes: lodging.notes,
            tripId: lodging.tripId,
            checkoutDateTime: lodging.checkoutDateTime,
            dataState: DataState.None);

  LodgingUpdator clone() {
    return LodgingUpdator._create(
        tripId: tripId,
        dataState: dataState,
        location: location,
        confirmationId: confirmationId,
        expenseUpdator: expenseUpdator?.clone(),
        checkinDateTime: checkinDateTime,
        checkoutDateTime: checkoutDateTime,
        id: id,
        notes: notes);
  }

  LodgingUpdator.createNewUIEntry({required String this.tripId})
      : dataState = DataState.None;

  @override
  List<Object?> get props => [
        location,
        confirmationId,
        notes,
        expenseUpdator,
        checkinDateTime,
        id,
        tripId,
        checkoutDateTime
      ];
}

class ExpenseUpdator extends Equatable {
  CurrencyWithValue? totalExpense;
  String? id;
  String? description;
  ExpenseCategory? category;
  String? title;
  Map<String, double>? paidBy;
  List<String>? splitBy;
  DataState dataState;
  LocationFacade? location;
  String tripId;
  DateTime? dateTime;

  ExpenseUpdator clone() {
    return ExpenseUpdator._create(
        dataState: dataState,
        tripId: tripId,
        totalExpense: totalExpense != null
            ? CurrencyWithValue(
                currency: totalExpense!.currency, amount: totalExpense!.amount)
            : null,
        id: id,
        description: description,
        category: category,
        title: title,
        paidBy: paidBy != null ? Map.from(paidBy!) : null,
        splitBy: splitBy != null ? List.from(splitBy!) : null,
        location: location != null ? (location as Location).clone() : null,
        dateTime: dateTime);
  }

  ExpenseUpdator.fromExpense({required ExpenseFacade expense})
      : this._create(
            totalExpense: expense.totalExpense,
            id: expense.id,
            description: expense.description,
            category: expense.category,
            title: expense.title,
            paidBy: expense.paidBy,
            splitBy: expense.splitBy,
            dataState: DataState.None,
            location: expense.location,
            tripId: expense.tripId,
            dateTime: expense.dateTime);

  ExpenseUpdator.fromLodgingExpense({required LodgingFacade lodgingFacade})
      : this._create(
            totalExpense: lodgingFacade.expense.totalExpense,
            description: lodgingFacade.expense.description,
            category: lodgingFacade.expense.category,
            title: lodgingFacade.toString(),
            paidBy: lodgingFacade.expense.paidBy,
            splitBy: lodgingFacade.expense.splitBy,
            dataState: DataState.None,
            location: lodgingFacade.location,
            tripId: lodgingFacade.expense.tripId,
            dateTime: lodgingFacade.expense.dateTime);

  ExpenseUpdator.fromTransitExpense({required TransitFacade transitFacade})
      : this._create(
            totalExpense: transitFacade.expense.totalExpense,
            description: transitFacade.expense.description,
            category: transitFacade.expense.category,
            title: transitFacade.toString(),
            paidBy: transitFacade.expense.paidBy,
            splitBy: transitFacade.expense.splitBy,
            dataState: DataState.None,
            tripId: transitFacade.expense.tripId,
            dateTime: transitFacade.expense.dateTime);

  ExpenseUpdator.createNewUIEntry(
      {required String this.tripId,
      required String currentUserName,
      required List<String> tripContributors,
      required String currency,
      this.category = ExpenseCategory.Other})
      : dataState = DataState.None,
        totalExpense = CurrencyWithValue(currency: currency, amount: 0),
        paidBy = {
          currentUserName: 0,
        },
        splitBy = [currentUserName] {
    paidBy!.addEntries(tripContributors
        .where((element) => element != currentUserName)
        .map((e) => MapEntry(e, 0)));
  }

  ExpenseUpdator._create(
      {this.totalExpense,
      this.id,
      this.description,
      this.category,
      this.title,
      this.paidBy,
      this.splitBy,
      required this.dataState,
      this.location,
      required this.tripId,
      this.dateTime});

  @override
  List<Object?> get props => [
        totalExpense,
        id,
        description,
        category,
        title,
        paidBy,
        splitBy,
        location,
        tripId,
        dateTime
      ];
}

class PlanDataUpdator extends Equatable {
  String? id;
  String? title;
  LocationListUpdator? locationListUpdator;
  List<NoteUpdator>? noteUpdators;
  List<CheckListUpdator>? checkListUpdators;
  DataState dataState;
  final String tripId;

  PlanDataUpdator.createNewUIEntry({required this.tripId})
      : dataState = DataState.None;

  PlanDataUpdator.fromPlanData(
      {required PlanDataFacade planDataFacade, required this.tripId})
      : dataState = DataState.None,
        id = planDataFacade.id,
        title = planDataFacade.title,
        locationListUpdator = LocationListUpdator.fromLocationList(
            places: planDataFacade.places,
            planDataId: planDataFacade.id,
            tripId: tripId),
        noteUpdators = List.generate(
            planDataFacade.notes.length,
            (index) => NoteUpdator.fromNote(
                noteFacade: planDataFacade.notes.elementAt(index),
                planDataId: planDataFacade.id,
                tripId: tripId)),
        checkListUpdators = List.generate(
            planDataFacade.checkLists.length,
            (index) => CheckListUpdator.fromCheckList(
                checkListFacade: planDataFacade.checkLists.elementAt(index),
                tripId: tripId,
                planDataId: planDataFacade.id));

  PlanDataUpdator clone() {
    return PlanDataUpdator._create(
        dataState: dataState,
        tripId: tripId,
        id: id,
        title: title,
        locationListUpdator: locationListUpdator?.clone(),
        noteUpdators: noteUpdators != null
            ? List.generate(noteUpdators!.length,
                (index) => noteUpdators!.elementAt(index).clone())
            : null,
        checkListUpdators: checkListUpdators != null
            ? List.generate(checkListUpdators!.length,
                (index) => checkListUpdators!.elementAt(index).clone())
            : null);
  }

  PlanDataUpdator._create(
      {this.id,
      this.title,
      this.locationListUpdator,
      this.noteUpdators,
      this.checkListUpdators,
      required this.dataState,
      required this.tripId});

  @override
  List<Object?> get props =>
      [id, title, locationListUpdator, noteUpdators, checkListUpdators, tripId];
}

class LocationListUpdator extends Equatable {
  List<LocationFacade>? places;
  String? planDataId;
  DataState dataState;
  final String tripId;

  LocationListUpdator clone() {
    return LocationListUpdator._create(
        dataState: dataState,
        tripId: tripId,
        places: places != null ? List.from(places!) : null,
        planDataId: planDataId);
  }

  LocationListUpdator._create(
      {this.places,
      this.planDataId,
      required this.dataState,
      required this.tripId});

  LocationListUpdator.fromLocationList(
      {required List<LocationFacade> this.places,
      required this.planDataId,
      required this.tripId})
      : dataState = DataState.None;

  @override
  List<Object?> get props => [places, planDataId, tripId];
}

class CheckListUpdator extends Equatable {
  String? title;
  List<CheckListItem>? items;
  String? id;
  String? planDataId;
  final String tripId;
  DataState dataState;

  CheckListUpdator.createNewUIEntry(
      {required this.tripId, required this.planDataId})
      : dataState = DataState.None;

  CheckListUpdator clone() {
    return CheckListUpdator._create(
        dataState: dataState,
        tripId: tripId,
        title: title,
        id: id,
        planDataId: planDataId,
        items: items != null ? List.from(items!) : null);
  }

  CheckListUpdator._create(
      {this.title,
      this.id,
      this.planDataId,
      required this.dataState,
      required this.tripId,
      this.items});

  CheckListUpdator.fromCheckList(
      {required CheckListFacade checkListFacade,
      required this.tripId,
      required String this.planDataId})
      : dataState = DataState.None,
        title = checkListFacade.title,
        items = List.from(checkListFacade.items),
        id = checkListFacade.id;

  @override
  List<Object?> get props => [title, items, id, planDataId, tripId];
}

class NoteUpdator extends Equatable {
  String? id;
  String? planDataId;
  String? note;
  DataState dataState;
  final String tripId;

  NoteUpdator.createNewUIEntry({required this.tripId, required this.planDataId})
      : dataState = DataState.None;

  NoteUpdator clone() {
    return NoteUpdator._create(
        dataState: dataState,
        tripId: tripId,
        id: id,
        planDataId: planDataId,
        note: note);
  }

  NoteUpdator._create(
      {this.id,
      this.planDataId,
      this.note,
      required this.dataState,
      required this.tripId});

  NoteUpdator.fromNote(
      {required NoteFacade noteFacade,
      required this.tripId,
      required String this.planDataId})
      : dataState = DataState.None,
        id = noteFacade.id,
        note = noteFacade.note;

  @override
  List<Object?> get props => [id, planDataId, note, tripId];
}
