/// Sight (SightFacade) CRUD integration tests.
///
/// Sights live inside a day's ItineraryPlanData document, edited through
/// the shared ItineraryPlanDataEditor. Add/edit are verified by re-reading
/// the day's plan data from the repository (a per-day document, not a
/// discrete collection item) and by checking the Sights viewer tab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/editor/sights.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/viewer/sights.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';
import 'package:wandrr/presentation/trip/widgets/note_editor.dart';

import '../../../helpers/test_helpers.dart';
import 'helpers.dart';

final _tripStartDate = DateTime(2025, 9, 24);

/// Adds a new sight to the trip's first day via the Creator bottom-sheet's
/// itinerary sub-action, fills its fields, submits, and verifies the
/// persisted SightFacade plus its entry in the Sights viewer tab.
Future<void> runAddSightTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);

  final loc = TestHelpers.getAppLocalizations(tester, TripEditorPage);
  await openItinerarySubAction(tester,
      icon: Icons.place_rounded, label: loc.sight);

  // Exactly one sight is expanded (the newly-appended one); the seeded
  // "Eiffel Tower" sight stays collapsed, so its editor subtree is not built.
  final titleField = find.descendant(
      of: find.byType(ItinerarySightsEditor),
      matching: find.byType(TextFormField));
  expect(titleField, findsOneWidget,
      reason: 'Exactly one sight editor (the new one) must be expanded');
  await TestHelpers.enterText(tester, titleField, 'Notre-Dame Cathedral');

  final locationField = find.descendant(
      of: find.descendant(
          of: find.byType(ItinerarySightsEditor),
          matching: find.byType(PlatformGeoLocationAutoComplete)),
      matching: find.byKey(const ValueKey('PlatformAutoComplete_TextField')));
  await TestHelpers.enterText(tester, locationField, 'Paris');
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
  final locationOption =
      find.byKey(const ValueKey('PlatformAutoComplete_ListTile'));
  expect(locationOption, findsAtLeastNWidgets(1),
      reason: 'At least one location option must appear for "Paris"');
  await TestHelpers.tapWidget(tester, locationOption.first);

  final descriptionField = find.descendant(
      of: find.descendant(
          of: find.byType(ItinerarySightsEditor),
          matching: find.byType(NoteEditor)),
      matching: find.byKey(const ValueKey('NoteEditor_TextField')));
  await TestHelpers.enterText(tester, descriptionField, 'Gothic masterpiece');
  print('[OK] Sight form filled');

  await submitItineraryPlanDataAndVerify(tester, onSubmitted: () async {
    final planData = TestHelpers.getTripRepository(tester)
        .activeTrip!
        .itineraryCollection
        .getItineraryForDay(_tripStartDate)
        .planData;
    final sight =
        planData.sights.firstWhere((s) => s.name == 'Notre-Dame Cathedral');
    expect(sight.description, 'Gothic masterpiece',
        reason: 'Persisted description must match');
    expect(sight.location, isNotNull, reason: 'Persisted location must be set');
    print('[OK] Sight persisted: $sight');

    await TestHelpers.navigateToItineraryTab(tester, date: _tripStartDate);
    await TestHelpers.tapWidget(tester, find.byIcon(Icons.place_outlined));
    final scrollable = find.descendant(
        of: find.byType(ItinerarySightsViewer),
        matching: find.byType(ListView));
    final found = await TestHelpers.scrollUntilPresent(
      tester,
      scrollableFinder: scrollable,
      widgetFinder: find.text('Notre-Dame Cathedral'),
      reason: 'New sight must appear in the Sights viewer tab',
    );
    expect(found, isTrue, reason: 'New sight not found in Sights viewer tab');
    print('[OK] Sight visible in Sights viewer tab');
  });
}

/// Edits the seeded "Eiffel Tower" sight from the Sights viewer tab and
/// verifies the change is persisted and reflected in the viewer.
Future<void> runEditSightTest(WidgetTester tester) async {
  await TestHelpers.pumpAndSettleApp(tester);
  await TestHelpers.navigateToTripEditorPage(tester);
  await TestHelpers.navigateToItineraryTab(tester, date: _tripStartDate);
  await TestHelpers.tapWidget(tester, find.byIcon(Icons.place_outlined));

  final sightTile = find.text('Eiffel Tower');
  expect(sightTile, findsOneWidget,
      reason: 'Seeded "Eiffel Tower" sight must be shown');
  await TestHelpers.tapWidget(tester, sightTile);
  await TestHelpers.waitForWidget(tester, find.byType(ItinerarySightsEditor));
  print('[OK] Sight editor opened for editing (Eiffel Tower)');

  final titleField = find.descendant(
      of: find.byType(ItinerarySightsEditor),
      matching: find.byType(TextFormField));
  expect(titleField, findsOneWidget);
  expect(
      tester.widget<TextFormField>(titleField).controller?.text, 'Eiffel Tower',
      reason: 'Editor must be pre-filled with the existing sight name');

  await TestHelpers.enterText(tester, titleField, 'Eiffel Tower (renamed)');

  await submitItineraryPlanDataAndVerify(tester, onSubmitted: () async {
    final planData = TestHelpers.getTripRepository(tester)
        .activeTrip!
        .itineraryCollection
        .getItineraryForDay(_tripStartDate)
        .planData;
    expect(
        planData.sights.any((s) => s.name == 'Eiffel Tower (renamed)'), isTrue,
        reason: 'Renamed sight must be persisted');
    print('[OK] Sight rename persisted');

    final scrollable = find.descendant(
        of: find.byType(ItinerarySightsViewer),
        matching: find.byType(ListView));
    final found = await TestHelpers.scrollUntilPresent(
      tester,
      scrollableFinder: scrollable,
      widgetFinder: find.text('Eiffel Tower (renamed)'),
      reason: 'Renamed sight must appear in the Sights viewer tab',
    );
    expect(found, isTrue,
        reason: 'Renamed sight not found in Sights viewer tab');
    print('[OK] Renamed sight visible in Sights viewer tab');
  });
}
