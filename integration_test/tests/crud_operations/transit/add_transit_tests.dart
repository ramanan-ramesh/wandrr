/// Transit creation integration tests.
///
/// Covers: REQ-TR-001, REQ-TR-002, REQ-TR-003, REQ-TR-004, REQ-TR-005,
/// REQ-TR-006, REQ-BU-001.
///
/// Each "add" test:
///   1. Opens the Creator bottom-sheet -> selects "Travel Entry".
///   2. Fills every visible field appropriate for the transit type.
///   3. Subscribes to transitCollection.onDocumentAdded.
///   4. Taps the ConflictAwareActionPage FAB (check icon).
///   5. Awaits the newly-added TransitFacade from the stream.
///   6. Verifies the bottom-sheet (TravelEditor) is fully dismissed.
///   7. Navigates to the correct itinerary day and asserts the timeline entry
///      using TransitFacade properties (no hardcoded strings).
///   8. Navigates to the Budgeting tab and asserts the expense list entry using
///      TransitFacade properties when the transit carries an expense.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expenses_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/journey_editor.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/transit_option_metadata.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/travel_editor.dart';

import '../../../helpers/test_config.dart';
import '../../../helpers/test_helpers.dart';
import '../../itinerary_viewer/helpers.dart';
import '../helpers.dart';
import 'helpers.dart';

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Shared form accessor
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

final _form = TravelEditorForm();

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// REQ-TR-003 – Default state of TravelEditor per transit type
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/// REQ-TR-003
/// When the Creator bottom-sheet is opened and "Travel Entry" is tapped, the
/// TravelEditor must show the correct fields for each transit type:
///   – walk / vehicle (free travel): no expense/operator/confirmation/airport fields;
///     two geo-location fields.
///   – All other types (bookable travel): expense editor (PaidBy+SplitBy with
///     correct contributors, amounts default to 0), operator field (except
///     rentedVehicle), confirmation ID field, and correct location fields.
///   – Flights specifically: airline name auto-complete (no flight-number until
///     an airline is selected), two airport auto-complete fields.
///   – ALL types: note field and two date-time pickers.
Future<void> runVerifyDefaultStateTest(WidgetTester tester) async {
  print(
      'REQ-TR-003: Verify default field state of TravelEditor per transit type');
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await _openTransitCreatorPage(tester);
  await _verifyTransitOptions(tester, TransitOption.publicTransport);

  final tripMetadata =
      TestHelpers.getTripRepository(tester).activeTrip!.tripMetadata;

  for (final transitOption in TransitOption.values) {
    await _form.selectTransitOption(tester, transitOption);

    if (_isFreeTravelOption(transitOption)) {
      await _verifyFreeTravelFields(tester, transitOption);
    } else {
      await _verifyBookableTransitFields(tester, transitOption, tripMetadata);
    }

    await _verifyCommonFields(tester, transitOption);
  }
}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// REQ-TR-001 – Add Walk transit
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/// REQ-TR-001, REQ-TR-002
Future<void> runAddWalkTransitTest(WidgetTester tester) async {
  print('REQ-TR-001, REQ-TR-002: Add Walk transit and verify timeline entry');
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await _openTransitCreatorPage(tester);
  await _form.selectTransitOption(tester, TransitOption.walk);

  final repo = TestHelpers.getTripRepository(tester);
  final tripStartDate = repo.activeTrip!.tripMetadata.startDate!;
  final dayItinerary =
      repo.activeTrip!.itineraryCollection.getItineraryForDay(tripStartDate);
  final departureName = dayItinerary.checkInLodging!.location!.context.name;
  final arrivalName = dayItinerary.planData.sights.first.location!.context.name;

  await _form.selectDepartureAndArrivalGeoLocations(
      tester, departureName, arrivalName);

  final departureTime = tripStartDate.copyWith(hour: 14, minute: 10);
  final arrivalTime = tripStartDate.copyWith(hour: 15, minute: 20);
  await _setTimes(tester, tripStartDate, departureTime, arrivalTime);
  await TestHelpers.enterText(
      tester, _form.commonFormElements.noteEditingField, 'Morning stroll');

  await _submitAndVerify(tester, onTransitAdded: (transit) async {
    print('[OK] Transit added: ${transit.toString()} (id: ${transit.id})');
    await TestHelpers.navigateToDateInItineraryViewer(
        tester, transit.departureDateTime!);
    await verifyTransitTimelineEntry(
      tester,
      day: transit.departureDateTime!,
      locationPair:
          '${transit.departureLocation} -> ${transit.arrivalLocation}',
      note: transit.notes,
    );
    await TestHelpers.navigateToBudgetingTab(tester);
    await _verifyNoExpenseEntry(tester, title: transit.toString());
  });
}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// REQ-TR-001 – Add Personal-Vehicle transit
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/// REQ-TR-001, REQ-TR-002
Future<void> runAddPersonalVehicleTransitTest(WidgetTester tester) async {
  print(
      'REQ-TR-001, REQ-TR-002: Add PersonalVehicle transit and verify timeline entry');
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await _openTransitCreatorPage(tester);
  await _form.selectTransitOption(tester, TransitOption.vehicle);

  final repo = TestHelpers.getTripRepository(tester);
  final tripStartDate = repo.activeTrip!.tripMetadata.startDate!;
  final day = tripStartDate.add(const Duration(days: 1)); // Sep 25
  const departureLocation = 'Paris';
  const arrivalLocation = 'Versailles';
  final departureTime = day.copyWith(hour: 8);
  final arrivalTime = day.copyWith(hour: 9);

  await _form.selectDepartureAndArrivalGeoLocations(
      tester, departureLocation, arrivalLocation);
  await _setTimes(tester, day, departureTime, arrivalTime);
  await TestHelpers.enterText(
      tester, _form.commonFormElements.noteEditingField, 'Road trip');
  print('[OK] Fields filled for PersonalVehicle');

  await _submitAndVerify(tester, onTransitAdded: (transit) async {
    print('[OK] Transit added: ${transit.toString()} (id: ${transit.id})');
    await TestHelpers.navigateToDateInItineraryViewer(
        tester, transit.departureDateTime!);
    await verifyTransitTimelineEntry(
      tester,
      day: transit.departureDateTime!,
      locationPair:
          '${transit.departureLocation} -> ${transit.arrivalLocation}',
      note: transit.notes,
    );
    print('[OK] PersonalVehicle timeline entry verified');
    await TestHelpers.navigateToBudgetingTab(tester);
    await _verifyNoExpenseEntry(tester, title: transit.toString());
    print('[OK] PersonalVehicle: no expense entry (free travel)');
  });
}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// REQ-TR-001 – Add Public-Transport transit
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/// REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001
Future<void> runAddPublicTransportTransitTest(WidgetTester tester) async {
  print(
      'REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001: Add PublicTransport transit');
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await _openTransitCreatorPage(tester);
  await _form.selectTransitOption(tester, TransitOption.publicTransport);
  print('[OK] Transit type set to PublicTransport');

  final repo = TestHelpers.getTripRepository(tester);
  final tripStartDate = repo.activeTrip!.tripMetadata.startDate!;
  final day = tripStartDate.add(const Duration(days: 4)); // Sep 28

  await _fillBookableForm(
    tester,
    option: TransitOption.publicTransport,
    operator: 'Amsterdam Metro',
    confirmationId: 'AM-PUB-001',
    departure: 'Rijksmuseum',
    arrival: 'Amsterdam',
    departureTime: day.copyWith(hour: 14),
    arrivalTime: day.copyWith(hour: 14, minute: 30),
    tripStartDate: day,
    expenseAmount: '3',
    note: 'Metro line 52',
  );

  await _submitAndVerify(tester, onTransitAdded: (transit) async {
    print('[OK] Transit added: ${transit.toString()} (id: ${transit.id})');
    await TestHelpers.navigateToDateInItineraryViewer(
        tester, transit.departureDateTime!);
    await verifyTransitTimelineEntry(
      tester,
      day: transit.departureDateTime!,
      locationPair:
          '${transit.departureLocation} -> ${transit.arrivalLocation}',
      operator: transit.operator,
      confirmationId: transit.confirmationId,
      note: transit.notes,
    );
    print('[OK] PublicTransport timeline entry verified');
    await TestHelpers.navigateToBudgetingTab(tester);
    await _verifyExpenseEntry(
      tester,
      expectedTitle: transit.toString(),
      expectedCategoryIcon: iconsForCategories[transit.category]!,
    );
    print('[OK] PublicTransport expense list entry verified');
  });
}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// REQ-TR-001 – Add Bus transit
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/// REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001
Future<void> runAddBusTransitTest(WidgetTester tester) async {
  print('REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001: Add Bus transit');
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await _openTransitCreatorPage(tester);
  await _form.selectTransitOption(tester, TransitOption.bus);
  print('[OK] Transit type set to Bus');

  final repo = TestHelpers.getTripRepository(tester);
  final tripStartDate = repo.activeTrip!.tripMetadata.startDate!;
  final day = tripStartDate.add(const Duration(days: 2)); // Sep 26

  await _fillBookableForm(
    tester,
    option: TransitOption.bus,
    operator: 'FlixBus',
    confirmationId: 'FLIX-NEW-001',
    departure: 'Paris',
    arrival: 'Brussels',
    departureTime: day.copyWith(hour: 22),
    arrivalTime: day.add(const Duration(days: 1)).copyWith(hour: 2, minute: 30),
    tripStartDate: day,
    expenseAmount: '35',
    note: 'Overnight bus',
  );

  await _submitAndVerify(tester, onTransitAdded: (transit) async {
    print('[OK] Transit added: ${transit.toString()} (id: ${transit.id})');
    await TestHelpers.navigateToDateInItineraryViewer(
        tester, transit.departureDateTime!);
    await verifyTransitTimelineEntry(
      tester,
      day: transit.departureDateTime!,
      locationPair:
          '${transit.departureLocation} -> ${transit.arrivalLocation}',
      operator: transit.operator,
      confirmationId: transit.confirmationId,
      note: transit.notes,
    );
    print('[OK] Bus timeline entry verified');
    await TestHelpers.navigateToBudgetingTab(tester);
    await _verifyExpenseEntry(
      tester,
      expectedTitle: transit.toString(),
      expectedCategoryIcon: iconsForCategories[transit.category]!,
    );
    print('[OK] Bus expense list entry verified');
  });
}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// REQ-TR-001 – Add Train transit
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/// REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001
Future<void> runAddTrainTransitTest(WidgetTester tester) async {
  print('REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001: Add Train transit');
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await _openTransitCreatorPage(tester);
  await _form.selectTransitOption(tester, TransitOption.train);
  print('[OK] Transit type set to Train');

  final repo = TestHelpers.getTripRepository(tester);
  final tripStartDate = repo.activeTrip!.tripMetadata.startDate!;
  final day = tripStartDate.add(const Duration(days: 1)); // Sep 25

  await _fillBookableForm(
    tester,
    option: TransitOption.train,
    operator: 'Eurostar',
    confirmationId: 'EURO-001',
    departure: 'Paris',
    arrival: 'Brussels',
    departureTime: day.copyWith(hour: 9),
    arrivalTime: day.copyWith(hour: 11),
    tripStartDate: day,
    expenseAmount: '60',
    note: 'High-speed train',
  );

  await _submitAndVerify(tester, onTransitAdded: (transit) async {
    print('[OK] Transit added: ${transit.toString()} (id: ${transit.id})');
    await TestHelpers.navigateToDateInItineraryViewer(
        tester, transit.departureDateTime!);
    await verifyTransitTimelineEntry(
      tester,
      day: transit.departureDateTime!,
      locationPair:
          '${transit.departureLocation} -> ${transit.arrivalLocation}',
      operator: transit.operator,
      confirmationId: transit.confirmationId,
      note: transit.notes,
    );
    print('[OK] Train timeline entry verified');
    await TestHelpers.navigateToBudgetingTab(tester);
    await _verifyExpenseEntry(
      tester,
      expectedTitle: transit.toString(),
      expectedCategoryIcon: iconsForCategories[transit.category]!,
    );
    print('[OK] Train expense list entry verified');
  });
}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// REQ-TR-001 – Add Taxi transit
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/// REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001
Future<void> runAddTaxiTransitTest(WidgetTester tester) async {
  print('REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001: Add Taxi transit');
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await _openTransitCreatorPage(tester);
  await _form.selectTransitOption(tester, TransitOption.taxi);
  print('[OK] Transit type set to Taxi');

  final repo = TestHelpers.getTripRepository(tester);
  final tripStartDate = repo.activeTrip!.tripMetadata.startDate!;
  final day = tripStartDate.add(const Duration(days: 3)); // Sep 27

  await _fillBookableForm(
    tester,
    option: TransitOption.taxi,
    operator: 'Uber',
    confirmationId: 'UBER-002',
    departure: 'Atomium',
    arrival: 'Brussels',
    departureTime: day.copyWith(hour: 16),
    arrivalTime: day.copyWith(hour: 16, minute: 30),
    tripStartDate: day,
    expenseAmount: '25',
    note: 'Quick ride',
  );

  await _submitAndVerify(tester, onTransitAdded: (transit) async {
    print('[OK] Transit added: ${transit.toString()} (id: ${transit.id})');
    await TestHelpers.navigateToDateInItineraryViewer(
        tester, transit.departureDateTime!);
    await verifyTransitTimelineEntry(
      tester,
      day: transit.departureDateTime!,
      locationPair:
          '${transit.departureLocation} -> ${transit.arrivalLocation}',
      operator: transit.operator,
      confirmationId: transit.confirmationId,
      note: transit.notes,
    );
    print('[OK] Taxi timeline entry verified');
    await TestHelpers.navigateToBudgetingTab(tester);
    await _verifyExpenseEntry(
      tester,
      expectedTitle: transit.toString(),
      expectedCategoryIcon: iconsForCategories[transit.category]!,
    );
    print('[OK] Taxi expense list entry verified');
  });
}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// REQ-TR-001 – Add Ferry transit
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/// REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001
Future<void> runAddFerryTransitTest(WidgetTester tester) async {
  print('REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001: Add Ferry transit');
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await _openTransitCreatorPage(tester);
  await _form.selectTransitOption(tester, TransitOption.ferry);
  print('[OK] Transit type set to Ferry');

  final repo = TestHelpers.getTripRepository(tester);
  final tripStartDate = repo.activeTrip!.tripMetadata.startDate!;
  final day = tripStartDate.add(const Duration(days: 3)); // Sep 27

  await _fillBookableForm(
    tester,
    option: TransitOption.ferry,
    operator: 'P&O Ferries',
    confirmationId: 'PO-NEW-001',
    departure: 'Brussels',
    arrival: 'Amsterdam',
    departureTime: day.copyWith(hour: 18),
    arrivalTime: day.copyWith(hour: 21),
    tripStartDate: day,
    expenseAmount: '45',
    note: 'Scenic route',
  );

  await _submitAndVerify(tester, onTransitAdded: (transit) async {
    print('[OK] Transit added: ${transit.toString()} (id: ${transit.id})');
    await TestHelpers.navigateToDateInItineraryViewer(
        tester, transit.departureDateTime!);
    await verifyTransitTimelineEntry(
      tester,
      day: transit.departureDateTime!,
      locationPair:
          '${transit.departureLocation} -> ${transit.arrivalLocation}',
      operator: transit.operator,
      confirmationId: transit.confirmationId,
      note: transit.notes,
    );
    print('[OK] Ferry timeline entry verified');
    await TestHelpers.navigateToBudgetingTab(tester);
    await _verifyExpenseEntry(
      tester,
      expectedTitle: transit.toString(),
      expectedCategoryIcon: iconsForCategories[transit.category]!,
    );
    print('[OK] Ferry expense list entry verified');
  });
}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// REQ-TR-001 – Add Rented-Vehicle transit
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/// REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001
/// RentedVehicle: has expense + confirmation, but no operator field.
Future<void> runAddRentedVehicleTransitTest(WidgetTester tester) async {
  print(
      'REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001: Add RentedVehicle transit');
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await _openTransitCreatorPage(tester);
  await _form.selectTransitOption(tester, TransitOption.rentedVehicle);
  print('[OK] Transit type set to RentedVehicle');

  final repo = TestHelpers.getTripRepository(tester);
  final tripStartDate = repo.activeTrip!.tripMetadata.startDate!;
  final day = tripStartDate.add(const Duration(days: 3)); // Sep 27

  await _fillBookableForm(
    tester,
    option: TransitOption.rentedVehicle,
    operator: null,
    // rentedVehicle has no operator field
    confirmationId: 'HERTZ-NEW-001',
    departure: 'Brussels',
    arrival: 'Atomium',
    departureTime: day.copyWith(hour: 10),
    arrivalTime: day.copyWith(hour: 10, minute: 30),
    tripStartDate: day,
    expenseAmount: '60',
    note: 'Full day rental',
  );

  await _submitAndVerify(tester, onTransitAdded: (transit) async {
    print('[OK] Transit added: ${transit.toString()} (id: ${transit.id})');
    await TestHelpers.navigateToDateInItineraryViewer(
        tester, transit.departureDateTime!);
    await verifyTransitTimelineEntry(
      tester,
      day: transit.departureDateTime!,
      locationPair:
          '${transit.departureLocation} -> ${transit.arrivalLocation}',
      confirmationId: transit.confirmationId,
      note: transit.notes,
    );
    print('[OK] RentedVehicle timeline entry verified');
    await TestHelpers.navigateToBudgetingTab(tester);
    await _verifyExpenseEntry(
      tester,
      expectedTitle: transit.toString(),
      expectedCategoryIcon: iconsForCategories[transit.category]!,
    );
    print('[OK] RentedVehicle expense list entry verified');
  });
}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// REQ-TR-001 – Add Cruise transit
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/// REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001
Future<void> runAddCruiseTransitTest(WidgetTester tester) async {
  print('REQ-TR-001, REQ-TR-002, REQ-TR-004, REQ-BU-001: Add Cruise transit');
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  await _openTransitCreatorPage(tester);
  await _form.selectTransitOption(tester, TransitOption.cruise);
  print('[OK] Transit type set to Cruise');

  final repo = TestHelpers.getTripRepository(tester);
  final tripStartDate = repo.activeTrip!.tripMetadata.startDate!;
  final day = tripStartDate.add(const Duration(days: 4)); // Sep 28

  await _fillBookableForm(
    tester,
    option: TransitOption.cruise,
    operator: 'Royal Caribbean',
    confirmationId: 'RC-NEW-001',
    departure: 'Amsterdam',
    arrival: 'Brussels',
    departureTime: day.copyWith(hour: 9),
    arrivalTime: day.copyWith(hour: 18),
    tripStartDate: day,
    expenseAmount: '200',
    note: 'Day cruise',
  );

  await _submitAndVerify(tester, onTransitAdded: (transit) async {
    print('[OK] Transit added: ${transit.toString()} (id: ${transit.id})');
    await TestHelpers.navigateToDateInItineraryViewer(
        tester, transit.departureDateTime!);
    await verifyTransitTimelineEntry(
      tester,
      day: transit.departureDateTime!,
      locationPair:
          '${transit.departureLocation} -> ${transit.arrivalLocation}',
      operator: transit.operator,
      confirmationId: transit.confirmationId,
      note: transit.notes,
    );
    print('[OK] Cruise timeline entry verified');
    await TestHelpers.navigateToBudgetingTab(tester);
    await _verifyExpenseEntry(
      tester,
      expectedTitle: transit.toString(),
      expectedCategoryIcon: iconsForCategories[transit.category]!,
    );
    print('[OK] Cruise expense list entry verified');
  });
}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// ->-> Predicates ->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->

/// Returns true for transit types that carry no expense and no operator.
bool _isFreeTravelOption(TransitOption option) =>
    option == TransitOption.walk || option == TransitOption.vehicle;

// ->-> Navigation ->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->

/// Opens the Creator bottom-sheet then taps "Travel Entry".
Future<void> _openTransitCreatorPage(WidgetTester tester) async {
  await openCreatorAndNavigateToEditor(
    tester,
    entityName: 'Transit',
    icon: Icons.flight,
    title: 'Travel Entry',
    subTitle: 'Add transit information',
    editorType: TravelEditor,
  );
  print('[OK] Transit creator opened');
}

// ->-> Submit & capture ->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->

/// Taps the ConflictAwareActionPage FAB to submit the transit form.
///
/// Before tapping, subscribes to [transitCollection.onDocumentAdded].
/// The ConflictAwareActionPage shows a loading spinner on the FAB and waits
/// for the Firestore operation to complete before auto-popping. We keep
/// pumping so platform-channel responses are delivered, and once the editor
/// is dismissed we know the add has completed and the stream has fired.
///
/// Throws [TestFailure] if the editor is not dismissed within 15 s.
Future<void> _submitAndVerify(
  WidgetTester tester, {
  required Future<void> Function(TransitFacade transit) onTransitAdded,
}) async {
  // Subscribe BEFORE tapping so no event is missed.
  final collection =
      TestHelpers.getTripRepository(tester).activeTrip!.transitCollection;
  final completer = Completer<TransitFacade>();
  late StreamSubscription<CollectionItemChangeMetadata<TransitFacade>> sub;
  sub = collection.onDocumentAdded.listen((event) {
    if (event.isFromExplicitAction && !completer.isCompleted) {
      completer.complete(event.modifiedCollectionItem);
      sub.cancel();
    }
  });

  final fab = _form.commonFormElements.createTripEntityButton;
  expect(fab, findsOneWidget,
      reason: 'ConflictAwareActionPage submit FAB must be present and enabled');
  await TestHelpers.tapWidget(tester, fab);
  print('[OK] Tapped ConflictAwareActionPage FAB -> submitted transit');

  // The ConflictAwareActionPage now shows a loading spinner on the FAB and
  // waits for the TripManagementBloc to emit UpdatedTripEntity before popping.
  // Keep pumping so that:
  //  1. Platform-channel responses from the Firestore emulator are delivered
  //     back to Dart, allowing _typedCollectionReference.add() to complete.
  //  2. The BLoC emits UpdatedTripEntity → ConflictAwareActionPage pops.
  // final deadline = DateTime.now().add(const Duration(seconds: 15));
  // while (DateTime.now().isBefore(deadline)) {
  //   await tester.pump(const Duration(milliseconds: 200));
  //   if (find.byType(TravelEditor).evaluate().isEmpty) {
  //     break;
  //   }
  // }
  await Future.delayed(Duration(seconds: 5), () {
    if (find.byType(TravelEditor).evaluate().isEmpty) {
      return;
    }
  });

  // Verify TravelEditor is dismissed (i.e. the operation completed).
  expect(find.byType(TravelEditor), findsNothing,
      reason:
          'TravelEditor must be dismissed after Firestore operation completes');
  print('[OK] Bottom-sheet dismissed');

  // The transit should now be available from the stream.
  TransitFacade? transit;
  if (completer.isCompleted) {
    transit = await completer.future;
  } else {
    // Give a little more time for the stream event to fire.
    transit = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        sub.cancel();
        throw TestFailure(
            'transitCollection.onDocumentAdded did not fire after editor dismissal');
      },
    );
  }
  sub.cancel();

  print(
      '[OK] transitCollection.onDocumentAdded received: ${transit.toString()} (id: ${transit.id})');

  // Settle the UI after the repository update, then run verifications.
  await tester.pumpAndSettle();
  await onTransitAdded(transit);
}

// ->-> Form filling ->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->

/// Fills the transit form for a bookable transit type.
/// [operator] may be null for types that have no operator field (rentedVehicle).
Future<void> _fillBookableForm(
  WidgetTester tester, {
  required TransitOption option,
  required String? operator,
  required String confirmationId,
  required String departure,
  required String arrival,
  required DateTime departureTime,
  required DateTime arrivalTime,
  required DateTime tripStartDate,
  required String expenseAmount,
  required String note,
}) async {
  // Operator (shown for most types; not for rentedVehicle).
  if (operator != null) {
    await TestHelpers.enterText(
        tester, _form.transitOperatorEditingField, operator);
    print('  [OK] Operator "$operator" entered');
  }

  // Location fields.
  if (option != TransitOption.flight) {
    await _form.selectDepartureAndArrivalGeoLocations(
        tester, departure, arrival);
  }

  // Date / times.
  await _setTimes(tester, tripStartDate, departureTime, arrivalTime);

  // Confirmation ID.
  await TestHelpers.enterText(
      tester, _form.confirmationIdEditingField, confirmationId);
  print('  [OK] Confirmation ID "$confirmationId" entered');

  // Expense amount (first contributor in PaidBy tab).
  await _form.commonFormElements.expenseEditor.switchToPaidByTab(tester);
  final amountField = find.descendant(
    of: _form.commonFormElements.expenseEditor.paidByTabContributorTile.first,
    matching: find.byKey(const ValueKey('ExpenseAmountEditField_TextField')),
  );
  await TestHelpers.enterText(tester, amountField, expenseAmount);
  print('  [OK] Expense amount "$expenseAmount" entered');

  // Note.
  await TestHelpers.enterText(
      tester, _form.commonFormElements.noteEditingField, note);
  print('  [OK] Note "$note" entered');
}

Future<void> _setTimes(
  WidgetTester tester,
  DateTime tripStartDate,
  DateTime departureTime,
  DateTime arrivalTime,
) async {
  await _form.commonFormElements.selectDateTime(tester,
      dateTime: departureTime,
      startDateTime: tripStartDate,
      indexOfDateTimePicker: 0);
  await _form.commonFormElements.selectDateTime(tester,
      dateTime: arrivalTime,
      startDateTime: departureTime,
      indexOfDateTimePicker: 1);
  print(
      '[OK] Times ${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')} -> ${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')} set');
}

// ->-> Expense-list verification ->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->

/// Asserts an expense list entry with [expectedTitle] and [expectedCategoryIcon].
Future<void> _verifyExpenseEntry(
  WidgetTester tester, {
  required String expectedTitle,
  required IconData expectedCategoryIcon,
}) async {
  final listView = find.byKey(const ValueKey('ExpensesListView_ListView'));
  final listScrollable =
      find.ancestor(of: listView, matching: find.byType(ListView)).first;

  final found = await TestHelpers.scrollUntilPresent(
    tester,
    scrollableFinder: listScrollable,
    widgetFinder: find.text(expectedTitle),
    reason: 'Expense list must contain "$expectedTitle"',
  );
  expect(found, isTrue,
      reason: 'Expense list entry "$expectedTitle" not found');
  print('  [OK] Expense list entry found: "$expectedTitle"');

  final card = find
      .ancestor(of: find.text(expectedTitle), matching: find.byType(Material))
      .first;
  expect(
    find.descendant(of: card, matching: find.byIcon(expectedCategoryIcon)),
    findsAtLeastNWidgets(1),
    reason:
        'Category icon must appear alongside "$expectedTitle" in expense list',
  );
  print('  [OK] Category icon present for "$expectedTitle"');
}

/// Asserts that [title] is NOT present in the expense list (used for zero-cost transits).
Future<void> _verifyNoExpenseEntry(WidgetTester tester,
    {required String title}) async {
  final listView = find.byKey(const ValueKey('ExpensesListView_ListView'));
  if (listView.evaluate().isEmpty) {
    print('  [OK] Expense list not visible – zero-cost transit not included');
    return;
  }
  await TestHelpers.scrollGuardVerifyNotPresent(
    tester,
    scrollableFinder: listView,
    widgetFinder: find.text(title),
    reason: 'Expense list should not contain "$title" (zero-cost transit)',
  );
  print('  [OK] Confirmed "$title" absent from expense list (zero-cost)');
}

// ->-> Default-state field verification ->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->

/// Verifies fields for walk / vehicle (free travel, no expense/operator/confirmation).
Future<void> _verifyFreeTravelFields(
    WidgetTester tester, TransitOption option) async {
  await _verifyAbsent(
      tester,
      _form.commonFormElements.expenseEditor.paidByTabContributorTile,
      '${option.name}: PaidBy tile must NOT be shown');
  await _verifyAbsent(
      tester,
      _form.commonFormElements.expenseEditor.splitByContributorTile,
      '${option.name}: SplitBy tile must NOT be shown');
  await _verifyAbsent(
      tester,
      find.descendant(
          of: _form.commonFormElements.expenseEditor.paidByTabContributorTile,
          matching:
              find.byKey(const ValueKey('ExpenseAmountEditField_TextField'))),
      '${option.name}: expense amount field must NOT be shown');
  await _verifyAbsent(tester, _form.transitOperatorEditingField,
      '${option.name}: operator field must NOT be shown');
  await _verifyAbsent(tester, _form.airportLocationAutoCompleteTextField,
      '${option.name}: airport auto-complete must NOT be shown');
  await _verifyPresent(
      tester,
      _form.geoLocationAutoCompleteTextField,
      findsNWidgets(2),
      '${option.name}: exactly 2 geo-location fields must be shown');
  print(
      '  -> ${option.name}: free-travel fields verified (expense/operator hidden, 2 location fields shown)');
}

/// Verifies fields for bookable transit types (non-walk, non-vehicle).
Future<void> _verifyBookableTransitFields(
    WidgetTester tester, TransitOption option, dynamic tripMetadata) async {
  final contributorCount = (tripMetadata.contributors as List).length;

  await _form.commonFormElements.expenseEditor.switchToPaidByTab(tester);

  final paidByTile =
      _form.commonFormElements.expenseEditor.paidByTabContributorTile;
  final amountFields = find.descendant(
    of: paidByTile,
    matching: find.byKey(const ValueKey('ExpenseAmountEditField_TextField')),
  );

  expect(paidByTile, findsNWidgets(contributorCount),
      reason:
          '${option.name}: $contributorCount PaidBy contributor tiles must be shown');
  expect(amountFields, findsNWidgets(contributorCount),
      reason:
          '${option.name}: $contributorCount expense amount fields must be shown');

  for (final tf in tester.widgetList<TextField>(amountFields)) {
    expect(double.tryParse(tf.controller?.text ?? ''), isNotNull,
        reason: '${option.name}: expense amount must be a parseable number');
    expect(double.parse(tf.controller!.text), 0.0,
        reason: '${option.name}: expense amount must default to 0');
  }

  expect(find.descendant(of: paidByTile, matching: find.text('You')),
      findsOneWidget,
      reason: '${option.name}: "You" must appear in PaidBy');
  expect(
    find.descendant(
        of: paidByTile,
        matching: find.text(TestConfig.tripMateUserName.split('@').first)),
    findsOneWidget,
    reason: '${option.name}: tripmate must appear in PaidBy',
  );

  await _form.commonFormElements.expenseEditor.switchToSplitTab(tester);

  final splitByTile =
      _form.commonFormElements.expenseEditor.splitByContributorTile;
  expect(splitByTile, findsNWidgets(contributorCount),
      reason: '${option.name}: $contributorCount SplitBy tiles must be shown');
  for (final lt in tester.widgetList<ListTile>(splitByTile)) {
    expect(lt.selected, isTrue,
        reason:
            '${option.name}: every SplitBy entry must be selected by default');
  }

  await _verifyPresent(tester, _form.confirmationIdEditingField, findsOneWidget,
      '${option.name}: Confirmation ID field must be shown');

  if (option == TransitOption.flight) {
    await _verifyPresent(
        tester,
        _form.airlineNameAutoCompleteTextField,
        findsOneWidget,
        '${option.name}: airline name auto-complete must be shown');
    await _verifyAbsent(tester, _form.airlineNumberTextField,
        '${option.name}: flight number field must NOT appear before an airline is selected');
    await _verifyPresent(
        tester,
        _form.airportLocationAutoCompleteTextField,
        findsNWidgets(2),
        '${option.name}: exactly 2 airport auto-complete fields must be shown');
    print('  -> ${option.name}: flight-specific fields verified');
  } else {
    if (option != TransitOption.rentedVehicle) {
      await _verifyPresent(tester, _form.transitOperatorEditingField,
          findsOneWidget, '${option.name}: operator field must be shown');
    }
    await _verifyPresent(
        tester,
        _form.geoLocationAutoCompleteTextField,
        findsNWidgets(2),
        '${option.name}: exactly 2 geo-location fields must be shown');
    print('  -> ${option.name}: non-flight bookable fields verified');
  }
}

/// Verifies common fields (note, date-time pickers) present for ALL transit types.
Future<void> _verifyCommonFields(
    WidgetTester tester, TransitOption option) async {
  await _verifyPresent(tester, _form.commonFormElements.noteEditingField,
      findsOneWidget, '${option.name}: note field must be shown');
  await _verifyPresent(
      tester,
      _form.commonFormElements.dateTimePicker,
      findsNWidgets(2),
      '${option.name}: exactly 2 date-time pickers must be shown');
  print(
      '  -> ${option.name}: common fields (note, date-time pickers) verified');
}

// ->-> Dropdown verification ->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->

/// Verifies the transit-option dropdown shows [defaultOption] selected and
/// lists all expected options with correct icons and labels.
Future<void> _verifyTransitOptions(
    WidgetTester tester, TransitOption defaultOption) async {
  final picker = tester.widget<DropdownButton>(_form.transitOptionPicker);
  expect(picker.value, defaultOption,
      reason: 'Default transit option must be $defaultOption');

  await TestHelpers.tapWidget(tester, _form.transitOptionPicker);

  final expectedMetadatas = _allExpectedMetadatas(tester);
  final displayedItems = picker.items!;
  expect(displayedItems.length, expectedMetadatas.length,
      reason:
          'Dropdown must contain exactly ${expectedMetadatas.length} transit options');

  Finder? defaultItemFinder;
  for (var i = 0; i < displayedItems.length; i++) {
    final item = displayedItems[i];
    final expected = expectedMetadatas.elementAt(i);
    final itemFinder = find.byWidget(item).last;

    expect(item.value, expected.transitOption,
        reason: 'Option at index $i must be ${expected.transitOption.name}');
    expect(
        find.descendant(of: itemFinder, matching: find.byIcon(expected.icon)),
        findsOneWidget,
        reason: 'Icon for ${expected.name} must be present in dropdown item');
    expect(find.descendant(of: itemFinder, matching: find.text(expected.name)),
        findsOneWidget,
        reason: 'Label for ${expected.name} must be present in dropdown item');

    if (item.value == defaultOption) {
      defaultItemFinder = itemFinder;
    }
  }

  // Dismiss by re-selecting the default option.
  if (defaultItemFinder != null) {
    await TestHelpers.tapWidget(tester, defaultItemFinder);
  }
  print(
      '  -> All ${expectedMetadatas.length} transit options verified in dropdown');
}

Iterable<TransitOptionMetadata> _allExpectedMetadatas(WidgetTester tester) {
  final loc = TestHelpers.getAppLocalizations(tester, TravelEditor);
  return [
    TransitOptionMetadata(
        transitOption: TransitOption.publicTransport,
        icon: Icons.emoji_transportation_rounded,
        name: loc.publicTransit),
    TransitOptionMetadata(
        transitOption: TransitOption.flight,
        icon: Icons.flight_rounded,
        name: loc.flight),
    TransitOptionMetadata(
        transitOption: TransitOption.bus,
        icon: Icons.directions_bus_rounded,
        name: loc.bus),
    TransitOptionMetadata(
        transitOption: TransitOption.cruise,
        icon: Icons.kayaking_rounded,
        name: loc.cruise),
    TransitOptionMetadata(
        transitOption: TransitOption.ferry,
        icon: Icons.directions_ferry_outlined,
        name: loc.ferry),
    TransitOptionMetadata(
        transitOption: TransitOption.rentedVehicle,
        icon: Icons.car_rental_rounded,
        name: loc.carRental),
    TransitOptionMetadata(
        transitOption: TransitOption.train,
        icon: Icons.train_rounded,
        name: loc.train),
    TransitOptionMetadata(
        transitOption: TransitOption.vehicle,
        icon: Icons.bike_scooter_rounded,
        name: loc.personalVehicle),
    TransitOptionMetadata(
        transitOption: TransitOption.walk,
        icon: Icons.directions_walk_rounded,
        name: loc.walk),
    TransitOptionMetadata(
        transitOption: TransitOption.taxi,
        icon: Icons.local_taxi_rounded,
        name: loc.taxi),
  ];
}

// ->-> Scroll-guarded assertion wrappers ->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->->

Finder _travelEditorScrollable() => find.ancestor(
      of: find.byType(JourneyEditor),
      matching: find.byType(SingleChildScrollView),
    );

Future<void> _verifyPresent(
  WidgetTester tester,
  Finder finder,
  Matcher matcher,
  String reason,
) async =>
    TestHelpers.scrollGuardVerify(
      tester,
      scrollableFinder: _travelEditorScrollable(),
      widgetFinder: finder,
      verification: () async => expect(finder, matcher, reason: reason),
    );

Future<void> _verifyAbsent(
  WidgetTester tester,
  Finder finder,
  String reason,
) async =>
    TestHelpers.scrollGuardVerifyNotPresent(
      tester,
      scrollableFinder: _travelEditorScrollable(),
      widgetFinder: finder,
      reason: reason,
    );
