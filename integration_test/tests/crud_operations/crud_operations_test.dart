/// TripEntity CRUD integration tests.
///
/// Registers real, stream-verified add/edit interaction tests for every
/// trip-entity kind: Transit (see transit/add_transit_tests.dart), Stay,
/// Expense, Sight, Note and Checklist. Each test fills the real editor UI,
/// submits it, and verifies the change through the relevant repository
/// collection/stream plus the corresponding viewer widget - no placeholder
/// print-only assertions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/firebase_emulator_helper.dart';
import '../../helpers/http_overrides/mock_location_api_service.dart';
import '../../helpers/test_config.dart';
import '../../helpers/test_helpers.dart';
import 'expense/add_edit_expense_tests.dart';
import 'itinerary/add_edit_checklist_tests.dart';
import 'itinerary/add_edit_note_tests.dart';
import 'itinerary/add_edit_sight_tests.dart';
import 'stay/add_edit_stay_tests.dart';
import 'transit/add_transit_tests.dart';

void runTests() {
  setUpAll(() async {
    await FirebaseEmulatorHelper.createFirebaseAuthUser(
      email: TestConfig.testEmail,
      password: TestConfig.testPassword,
      shouldAddToFirestore: true,
      shouldSignIn: true,
    );
    await MockApiServices.initialize();
  });

  tearDownAll(() async {
    await FirebaseEmulatorHelper.cleanupAfterTest();
  });

  setUp(() async {
    await TestHelpers.createTestTrip();
  });

  tearDown(() async {
    await FirebaseEmulatorHelper.clearAllFirestoreData();
    expect(find.byType(ErrorWidget), findsNothing);
  });

  // ── Transit ──────────────────────────────────────────────────────────────────
  testWidgets('verify default state of TravelEditor on creation',
      (WidgetTester tester) async {
    print('REQ-TR-003');
    await runVerifyDefaultStateTest(tester);
  });

  testWidgets('add Walk transit via Creator bottom-sheet',
      (WidgetTester tester) async {
    print('REQ-TR-001');
    await runAddWalkTransitTest(tester);
  });

  testWidgets('add PersonalVehicle transit via Creator bottom-sheet',
      (WidgetTester tester) async {
    print('REQ-TR-001');
    await runAddPersonalVehicleTransitTest(tester);
  });

  testWidgets('add PublicTransport transit and verify timeline + expense entry',
      (WidgetTester tester) async {
    print('REQ-TR-001 REQ-BU-001');
    await runAddPublicTransportTransitTest(tester);
  });

  testWidgets('add Bus transit and verify timeline + expense entry',
      (WidgetTester tester) async {
    print('REQ-TR-001 REQ-BU-001');
    await runAddBusTransitTest(tester);
  });

  testWidgets('add Train transit and verify timeline + expense entry',
      (WidgetTester tester) async {
    print('REQ-TR-001 REQ-BU-001');
    await runAddTrainTransitTest(tester);
  });

  testWidgets('add Taxi transit and verify timeline + expense entry',
      (WidgetTester tester) async {
    print('REQ-TR-001 REQ-BU-001');
    await runAddTaxiTransitTest(tester);
  });

  testWidgets('add Ferry transit and verify timeline + expense entry',
      (WidgetTester tester) async {
    print('REQ-TR-001 REQ-BU-001');
    await runAddFerryTransitTest(tester);
  });

  testWidgets('add RentedVehicle transit and verify timeline + expense entry',
      (WidgetTester tester) async {
    print('REQ-TR-001 REQ-BU-001');
    await runAddRentedVehicleTransitTest(tester);
  });

  testWidgets('add Cruise transit and verify timeline + expense entry',
      (WidgetTester tester) async {
    print('REQ-TR-001 REQ-BU-001');
    await runAddCruiseTransitTest(tester);
  });

  // ── Stay ─────────────────────────────────────────────────────────────────────
  testWidgets(
      'add new stay via Creator bottom-sheet and verify check-in timeline entry',
      (WidgetTester tester) async {
    print('REQ-ST-001 REQ-IT-003');
    await runAddStayTest(tester);
  });

  testWidgets('edit existing stay from its check-in timeline entry',
      (WidgetTester tester) async {
    print('REQ-ST-001 REQ-TE-005 REQ-IT-006');
    await runEditStayTest(tester);
  });

  // ── Expense ──────────────────────────────────────────────────────────────────
  testWidgets(
      'add new expense via Creator bottom-sheet and verify budgeting list entry',
      (WidgetTester tester) async {
    print('REQ-SE-001 REQ-BU-001');
    await runAddExpenseTest(tester);
  });

  testWidgets('edit existing expense from the budgeting list',
      (WidgetTester tester) async {
    print('REQ-SE-001 REQ-TE-005 REQ-BU-001');
    await runEditExpenseTest(tester);
  });

  // ── Sight ────────────────────────────────────────────────────────────────────
  testWidgets(
      'add new sight via Creator bottom-sheet and verify Sights viewer tab',
      (WidgetTester tester) async {
    print('REQ-IPD-001 REQ-IT-002');
    await runAddSightTest(tester);
  });

  testWidgets('edit existing sight from the Sights viewer tab',
      (WidgetTester tester) async {
    print('REQ-IPD-002 REQ-TE-005 REQ-IT-006');
    await runEditSightTest(tester);
  });

  // ── Note ─────────────────────────────────────────────────────────────────────
  testWidgets(
      'add new note via Creator bottom-sheet and verify Notes viewer tab',
      (WidgetTester tester) async {
    print('REQ-IPD-001 REQ-IT-002');
    await runAddNoteTest(tester);
  });

  testWidgets('edit existing note from the Notes viewer tab',
      (WidgetTester tester) async {
    print('REQ-IPD-002 REQ-TE-005 REQ-IT-006');
    await runEditNoteTest(tester);
  });

  // ── Checklist ────────────────────────────────────────────────────────────────
  testWidgets(
      'add new checklist via Creator bottom-sheet and verify Checklists viewer tab',
      (WidgetTester tester) async {
    print('REQ-IPD-001 REQ-IT-002');
    await runAddChecklistTest(tester);
  });

  testWidgets('edit existing checklist from the Checklists viewer tab',
      (WidgetTester tester) async {
    print('REQ-IPD-002 REQ-TE-005 REQ-IT-006');
    await runEditChecklistTest(tester);
  });
}
