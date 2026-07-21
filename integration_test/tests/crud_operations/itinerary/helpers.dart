import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_plan_data_editor.dart';

import '../../../helpers/test_helpers.dart';
import '../helpers.dart';

/// Reusable finders/flows scoped to [ItineraryPlanDataEditor].
///
/// Sights/notes/checklists all live inside a single per-day
/// [ItineraryPlanData] document, edited through one shared editor page with
/// three tabs. Every "create" and "edit" flow for these three entity kinds
/// goes through [openItinerarySubAction] / an existing viewer-tile tap, and
/// is submitted through [submitItineraryPlanDataAndVerify].
final CommonFormElements itineraryFormElements =
    CommonFormElements(ItineraryPlanDataEditor);

/// Localizations resolved from the live [ItineraryPlanDataEditor] element.
AppLocalizations itineraryLocalizations(WidgetTester tester) {
  final context = tester.element(find.byType(ItineraryPlanDataEditor));
  return AppLocalizations.of(context)!;
}

/// Taps the add FAB, then the itinerary card's [label] sub-action
/// (sight/note/checklist), and waits for the [ItineraryPlanDataEditor] to
/// appear with a new, blank item already appended and expanded.
Future<void> openItinerarySubAction(
  WidgetTester tester, {
  required IconData icon,
  required String label,
}) async {
  final addFab = find.descendant(
    of: find.byType(Scaffold),
    matching: find.descendant(
      of: find.byType(FloatingActionButton),
      matching: find.byIcon(Icons.add),
    ),
  );
  await TestHelpers.tapWidget(tester, addFab);
  await tester.pumpAndSettle();

  final subAction = find.widgetWithText(OutlinedButton, label);
  expect(subAction, findsOneWidget,
      reason: 'Itinerary sub-action "$label" must be offered');
  await TestHelpers.tapWidget(tester, subAction);

  await TestHelpers.waitForWidget(tester, find.byType(ItineraryPlanDataEditor));
  print('[OK] ItineraryPlanDataEditor opened for a new "$label"');
}

/// Taps the submit FAB (always the "update" check-icon FAB for itinerary plan
/// data, since a day's [ItineraryPlanData] document always already exists),
/// waits for the editor to dismiss, then runs [onSubmitted].
///
/// [onSubmitted] typically re-reads the day's plan data from the repository
/// (a single per-day document, not a discrete collection item) rather than
/// listening on a change stream.
Future<void> submitItineraryPlanDataAndVerify(
  WidgetTester tester, {
  required Future<void> Function() onSubmitted,
}) async {
  final fab = itineraryFormElements.updateTripEntityButton;
  expect(fab, findsOneWidget, reason: 'Update FAB must be present and enabled');
  await TestHelpers.tapWidget(tester, fab);
  print('[OK] Tapped submit FAB -> submitted itinerary plan data');

  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.byType(ItineraryPlanDataEditor).evaluate().isEmpty) {
      break;
    }
  }
  expect(find.byType(ItineraryPlanDataEditor), findsNothing,
      reason:
          'ItineraryPlanDataEditor must be dismissed after Firestore operation completes');
  print('[OK] Bottom-sheet dismissed');

  await tester.pumpAndSettle();
  await onSubmitted();
}
