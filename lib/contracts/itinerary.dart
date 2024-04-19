import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/plan_data.dart';

import 'lodging.dart';
import 'transit.dart';

mixin ItineraryFacade {
  DateTime get day;

  UnmodifiableListView<TransitFacade> get transits;

  UnmodifiableListView<LodgingFacade> get lodgings;

  PlanDataFacade get planData;

  List calculateSortedEvents();

  bool isOnSameDayAs(DateTime dateTime);
}

abstract class ItineraryModifier with ItineraryFacade {
  set planData(PlanDataFacade planData);

  Future<bool> updatePlanData(PlanDataFacade planData);

  void addTransit(Transit transit);

  void addLodging(Lodging lodging);

  void removeTransit(Transit transit);

  void removeLodging(Lodging lodging);
}

class Itinerary with EquatableMixin implements ItineraryModifier {
  final List<Lodging> _lodgings;
  final List<Transit> _transits;

  @override
  PlanDataFacade get planData => _planData;
  PlanData _planData;
  @override
  set planData(PlanDataFacade planData) {
    _planData = planData as PlanData;
  }

  @override
  DateTime get day => _day;
  final DateTime _day;
  static const _dayField = 'day';

  final String tripId;

  @override
  Future<bool> updatePlanData(PlanDataFacade planData) async {
    return await _planData.updateItineraryData(
        planDataUpdator: PlanDataUpdator.fromPlanData(
            planDataFacade: planData, tripId: tripId),
        day: _day);
  }

  @override
  bool isOnSameDayAs(DateTime dateTime) {
    return day.day == dateTime.day &&
        day.month == dateTime.month &&
        day.year == dateTime.year;
  }

  @override
  UnmodifiableListView<LodgingFacade> get lodgings =>
      UnmodifiableListView(_lodgings);

  @override
  void addLodging(Lodging lodging) {
    _lodgings.add(lodging);
  }

  @override
  void removeLodging(Lodging lodging) {
    _lodgings.remove(lodging);
  }

  @override
  UnmodifiableListView<TransitFacade> get transits =>
      UnmodifiableListView(_transits);

  @override
  void addTransit(Transit transit) {
    _transits.add(transit);
  }

  @override
  void removeTransit(Transit transit) {
    _transits.remove(transit);
  }

  Itinerary.empty({required DateTime day, required this.tripId})
      : _day = day,
        _lodgings = [],
        _transits = [],
        _planData = PlanData.empty(tripId: tripId, isPlanDataList: false);

  Itinerary.withPlanData(
      {required DateTime day, required this.tripId, required PlanData planData})
      : _day = day,
        _lodgings = [],
        _transits = [],
        _planData = planData;

  static Future<Itinerary> fromDocumentSnapshot(
      {required String tripId,
      required QueryDocumentSnapshot<Map<String, dynamic>>
          documentSnapshot}) async {
    var planData = await PlanData.fromDocumentSnapshot(
        tripId: tripId,
        documentSnapshot: documentSnapshot,
        isPlanDataList: false);
    return Itinerary.withPlanData(
        day: (documentSnapshot[_dayField] as Timestamp).toDate(),
        tripId: tripId,
        planData: planData);
  }

  @override
  List calculateSortedEvents() {
    List sortedEvents = List.of(_transits);
    sortedEvents.sort((event1, event2) =>
        _getDateTimeFromEvent(event1).compareTo(_getDateTimeFromEvent(event2)));
    sortedEvents.addAll(List.of(_lodgings));
    return sortedEvents;
  }

  DateTime _getDateTimeFromEvent(dynamic event) {
    if (event is TransitFacade) {
      return event.departureDateTime;
    } else {
      return (event as LodgingFacade).checkinDateTime;
    }
  }

  @override
  List<Object?> get props => [_transits, _lodgings, _planData, _day];
}
