import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/trip/pages/home/trips_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/print_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/widgets/print_action_panel.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/widgets/print_form_content.dart';

import '../../helpers/test_config.dart';
import '../../helpers/test_helpers.dart';

/// Reusable finders and flows for the PrintTrip page.
///
/// Keeps every interaction driven by type-based finders and the two stable
/// `ValueKey`s exposed by the print page (`print_page_ready` /
/// `print_page_loading`) so no additional widget keys are required.
class PrintFinders {
  /// The ready subtree – present once trip data + transits have loaded.
  static Finder get readySubtree =>
      find.byKey(const ValueKey('print_page_ready'));

  /// The loading subtree – present while trip data / transits are loading.
  static Finder get loadingSubtree =>
      find.byKey(const ValueKey('print_page_loading'));

  /// The editable document-title field (the only TextFormField on the page).
  static Finder get titleField => find.descendant(
        of: find.byType(PrintFormContent),
        matching: find.byType(TextFormField),
      );

  /// The "Generate PDF" action button.
  static Finder generateButton(String label) => find.widgetWithText(
        FilledButton,
        label,
      );

  /// A section include chip identified by its localized [label].
  static Finder sectionChip(String label) =>
      find.widgetWithText(FilterChip, label);

  /// A transit inclusion/exclusion checkbox (standalone or journey leg).
  static Finder get transitCheckboxes => find.descendant(
        of: find.byType(PrintFormContent),
        matching: find.byType(Checkbox),
      );

  /// The "select all legs" checkbox on a journey group's header row.
  static Finder journeySelectAllCheckbox(String journeyId) => find.byKey(
      ValueKey('PrintJourneyGroupTile_SelectAll_$journeyId'));

  /// The merge/show-legs toggle on a journey group's header row.
  static Finder journeyMergeToggle(String journeyId) => find.byKey(
      ValueKey('PrintJourneyGroupTile_MergeToggle_$journeyId'));

  /// The inclusion checkbox for an individual journey leg, identified by the
  /// leg's transit id.
  static Finder journeyLegCheckbox(String legId) =>
      find.byKey(ValueKey('PrintJourneyGroupTile_LegCheckbox_$legId'));
}

/// Localizations resolved from the live PrintPage element.
AppLocalizations printLocalizations(WidgetTester tester) {
  final context = tester.element(find.byType(PrintPage));
  return AppLocalizations.of(context)!;
}

/// Opens print from the trip editor app-bar print button and waits until the
/// print page is fully ready.
///
/// REQ_PRN_001 (open from trip editor), REQ_PRN_003 (shows print page).
Future<void> openPrintFromTripEditor(WidgetTester tester) async {
  final printButton = find.descendant(
    of: find.byType(AppBar),
    matching: find.byIcon(Icons.print_rounded),
  );
  expect(printButton, findsOneWidget,
      reason: 'Trip editor app-bar must expose a print action');
  await TestHelpers.tapWidget(tester, printButton);
  print('[OK] Print opened from trip editor');
  await waitForPrintReady(tester);
}

/// Opens print from a trip card overflow menu in the trips list.
///
/// REQ_PRN_002 (open from a trip card).
Future<void> openPrintFromTripCard(WidgetTester tester, String tripName) async {
  await TestHelpers.waitForWidget(tester, find.byType(TripListView));

  // Open the card overflow menu (more_vert) that belongs to [tripName].
  final card = find.ancestor(
    of: find.text(tripName),
    matching: find.byType(InkWell),
  );
  final menuButton = find
      .descendant(of: card.first, matching: find.byIcon(Icons.more_vert))
      .first;
  await TestHelpers.tapWidget(tester, menuButton, warnIfMissed: false);

  final loc = AppLocalizations.of(tester.element(find.byType(TripListView)))!;
  final printItem = find.text(loc.printTrip);
  expect(printItem, findsOneWidget,
      reason: 'Card overflow menu must offer "${loc.printTrip}"');
  await TestHelpers.tapWidget(tester, printItem);
  print('[OK] Print opened from trip card menu');
  await waitForPrintReady(tester);
}

/// Waits until the print page reaches its ready state.
Future<void> waitForPrintReady(WidgetTester tester) async {
  await TestHelpers.waitForWidget(
    tester,
    PrintFinders.readySubtree,
    timeout: const Duration(seconds: 20),
  );
  await tester.pumpAndSettle();
  expect(find.byType(PrintActionPanel), findsOneWidget,
      reason: 'Print page must show its action panel when ready');
  print('[OK] Print page ready');
}

/// Seeds a second, content-less trip so section-availability behaviour can be
/// verified (REQ_PRN_016). Only trip metadata is written – no transits,
/// lodgings, expenses, sights, notes or checklists.
Future<String> createEmptyTestTrip({String name = 'Blank Getaway'}) async {
  final firestore = FirebaseFirestore.instance;
  const emptyTripId = 'empty_trip_456';
  await firestore
      .collection(FirestoreCollections.tripMetadataCollectionName)
      .doc(emptyTripId)
      .set({
    'name': name,
    'startDate': Timestamp.fromDate(DateTime(2025, 10, 10)),
    'endDate': Timestamp.fromDate(DateTime(2025, 10, 12)),
    'thumbnailTag': 'urban',
    'contributors': [TestConfig.testEmail],
    'budget': '0.00 EUR',
  });
  print('✅ Empty test trip created: $emptyTripId ($name)');
  return emptyTripId;
}

/// Seeds a 2-leg journey (both legs share [journeyId]) into the default test
/// trip so journey grouping/merge behaviour can be verified
/// (REQ_PRN_025..028). Leg ids are fixed (`journey_leg_1`, `journey_leg_2`)
/// so tests can reference [PrintFinders.journeyLegCheckbox] directly.
Future<void> addJourneyToTestTrip({String journeyId = 'journey_test_1'}) async {
  final firestore = FirebaseFirestore.instance;
  final transitCollection = firestore
      .collection(FirestoreCollections.tripCollectionName)
      .doc(TestConfig.testTripId)
      .collection(FirestoreCollections.transitCollectionName);

  final brusselsAirport = {
    'latLon': const GeoPoint(50.9010, 4.4844),
    'context': {
      'type': 'airport',
      'locationType': 'airport',
      'name': 'Brussels Airport',
      'city': 'Brussels',
      'iata': 'BRU',
    }
  };
  final viennaAirport = {
    'latLon': const GeoPoint(48.1103, 16.5697),
    'context': {
      'type': 'airport',
      'locationType': 'airport',
      'name': 'Vienna International Airport',
      'city': 'Vienna',
      'iata': 'VIE',
    }
  };
  final budapestAirport = {
    'latLon': const GeoPoint(47.4298, 19.2611),
    'context': {
      'type': 'airport',
      'locationType': 'airport',
      'name': 'Budapest Ferenc Liszt International Airport',
      'city': 'Budapest',
      'iata': 'BUD',
    }
  };
  final contributors = [TestConfig.testEmail, TestConfig.tripMateUserName];

  await transitCollection.doc('journey_leg_1').set({
    'transitOption': 'flight',
    'journeyId': journeyId,
    'departureLocation': brusselsAirport,
    'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 26, 6, 0)),
    'arrivalLocation': viennaAirport,
    'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 26, 8, 0)),
    'operator': 'Austrian Airlines OS 123',
    'totalExpense': {
      'currency': 'EUR',
      'category': 'flights',
      'paidBy': {TestConfig.testEmail: 90.0},
      'splitBy': contributors,
    },
    'notes': 'Leg 1 of connecting flight',
  });

  await transitCollection.doc('journey_leg_2').set({
    'transitOption': 'flight',
    'journeyId': journeyId,
    'departureLocation': viennaAirport,
    'departureDateTime': Timestamp.fromDate(DateTime(2025, 9, 26, 9, 30)),
    'arrivalLocation': budapestAirport,
    'arrivalDateTime': Timestamp.fromDate(DateTime(2025, 9, 26, 10, 30)),
    'operator': 'Austrian Airlines OS 456',
    'totalExpense': {
      'currency': 'EUR',
      'category': 'flights',
      'paidBy': {TestConfig.testEmail: 70.0},
      'splitBy': contributors,
    },
    'notes': 'Leg 2 of connecting flight',
  });

  print('✅ Journey added to test trip: $journeyId (2 legs)');
}

