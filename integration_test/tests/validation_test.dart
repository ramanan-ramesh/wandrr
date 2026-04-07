/// Validation Rules Integration Tests
///
/// Tests all validation rules from requirements Section 23.
/// Covers: REQ-CT-002, REQ-ST-002, REQ-TR-002, REQ-TR-005, REQ-IPD-007,
/// REQ-EX-005, REQ-SE-003.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list_item.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/location/geo_location_api_context.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

import '../helpers/test_config.dart';

const _tripId = 'val_trip';
const _cur = 'EUR';
final _contribs = [TestConfig.testEmail, TestConfig.tripMateUserName];

ExpenseFacade _exp() => ExpenseFacade(
    currency: _cur, paidBy: {TestConfig.testEmail: 10.0}, splitBy: _contribs);

LocationFacade _loc() => LocationFacade(
    latitude: 48.85,
    longitude: 2.35,
    context: GeoLocationApiContext.fromDocument({
      'type': 'city',
      'locationType': 'city',
      'class': 'place',
      'name': 'Paris',
      'address': 'Paris, France',
      'boundingbox': {
        'maxLat': 48.9,
        'minLat': 48.8,
        'maxLon': 2.5,
        'minLon': 2.2
      },
      'place_id': 'test',
      'city': 'Paris',
      'state': 'IDF',
      'country': 'France',
    }));

/// REQ-CT-002 — TripMetadata validation.
Future<void> runTripMetadataValidationTest(
    WidgetTester tester, SharedPreferences sp) async {
  final v = TripMetadataFacade(
      id: _tripId,
      name: 'Trip',
      startDate: DateTime(2025, 10, 1),
      endDate: DateTime(2025, 10, 5),
      budget: Money(currency: 'INR', amount: 0),
      contributors: _contribs,
      thumbnailTag: 'roadTrip');
  expect(v.validate(), true);
  expect((v.clone()..name = '').validate(), false, reason: 'Empty name');
  expect((v.clone()..startDate = null).validate(), false, reason: 'No start');
  expect((v.clone()..endDate = null).validate(), false, reason: 'No end');
  expect(
      (v.clone()
            ..startDate = DateTime(2025, 10, 5)
            ..endDate = DateTime(2025, 10, 1))
          .validate(),
      false,
      reason: 'End < start');
  expect((v.clone()..endDate = DateTime(2025, 10, 1)).validate(), true,
      reason: 'Same day');
  print('✓ TripMetadata: 6 scenarios passed');
}

/// REQ-ST-002 — Lodging validation.
Future<void> runLodgingValidationTest(
    WidgetTester tester, SharedPreferences sp) async {
  final v = LodgingFacade(
      tripId: _tripId,
      location: _loc(),
      checkinDateTime: DateTime(2025, 10, 1, 14),
      checkoutDateTime: DateTime(2025, 10, 3, 11),
      expense: _exp());
  expect(v.validate(), true);
  expect((v.clone()..location = null).validate(), false, reason: 'No loc');
  expect(
      LodgingFacade(
              tripId: _tripId,
              location: _loc(),
              checkinDateTime: null,
              checkoutDateTime: DateTime(2025, 10, 3),
              expense: _exp())
          .validate(),
      false,
      reason: 'No checkin');
  expect(
      LodgingFacade(
              tripId: _tripId,
              location: _loc(),
              checkinDateTime: DateTime(2025, 10, 1),
              checkoutDateTime: null,
              expense: _exp())
          .validate(),
      false,
      reason: 'No checkout');
  expect(
      LodgingFacade(
              tripId: _tripId,
              location: _loc(),
              checkinDateTime: DateTime(2025, 10, 1),
              checkoutDateTime: DateTime(2025, 10, 3),
              expense: ExpenseFacade(currency: _cur, paidBy: {}, splitBy: []))
          .validate(),
      false,
      reason: 'Bad expense');
  print('✓ Lodging: 5 scenarios passed');
}

/// REQ-TR-002, REQ-TR-005 — Transit validation.
Future<void> runTransitValidationTest(
    WidgetTester tester, SharedPreferences sp) async {
  final v = TransitFacade(
      tripId: _tripId,
      transitOption: TransitOption.train,
      departureLocation: _loc(),
      arrivalLocation: _loc(),
      departureDateTime: DateTime(2025, 10, 1, 10),
      arrivalDateTime: DateTime(2025, 10, 1, 12),
      expense: _exp(),
      operator: 'RER');
  expect(v.validate(), true);
  expect((v.clone()..departureLocation = null).validate(), false);
  expect((v.clone()..arrivalLocation = null).validate(), false);
  expect((v.clone()..departureDateTime = null).validate(), false);
  expect((v.clone()..arrivalDateTime = null).validate(), false);
  expect(
      (v.clone()..arrivalDateTime = DateTime(2025, 10, 1, 9)).validate(), false,
      reason: 'Arr<dep');
  expect((v.clone()..arrivalDateTime = DateTime(2025, 10, 1, 10)).validate(),
      false,
      reason: 'Arr==dep');
  // Flight operator (REQ-TR-005)
  final f = TransitFacade(
      tripId: _tripId,
      transitOption: TransitOption.flight,
      departureLocation: _loc(),
      arrivalLocation: _loc(),
      departureDateTime: DateTime(2025, 10, 1, 10),
      arrivalDateTime: DateTime(2025, 10, 1, 14),
      expense: _exp(),
      operator: 'IndiGo 6E 2341');
  expect(f.validate(), true, reason: '≥3 tokens');
  expect((f.clone()..operator = 'IndiGo').validate(), false, reason: '1 token');
  expect((f.clone()..operator = 'IndiGo 6E').validate(), false,
      reason: '2 tokens');
  expect((f.clone()..operator = '').validate(), false);
  expect((f.clone()..operator = null).validate(), false);
  expect((f.clone()..operator = 'IndiGo 6E ').validate(), false,
      reason: 'Trailing space');
  // Walk
  expect(
      TransitFacade(
              tripId: _tripId,
              transitOption: TransitOption.walk,
              departureLocation: _loc(),
              arrivalLocation: _loc(),
              departureDateTime: DateTime(2025, 10, 1, 10),
              arrivalDateTime: DateTime(2025, 10, 1, 10, 30),
              expense: _exp())
          .validate(),
      true,
      reason: 'Walk no op');
  print('✓ Transit: 14 scenarios passed');
}

/// Sight validation.
Future<void> runSightValidationTest(
    WidgetTester tester, SharedPreferences sp) async {
  expect(
      SightFacade(
              tripId: _tripId,
              name: 'Eiffel Tower',
              day: DateTime(2025, 10, 1),
              expense: _exp())
          .validate(),
      true);
  expect(
      SightFacade(
              tripId: _tripId,
              name: '',
              day: DateTime(2025, 10, 1),
              expense: _exp())
          .validate(),
      false);
  expect(
      SightFacade(
              tripId: _tripId,
              name: 'Ab',
              day: DateTime(2025, 10, 1),
              expense: _exp())
          .validate(),
      false);
  expect(
      SightFacade(
              tripId: _tripId,
              name: 'Abc',
              day: DateTime(2025, 10, 1),
              expense: _exp())
          .validate(),
      true);
  print('✓ Sight: 4 scenarios passed');
}

/// CheckList validation.
Future<void> runCheckListValidationTest(
    WidgetTester tester, SharedPreferences sp) async {
  final item = CheckListItem(item: 'Passport', isChecked: false);
  expect(
      CheckListFacade(tripId: _tripId, title: 'Pack', items: [item]).validate(),
      true);
  expect(
      CheckListFacade(tripId: _tripId, title: null, items: [item]).validate(),
      false);
  expect(CheckListFacade(tripId: _tripId, title: '', items: [item]).validate(),
      false);
  expect(CheckListFacade(tripId: _tripId, title: 'Pack', items: []).validate(),
      false);
  expect(
      CheckListFacade(
          tripId: _tripId,
          title: 'Pack',
          items: [CheckListItem(item: '', isChecked: false)]).validate(),
      false);
  print('✓ CheckList: 5 scenarios passed');
}

/// REQ-IPD-007 — ItineraryPlanData validation.
Future<void> runItineraryPlanDataValidationTest(
    WidgetTester tester, SharedPreferences sp) async {
  final e = ItineraryPlanData(
      tripId: _tripId,
      day: DateTime(2025, 10, 1),
      sights: [],
      notes: [],
      checkLists: []);
  expect(e.validate(), true, reason: 'noContent=valid');
  expect(e.getValidationResult(), ItineraryPlanDataValidationResult.noContent);

  final vp =
      ItineraryPlanData(tripId: _tripId, day: DateTime(2025, 10, 1), sights: [
    SightFacade(
        tripId: _tripId,
        name: 'Tower',
        day: DateTime(2025, 10, 1),
        expense: _exp())
  ], notes: [
    'Note'
  ], checkLists: [
    CheckListFacade(
        tripId: _tripId,
        title: 'List',
        items: [CheckListItem(item: 'X', isChecked: false)])
  ]);
  expect(vp.validate(), true);

  expect(
      ItineraryPlanData(tripId: _tripId, day: DateTime(2025, 10, 1), sights: [
        SightFacade(
            tripId: _tripId,
            name: '',
            day: DateTime(2025, 10, 1),
            expense: _exp())
      ], notes: [], checkLists: []).getValidationResult(),
      ItineraryPlanDataValidationResult.sightInvalid);

  expect(
      ItineraryPlanData(
          tripId: _tripId,
          day: DateTime(2025, 10, 1),
          sights: [],
          notes: [''],
          checkLists: []).getValidationResult(),
      ItineraryPlanDataValidationResult.noteEmpty);

  expect(
      ItineraryPlanData(
          tripId: _tripId,
          day: DateTime(2025, 10, 1),
          sights: [],
          notes: [],
          checkLists: [
            CheckListFacade(
                tripId: _tripId,
                title: 'AB',
                items: [CheckListItem(item: 'X', isChecked: false)])
          ]).getValidationResult(),
      ItineraryPlanDataValidationResult.checkListTitleNotValid);

  expect(
      ItineraryPlanData(
          tripId: _tripId,
          day: DateTime(2025, 10, 1),
          sights: [],
          notes: [],
          checkLists: [
            CheckListFacade(tripId: _tripId, title: 'Pack', items: [])
          ]).getValidationResult(),
      ItineraryPlanDataValidationResult.checkListItemEmpty);

  expect(
      ItineraryPlanData(
          tripId: _tripId,
          day: DateTime(2025, 10, 1),
          sights: [],
          notes: [],
          checkLists: [
            CheckListFacade(
                tripId: _tripId,
                title: 'Pack',
                items: [CheckListItem(item: '', isChecked: false)])
          ]).getValidationResult(),
      ItineraryPlanDataValidationResult.checkListItemEmpty);
  print('✓ ItineraryPlanData: 7 scenarios passed');
}

/// REQ-EX-005 — ExpenseFacade validation.
Future<void> runExpenseFacadeValidationTest(
    WidgetTester tester, SharedPreferences sp) async {
  expect(
      ExpenseFacade(
              currency: _cur,
              paidBy: {TestConfig.testEmail: 100},
              splitBy: _contribs)
          .validate(),
      true);
  expect(
      ExpenseFacade(currency: _cur, paidBy: {}, splitBy: _contribs).validate(),
      false);
  expect(
      ExpenseFacade(
          currency: _cur,
          paidBy: {TestConfig.testEmail: 100},
          splitBy: []).validate(),
      false);
  expect(
      ExpenseFacade(currency: _cur, paidBy: {}, splitBy: []).validate(), false);
  expect(
      ExpenseFacade(
          currency: _cur,
          paidBy: {TestConfig.testEmail: 0},
          splitBy: [TestConfig.testEmail]).validate(),
      true);
  print('✓ ExpenseFacade: 5 scenarios passed');
}

/// REQ-SE-003 — StandaloneExpense validation.
Future<void> runStandaloneExpenseValidationTest(
    WidgetTester tester, SharedPreferences sp) async {
  expect(
      StandaloneExpense(tripId: _tripId, title: 'X', expense: _exp())
          .validate(),
      true);
  expect(
      StandaloneExpense(
              tripId: _tripId,
              title: 'X',
              expense: ExpenseFacade(currency: _cur, paidBy: {}, splitBy: []))
          .validate(),
      false);
  print('✓ StandaloneExpense: 2 scenarios passed');
}
