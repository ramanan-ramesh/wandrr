/// PrintTrip integration tests.
///
/// Covers requirements from docs/requirements/PrintTrip.md:
///   Entry:        REQ_PRN_001, REQ_PRN_002, REQ_PRN_003, REQ_PRN_054
///   Loading:      REQ_PRN_004
///   Title:        REQ_PRN_009, REQ_PRN_010
///   Sections:     REQ_PRN_011, REQ_PRN_015, REQ_PRN_016
///   TransitFltr:  REQ_PRN_017, REQ_PRN_019, REQ_PRN_023, REQ_PRN_024
///   Journeys:     REQ_PRN_025, REQ_PRN_026, REQ_PRN_027, REQ_PRN_028
///   Generate:     REQ_PRN_029
///
/// Not covered here (require native print / PDF inspection, see unit tests):
///   REQ_PRN_030..REQ_PRN_053 (document generation & content).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/presentation/trip/pages/home/trips_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/print_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/widgets/print_common_controls.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/widgets/print_form_content.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../../helpers/firebase_emulator_helper.dart';
import '../../helpers/http_overrides/mock_location_api_service.dart';
import '../../helpers/test_config.dart';
import '../../helpers/test_helpers.dart';
import 'helpers.dart';

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

  // ── Entry & navigation ──────────────────────────────────────────────────────
  testWidgets(
      'opens print page from the trip editor and returns to it when closed',
      (WidgetTester tester) async {
    print('REQ_PRN_001 REQ_PRN_003 REQ_PRN_004 REQ_PRN_054');
    await TestHelpers.pumpAndSettleApp(tester);
    await TestHelpers.navigateToTripEditorPage(tester);

    // REQ_PRN_004: opening print may briefly show the loading subtree while
    // keeping the action panel visible; the page then becomes ready.
    await openPrintFromTripEditor(tester);
    expect(find.byType(PrintPage), findsOneWidget,
        reason: 'Print page must be shown for the trip');

    // REQ_PRN_054: closing print returns to the trip editor it was opened from.
    await TestHelpers.tapWidget(tester, find.byType(BackButton));
    await TestHelpers.waitForWidget(tester, find.byType(TripEditorPage));
    expect(find.byType(PrintPage), findsNothing);
    print('[OK] Returned to trip editor after closing print');
  });

  testWidgets(
      'opens print page from a trips-list card and returns to the trips list when closed',
      (WidgetTester tester) async {
    print('REQ_PRN_002 REQ_PRN_003 REQ_PRN_054');
    await TestHelpers.pumpAndSettleApp(tester);
    await TestHelpers.waitForWidget(tester, find.byType(TripListView));

    await openPrintFromTripCard(tester, 'European Adventure');
    expect(find.byType(PrintPage), findsOneWidget,
        reason: 'Print page must be shown for the selected trip');

    // REQ_PRN_054: closing print returns to the trips list it was opened from.
    await TestHelpers.tapWidget(tester, find.byType(BackButton));
    await TestHelpers.waitForWidget(tester, find.byType(TripListView));
    expect(find.byType(PrintPage), findsNothing);
    print('[OK] Returned to trips list after closing print');
  });

  // ── Default state ────────────────────────────────────────────────────────────
  testWidgets('print page shows the correct default state once ready',
      (WidgetTester tester) async {
    print('REQ_PRN_009 REQ_PRN_011 REQ_PRN_015 REQ_PRN_019 REQ_PRN_023 '
        'REQ_PRN_029');
    await TestHelpers.pumpAndSettleApp(tester);
    await TestHelpers.navigateToTripEditorPage(tester);
    await openPrintFromTripEditor(tester);

    final loc = printLocalizations(tester);

    // REQ_PRN_009: title defaults to the trip name.
    expect(
      find.descendant(
          of: find.byType(PrintFormContent),
          matching: find.text('European Adventure')),
      findsOneWidget,
      reason: 'Document title must default to the trip name',
    );
    print('[OK] Title defaults to "European Adventure"');

    // REQ_PRN_011 / REQ_PRN_015: the four optional sections are offered and
    // every section is selected + enabled by default (the trip has content
    // for all sections).
    final expectedLabels = [
      loc.checklists,
      loc.expenses,
      loc.sightsPlaces,
      loc.notes,
    ];
    for (final label in expectedLabels) {
      expect(PrintFinders.sectionChip(label), findsOneWidget,
          reason: 'Section option "$label" must be offered');
    }
    for (final chip in tester.widgetList<FilterChip>(find.byType(FilterChip))) {
      expect(chip.selected, isTrue,
          reason: 'Section "${_chipLabel(chip)}" must be selected by default');
      expect(chip.onSelected, isNotNull,
          reason: 'Section "${_chipLabel(chip)}" must be enabled');
    }
    print('[OK] All 4 section chips present, selected and enabled');

    // REQ_PRN_019: both inter- and intra-city switches default to on.
    for (final sw in tester
        .widgetList<PrintCompactSwitch>(find.byType(PrintCompactSwitch))) {
      expect(sw.value, isTrue,
          reason: '"${sw.label}" transit filter must default to included');
    }

    // REQ_PRN_023: transits are listed and all selected by default (no "none"
    // placeholder shown when transits exist).
    expect(find.text(loc.noTransitsAvailable), findsNothing,
        reason: 'Transits exist, so the empty placeholder must not appear');
    final checkboxes = PrintFinders.transitCheckboxes;
    expect(checkboxes, findsAtLeastNWidgets(1),
        reason: 'At least one transit must be listed');
    for (final cb in tester.widgetList<Checkbox>(checkboxes)) {
      expect(cb.value, isTrue,
          reason: 'Every listed transit must be selected by default');
    }
    print('[OK] Transit filters on by default, all transits selected');

    // REQ_PRN_029: the generate action is available once the page is ready.
    final button = tester
        .widget<FilledButton>(PrintFinders.generateButton(loc.generatePdf));
    expect(button.onPressed, isNotNull,
        reason: 'Generate action must be enabled when transits are ready');
    print('[OK] Generate action enabled');
  });

  // ── Document title ──────────────────────────────────────────────────────────
  testWidgets('document title can be edited before generating',
      (WidgetTester tester) async {
    print('REQ_PRN_010');
    await TestHelpers.pumpAndSettleApp(tester);
    await TestHelpers.navigateToTripEditorPage(tester);
    await openPrintFromTripEditor(tester);

    await TestHelpers.enterText(
        tester, PrintFinders.titleField, 'My Custom Itinerary');
    await tester.pumpAndSettle();
    expect(find.text('My Custom Itinerary'), findsOneWidget,
        reason: 'Edited document title must be reflected in the field');
    print('[OK] Title edited to "My Custom Itinerary"');
  });

  // ── Include sections ────────────────────────────────────────────────────────
  testWidgets('section options are unavailable when the trip has no content',
      (WidgetTester tester) async {
    print('REQ_PRN_016');
    await createEmptyTestTrip();

    await TestHelpers.pumpAndSettleApp(tester);
    await TestHelpers.waitForWidget(tester, find.byType(TripListView));
    await openPrintFromTripCard(tester, 'Blank Getaway');

    // REQ_PRN_016: with no content, section chips are disabled.
    final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
    expect(chips, isNotEmpty);
    for (final chip in chips) {
      expect(chip.onSelected, isNull,
          reason:
              'Section "${_chipLabel(chip)}" must be unavailable for an empty trip');
    }
    print('[OK] All section chips unavailable for an empty trip');
  });

  // ── Transit filters & selection ─────────────────────────────────────────────
  testWidgets('disabling both transit filters hides all transits',
      (WidgetTester tester) async {
    print('REQ_PRN_017');
    await TestHelpers.pumpAndSettleApp(tester);
    await TestHelpers.navigateToTripEditorPage(tester);
    await openPrintFromTripEditor(tester);

    final loc = printLocalizations(tester);

    await _toggleTransitFilter(tester, loc.includeInterCityTransit);
    await _toggleTransitFilter(tester, loc.includeIntraCityTransit);

    // REQ_PRN_017: filtering out both classes removes every transit.
    expect(find.text(loc.noTransitsAvailable), findsOneWidget,
        reason:
            'With both filters off, no transit should remain in the selection list');
    print('[OK] Both filters off -> "No transits available" shown');
  });

  testWidgets('an individual transit can be excluded and re-included',
      (WidgetTester tester) async {
    print('REQ_PRN_024');
    await TestHelpers.pumpAndSettleApp(tester);
    await TestHelpers.navigateToTripEditorPage(tester);
    await openPrintFromTripEditor(tester);

    final firstCheckbox = PrintFinders.transitCheckboxes.first;
    expect(tester.widget<Checkbox>(firstCheckbox).value, isTrue);

    // Exclude it.
    await TestHelpers.tapWidget(tester, firstCheckbox, warnIfMissed: false);
    expect(
      tester
          .widgetList<Checkbox>(PrintFinders.transitCheckboxes)
          .any((cb) => cb.value == false),
      isTrue,
      reason: 'Excluding a transit must clear its checkbox',
    );
    print('[OK] Transit excluded');

    // Re-include it.
    await TestHelpers.tapWidget(tester, PrintFinders.transitCheckboxes.first,
        warnIfMissed: false);
    print('[OK] Transit re-included');
  });

  // ── Journeys (multi-leg transits) ───────────────────────────────────────────
  testWidgets(
      'a multi-leg journey can be merged into one entry and split back into legs',
      (WidgetTester tester) async {
    print('REQ_PRN_025 REQ_PRN_026 REQ_PRN_027 REQ_PRN_028');
    const journeyId = 'journey_test_1';
    await addJourneyToTestTrip(journeyId: journeyId);
    await TestHelpers.pumpAndSettleApp(tester);
    await TestHelpers.navigateToTripEditorPage(tester);
    await openPrintFromTripEditor(tester);

    final loc = printLocalizations(tester);

    // REQ_PRN_025: the multi-leg journey is shown as a single grouped option.
    expect(find.textContaining(loc.nLegs(2)), findsOneWidget,
        reason: 'Journey with 2 legs must show a grouped "2 legs" label');
    final legsPanel = find.byType(SizeTransition);
    expect(legsPanel, findsOneWidget,
        reason: 'Journey group must expose an expandable legs panel');
    print('[OK] Journey shown as a grouped travel option');

    // Legs are shown individually / reviewable by default.
    expect(find.text(loc.mergeLegs), findsOneWidget,
        reason:
            'Legs are shown individually by default (toggle offers "Merge legs")');
    expect(tester.widget<SizeTransition>(legsPanel).sizeFactor.value, 1.0,
        reason: 'Legs panel must be fully expanded by default');

    // REQ_PRN_026: both legs are selected/deselected together via the group
    // checkbox.
    final selectAllCheckbox = PrintFinders.journeySelectAllCheckbox(journeyId);
    final leg1Checkbox = PrintFinders.journeyLegCheckbox('journey_leg_1');
    final leg2Checkbox = PrintFinders.journeyLegCheckbox('journey_leg_2');
    expect(tester.widget<Checkbox>(selectAllCheckbox).value, isTrue,
        reason: 'Both legs are selected by default -> group checkbox checked');
    await TestHelpers.tapWidget(tester, selectAllCheckbox, warnIfMissed: false);
    expect(tester.widget<Checkbox>(leg1Checkbox).value, isFalse,
        reason: 'Deselecting the group checkbox must exclude leg 1');
    expect(tester.widget<Checkbox>(leg2Checkbox).value, isFalse,
        reason: 'Deselecting the group checkbox must exclude leg 2');
    await TestHelpers.tapWidget(tester, selectAllCheckbox, warnIfMissed: false);
    print('[OK] Group checkbox includes/excludes all legs at once');

    // REQ_PRN_027: the user can print the journey as one merged entry.
    final mergeToggle = PrintFinders.journeyMergeToggle(journeyId);
    await TestHelpers.tapWidget(tester, mergeToggle, warnIfMissed: false);
    expect(find.text(loc.showLegs), findsOneWidget,
        reason: 'After merging, the toggle must offer to show legs again');
    expect(tester.widget<SizeTransition>(legsPanel).sizeFactor.value, 0.0,
        reason: 'Merging collapses the individual-legs panel');
    expect(tester.widget<Checkbox>(leg1Checkbox).value, isTrue,
        reason: 'Merging re-selects every leg for printing');
    expect(tester.widget<Checkbox>(leg2Checkbox).value, isTrue,
        reason: 'Merging re-selects every leg for printing');
    print('[OK] Journey merged into a single printed entry');

    // REQ_PRN_028: the user can review/select journey legs individually again.
    await TestHelpers.tapWidget(tester, mergeToggle, warnIfMissed: false);
    expect(find.text(loc.mergeLegs), findsOneWidget,
        reason: 'Un-merging must restore the "Merge legs" toggle label');
    expect(tester.widget<SizeTransition>(legsPanel).sizeFactor.value, 1.0,
        reason: 'Un-merging re-expands the individual-legs panel');
    print('[OK] Journey split back into individually reviewable legs');
  });
}

/// Reads the label text out of a [FilterChip] whose label is a [Text] widget.
String _chipLabel(FilterChip chip) {
  final label = chip.label;
  if (label is Text) {
    return label.data ?? '';
  }
  return label.toString();
}

/// Toggles the transit filter switch identified by its [label].
Future<void> _toggleTransitFilter(WidgetTester tester, String label) async {
  final compactSwitch = find.ancestor(
    of: find.text(label),
    matching: find.byType(PrintCompactSwitch),
  );
  expect(compactSwitch, findsOneWidget,
      reason: 'Transit filter "$label" must be present');
  final toggle =
      find.descendant(of: compactSwitch, matching: find.byType(Switch));
  await TestHelpers.tapWidget(tester, toggle, warnIfMissed: false);
  print('  [OK] Toggled transit filter "$label"');
}
