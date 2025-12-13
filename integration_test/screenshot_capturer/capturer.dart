import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/widgets/timeline_item_widget.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/main/bottom_nav_bar.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../helpers/test_helpers.dart';

const _tripsListView = 'trips_list_view';
const _tripEditorPage = 'trip_editor_page';
const _flightEditor = 'flight_editor';
const _stayEditor = 'stay_editor';
const _noteViewer = 'note_viewer';
const _checklistViewer = 'checklist_viewer';
const _sightViewer = 'sight_viewer';
const _noteEditor = 'note_editor';
const _checkListEditor = 'check_list_editor';
const _sightEditor = 'sight_editor';
const _budgetingPage = 'budgeting_page';
const _debtSummarySection = 'debt_summary_section';
const _budgetBreakdownByDaySection = 'budget_breakdown_by_day_section';
const _budgetBreakdownByCategorySection =
    'budget_breakdown_by_category_section';

Future<void> runScreenshotCapturer(
    WidgetTester tester, IntegrationTestWidgetsFlutterBinding binding) async {
  await TestHelpers.pumpAndSettleApp(tester);

  // Convert surface to image once at the start
  await binding.convertFlutterSurfaceToImage();
  await tester.pumpAndSettle();

  var isLargeScreen = TestHelpers.isLargeScreen(tester);
  if (isLargeScreen) {
    await _switchThemeMode(tester);
  }
  await _generateScreenshot(tester, binding, _tripsListView);

  await _navigateToTripEditorPage(tester);
  await _generateScreenshot(tester, binding, _tripEditorPage);

  final flightTimelineEntry = find.descendant(
      of: find.byType(TimelineItemWidget),
      matching: find.text('Air France AF 542'));
  await TestHelpers.tapWidget(tester, flightTimelineEntry);
  await _generateScreenshot(tester, binding, _flightEditor);
  await _closeActionPage(tester);

  final stayTimelineEntry = find.descendant(
      of: find.byType(TimelineItemWidget),
      matching: find.text('Check-In • 02:00 PM'));
  await TestHelpers.tapWidget(tester, stayTimelineEntry);
  await _generateScreenshot(tester, binding, _stayEditor);
  await _closeActionPage(tester);

  await _takeItineraryDataComponentScreenshots(
      tester,
      binding,
      Icons.note_outlined,
      _noteViewer,
      _noteEditor,
      find.text('Arrive from London').first);

  await _takeItineraryDataComponentScreenshots(
      tester,
      binding,
      Icons.checklist_outlined,
      _checklistViewer,
      _checkListEditor,
      find.byIcon(Icons.edit_outlined));
  await _takeItineraryDataComponentScreenshots(
      tester,
      binding,
      Icons.place_outlined,
      _sightViewer,
      _sightEditor,
      find.text('Eiffel Tower'));

  if (!isLargeScreen) {
    final budgetIcon = find.descendant(
      of: find.byType(BottomNavBar),
      matching: find.byIcon(Icons.wallet_travel_rounded),
    );
    await TestHelpers.tapWidget(tester, budgetIcon);
    await _generateScreenshot(tester, binding, _budgetingPage);
  }

  final debtSummarySectionHeader = find.byIcon(Icons.money_off_rounded);
  await TestHelpers.tapWidget(tester, debtSummarySectionHeader);
  await _generateScreenshot(tester, binding, _debtSummarySection);

  final pieChartSectionHeader = find.byIcon(Icons.pie_chart_rounded);
  await TestHelpers.tapWidget(tester, pieChartSectionHeader);
  await _generateScreenshot(tester, binding, _budgetBreakdownByCategorySection);

  final breakdownByDaySectionHeader = find.text('Day by day');
  await TestHelpers.tapWidget(tester, breakdownByDaySectionHeader);
  await _generateScreenshot(tester, binding, _budgetBreakdownByDaySection);
}

Future<void> _takeItineraryDataComponentScreenshots(
    WidgetTester tester,
    IntegrationTestWidgetsFlutterBinding binding,
    IconData tabIndicatorIcon,
    String viewerScreenshotName,
    String editorScreenshotName,
    Finder viewerElementFinder) async {
  final tabIcon = find.byIcon(tabIndicatorIcon);
  await TestHelpers.tapWidget(tester, tabIcon);
  await _generateScreenshot(tester, binding, viewerScreenshotName);
  await TestHelpers.tapWidget(tester, viewerElementFinder);
  await _generateScreenshot(tester, binding, editorScreenshotName);
  await _closeActionPage(tester);
}

Future<void> _closeActionPage(WidgetTester tester) async {
  final closeIcon = find.descendant(
      of: find.byType(AppBar), matching: find.byIcon(Icons.close));
  await TestHelpers.tapWidget(tester, closeIcon);
}

Future<void> _switchThemeMode(WidgetTester tester) async {
  final toolbarButton = find.byIcon(Icons.settings);
  await TestHelpers.tapWidget(tester, toolbarButton);
  final themeOption = find.byKey(Key('ToolBar_ThemeSwitcher'));
  await TestHelpers.tapWidget(tester, themeOption);
  await TestHelpers.tapWidget(tester, toolbarButton);
}

Future<void> _navigateToTripEditorPage(WidgetTester tester) async {
  // Find the test trip grid item by its name "European Adventure"
  final testTripItem = find.ancestor(
    of: find.text('European Adventure'),
    matching: find.byType(InkWell),
  );

  // Verify the test trip item is found
  expect(testTripItem, findsOneWidget,
      reason:
          'Test trip "European Adventure" should be displayed in TripsListView');

  // Click on the test trip item to navigate to TripEditorPage
  await TestHelpers.tapWidget(tester, testTripItem);

  await TestHelpers.waitForWidget(
    tester,
    find.byType(TripEditorPage),
    timeout: const Duration(seconds: 10), // Allow extra time for Rive animation
  );
}

Future<void> _generateScreenshot(WidgetTester tester,
    IntegrationTestWidgetsFlutterBinding binding, String screenshotName) async {
  await tester.pumpAndSettle();
  final isLargeScreen = TestHelpers.isLargeScreen(tester);
  final screenShotNameForDevice =
      _generateScreenshotNameForDevice(isLargeScreen, screenshotName);
  await binding.takeScreenshot(screenShotNameForDevice);
}

String _generateScreenshotNameForDevice(
    bool isLargeScreen, String screenshotName) {
  return isLargeScreen ? 'tablet_$screenshotName' : 'phone_$screenshotName';
}
