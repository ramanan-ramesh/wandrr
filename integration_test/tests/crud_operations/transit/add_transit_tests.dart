import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/travel_editor.dart';

import '../../../helpers/test_config.dart';
import '../../../helpers/test_helpers.dart';
import '../helpers.dart';
import 'helpers.dart';

final _travelEditorForm = TravelEditorForm();

/// Get the scrollable finder for the TravelEditor's parent scroll view
Finder _getTravelEditorScrollable() {
  return find.ancestor(
    of: find.byType(TravelEditor),
    matching: find.byType(SingleChildScrollView),
  );
}

/// Helper method to verify widget presence with scroll guard
Future<void> _verifyWithScrollGuard(
  WidgetTester tester, {
  required Finder widgetFinder,
  required Matcher matcher,
  required String reason,
  bool scrollToTop = true,
}) async {
  await TestHelpers.scrollGuardVerify(
    tester,
    scrollableFinder: _getTravelEditorScrollable(),
    widgetFinder: widgetFinder,
    verification: () async {
      expect(widgetFinder, matcher, reason: reason);
    },
    scrollToTop: scrollToTop,
  );
}

/// Helper method to verify widget is NOT present with scroll guard
Future<void> _verifyNotPresentWithScrollGuard(
  WidgetTester tester, {
  required Finder widgetFinder,
  required String reason,
}) async {
  await TestHelpers.scrollGuardVerifyNotPresent(
    tester,
    scrollableFinder: _getTravelEditorScrollable(),
    widgetFinder: widgetFinder,
    reason: reason,
  );
}

/// Test: Add new transit via FloatingActionButton
Future<void> runVerifyDefaultStateTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

  // Tap the FAB to open add menu
  await _openTransitCreatorPage(tester);

  await _verifyTransitOptions(tester, TransitOption.publicTransport);

  final tripMetadata =
      TestHelpers.getTripRepository(tester).activeTrip!.tripMetadata;
  for (final transitOption in TransitOption.values) {
    await _travelEditorForm.selectTransitOption(tester, transitOption);

    final paidByContributorTileFinder = _travelEditorForm
        .commonFormElements.expenseEditor.paidByTabContributorTile;
    final splitByContributorTileFinder = _travelEditorForm
        .commonFormElements.expenseEditor.splitByContributorTile;
    final expenseAmountTextFieldFinder = find.descendant(
        of: paidByContributorTileFinder,
        matching: find.byKey(ValueKey('ExpenseAmountEditField_TextField')));

    if (transitOption == TransitOption.walk) {
      // For walk, verify widgets are NOT present by scrolling through entire view
      await _verifyNotPresentWithScrollGuard(
        tester,
        widgetFinder: paidByContributorTileFinder,
        reason: 'Paid by contributor tile should not be displayed for walk',
      );
      await _verifyNotPresentWithScrollGuard(
        tester,
        widgetFinder: splitByContributorTileFinder,
        reason: 'Split by contributor tile should not be displayed for walk',
      );
      await _verifyNotPresentWithScrollGuard(
        tester,
        widgetFinder: expenseAmountTextFieldFinder,
        reason: 'Expense amount field should not be displayed for walk',
      );
      await _verifyNotPresentWithScrollGuard(
        tester,
        widgetFinder: _travelEditorForm.transitOperatorEditingField,
        reason: 'Transit operator field should not be displayed for walk',
      );
      await _verifyNotPresentWithScrollGuard(
        tester,
        widgetFinder: _travelEditorForm.airportLocationAutoCompleteTextField,
        reason:
            'Departure and arrival Airport location text fields should not be displayed for walk',
      );
    } else {
      // Verify that PaidBy is displayed by default and expense amount is 0
      var numberOfContributors = tripMetadata.contributors.length;

      // Switch to SplitBy tab and verify that contributors are you and tripmate
      await _travelEditorForm.commonFormElements.expenseEditor
          .switchToPaidByTab(tester);

      expect(paidByContributorTileFinder, findsNWidgets(numberOfContributors),
          reason:
              '$numberOfContributors Paid by contributor tiles should be displayed');

      expect(expenseAmountTextFieldFinder, findsNWidgets(numberOfContributors),
          reason:
              '$numberOfContributors Expense amount fields should be displayed');

      final expenseAmountTextFields =
          tester.widgetList<TextField>(expenseAmountTextFieldFinder);
      for (final expenseAmountTextField in expenseAmountTextFields) {
        expect(
            double.parse(expenseAmountTextField.controller!.text) == 0, isTrue,
            reason: 'Expense amount should be 0');
      }

      expect(
          find.descendant(
              of: paidByContributorTileFinder, matching: find.text('You')),
          findsOneWidget,
          reason: 'You should be a contributor in PaidBy');

      expect(
          find.descendant(
              of: paidByContributorTileFinder,
              matching:
                  find.text(TestConfig.tripMateUserName.split('@').first)),
          findsOneWidget,
          reason: 'Tripmate should be a contributor in PaidBy');

      // Switch to SplitBy tab and verify that contributors are you and tripmate
      await _travelEditorForm.commonFormElements.expenseEditor
          .switchToSplitTab(tester);

      expect(splitByContributorTileFinder, findsNWidgets(numberOfContributors),
          reason:
              '$numberOfContributors Split by contributor tiles should be displayed');
      for (final contributor in tripMetadata.contributors) {
        if (contributor == TestConfig.testEmail) {
          expect(
              find.descendant(
                  of: splitByContributorTileFinder, matching: find.text('You')),
              findsOneWidget,
              reason: 'Tripmate should be a contributor to split');
        } else {
          final displayName = contributor.split('@').first;
          expect(
              find.descendant(
                  of: splitByContributorTileFinder,
                  matching: find.text(displayName)),
              findsOneWidget,
              reason: 'Contributor should be a contributor to split');
        }
      }

      final splitByListTiles =
          tester.widgetList<ListTile>(splitByContributorTileFinder);
      for (final splitByListTile in splitByListTiles) {
        expect(splitByListTile.selected, isTrue,
            reason: 'Entry should be selected in SplitBy');
      }

      // Verify flight-specific fields with scroll guard
      if (transitOption == TransitOption.flight) {
        await _verifyWithScrollGuard(tester,
            widgetFinder: _travelEditorForm.airlineNameAutoCompleteTextField,
            matcher: findsOneWidget,
            reason: 'Airline name text field should be displayed');

        await _verifyWithScrollGuard(
          tester,
          widgetFinder: _travelEditorForm.airlineNumberTextField,
          matcher: transitOption == TransitOption.flight
              ? findsOneWidget
              : findsNothing,
          reason:
              'Airline number text field should be displayed only for flights',
        );

        await _verifyWithScrollGuard(
          tester,
          widgetFinder: _travelEditorForm.airportLocationAutoCompleteTextField,
          matcher: transitOption == TransitOption.flight
              ? findsNWidgets(2)
              : findsNothing,
          reason:
              'Departure and arrival Airport location text fields should be displayed only for flights',
        );
      } else {
        await _verifyWithScrollGuard(
          tester,
          widgetFinder: _travelEditorForm.transitOperatorEditingField,
          matcher: transitOption != TransitOption.flight
              ? findsOneWidget
              : findsNothing,
          reason:
              'Transit operator field should be displayed only for non-flight transit options',
        );

        // Verify geo location fields with scroll guard
        await _verifyWithScrollGuard(
          tester,
          widgetFinder: _travelEditorForm.geoLocationAutoCompleteTextField,
          matcher: transitOption != TransitOption.flight
              ? findsNWidgets(2)
              : findsNothing,
          reason:
              'Departure and arrival Geo location text fields should be displayed, but only for non-flight transit options',
        );
      }
    }

    // Verify confirmation ID field with scroll guard
    await _verifyWithScrollGuard(
      tester,
      widgetFinder: _travelEditorForm.confirmationIdEditingField,
      matcher:
          transitOption == TransitOption.walk ? findsNothing : findsOneWidget,
      reason:
          'Confirmation ID field should not be displayed for walk. It should be displayed otherwise.',
    );

    // Verify note field with scroll guard
    await _verifyWithScrollGuard(
      tester,
      widgetFinder: _travelEditorForm.commonFormElements.noteEditingField,
      matcher: findsOneWidget,
      reason: 'Note field should be displayed',
    );

    // Verify date time pickers with scroll guard
    await _verifyWithScrollGuard(
      tester,
      widgetFinder: _travelEditorForm.commonFormElements.dateTimePicker,
      matcher: findsNWidgets(2),
      reason: '2 Date and time pickers should be displayed',
    );
  }
}

/// Test: Add new transit via FloatingActionButton
Future<void> runAddWalkTransitTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

  // Tap the FAB to open add menu
  await _openTransitCreatorPage(tester);

  // Step 1: Select Transit Option as Walk
  await _travelEditorForm.selectTransitOption(tester, TransitOption.walk);

  var tripStartDate = DateTime(2025, 9, 24);
  var tripStartDayItinerary = TestHelpers.getTripRepository(tester)
      .activeTrip!
      .itineraryCollection
      .getItineraryForDay(tripStartDate);

  // Step 2: Set the departure and arrival locations
  final parisHotelLocationName =
      tripStartDayItinerary.checkInLodging!.location!.context.name;
  final parisSightLocationName =
      tripStartDayItinerary.planData.sights.first.location!.context.name;
  await _travelEditorForm.selectDepartureAndArrivalGeoLocations(
      tester, parisHotelLocationName, parisSightLocationName);

  // Step 3: Set the departure date and arrival time
  var travelStartTime = DateTime(2025, 9, 24, 14, 0);
  await _travelEditorForm.commonFormElements.selectDateTime(tester,
      dateTime: travelStartTime,
      startDateTime: tripStartDate,
      indexOfDateTimePicker: 0);
  var travelEndTime = DateTime(2025, 9, 24, 15, 30);
  await _travelEditorForm.commonFormElements.selectDateTime(tester,
      dateTime: travelEndTime,
      startDateTime: travelStartTime,
      indexOfDateTimePicker: 1);

  // Step 4: Set the note
  await TestHelpers.enterText(tester,
      _travelEditorForm.commonFormElements.noteEditingField, 'Test note');
}

Future<void> _openTransitCreatorPage(WidgetTester tester) async {
  final addFabButton = find.descendant(
      of: find.byType(Scaffold),
      matching: find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byIcon(Icons.add)));
  await TestHelpers.tapWidget(tester, addFabButton);

  // Look for "Travel Entry" or travel option
  await verifyAndOpenTripEntityEditor(tester, 'Transit', Icons.flight,
      'Travel Entry', 'Add transit information', TravelEditor);
}

Future<void> _verifyTransitOptions(
    WidgetTester tester, TransitOption defaultTransitOption) async {
  final transitOptionPicker =
      tester.widget<DropdownButton>(_travelEditorForm.transitOptionPicker);
  expect(transitOptionPicker.value == defaultTransitOption, isTrue,
      reason: '$defaultTransitOption option should be selected by default');
  await TestHelpers.tapWidget(tester, _travelEditorForm.transitOptionPicker);

  Finder? selectedDropDownEntry;
  final displayedTransitOptions = transitOptionPicker.items!;
  find.descendant(
      of: find.byType(DropdownMenuItem),
      matching: find.byWidget(displayedTransitOptions.first));
  final expectedTransitOptions = _getAllExpectedTransitOptionMetadatas(tester);
  expect(
      displayedTransitOptions.length == expectedTransitOptions.length, isTrue,
      reason: '$expectedTransitOptions transit options should be displayed');
  for (var index = 0; index < displayedTransitOptions.length; index++) {
    final displayedTransitOptionMenuItem = displayedTransitOptions[index];
    final expectedTransitOption = expectedTransitOptions.elementAt(index);
    expect(
        displayedTransitOptionMenuItem.value ==
            expectedTransitOption.transitOption,
        isTrue,
        reason:
            'Transit option ${expectedTransitOption.name} should be displayed');
    if (displayedTransitOptionMenuItem.value == defaultTransitOption) {
      selectedDropDownEntry =
          find.byWidget(displayedTransitOptionMenuItem).last;
    }
    expect(
        find.descendant(
            of: find.byWidget(displayedTransitOptionMenuItem).last,
            matching: find.byIcon(expectedTransitOption.icon)),
        findsOneWidget,
        reason: 'Transit option icon should be displayed');
    expect(
        find.descendant(
            of: find.byWidget(displayedTransitOptionMenuItem).last,
            matching: find.text(expectedTransitOption.name)),
        findsOneWidget,
        reason: 'Transit option name should be displayed');
  }
  if (selectedDropDownEntry != null) {
    await TestHelpers.tapWidget(tester, selectedDropDownEntry);
  }
}

Iterable<TransitOptionMetadata> _getAllExpectedTransitOptionMetadatas(
    WidgetTester tester) {
  final appLocalizations =
      TestHelpers.getAppLocalizations(tester, TravelEditor);
  var transitOptionMetadataList = <TransitOptionMetadata>[];
  transitOptionMetadataList.add(TransitOptionMetadata(
      transitOption: TransitOption.publicTransport,
      icon: Icons.emoji_transportation_rounded,
      name: appLocalizations.publicTransit));
  transitOptionMetadataList.add(TransitOptionMetadata(
      transitOption: TransitOption.flight,
      icon: Icons.flight_rounded,
      name: appLocalizations.flight));
  transitOptionMetadataList.add(TransitOptionMetadata(
      transitOption: TransitOption.bus,
      icon: Icons.directions_bus_rounded,
      name: appLocalizations.bus));
  transitOptionMetadataList.add(TransitOptionMetadata(
      transitOption: TransitOption.cruise,
      icon: Icons.kayaking_rounded,
      name: appLocalizations.cruise));
  transitOptionMetadataList.add(TransitOptionMetadata(
      transitOption: TransitOption.ferry,
      icon: Icons.directions_ferry_outlined,
      name: appLocalizations.ferry));
  transitOptionMetadataList.add(TransitOptionMetadata(
      transitOption: TransitOption.rentedVehicle,
      icon: Icons.car_rental_rounded,
      name: appLocalizations.carRental));
  transitOptionMetadataList.add(TransitOptionMetadata(
      transitOption: TransitOption.train,
      icon: Icons.train_rounded,
      name: appLocalizations.train));
  transitOptionMetadataList.add(TransitOptionMetadata(
      transitOption: TransitOption.vehicle,
      icon: Icons.bike_scooter_rounded,
      name: appLocalizations.personalVehicle));
  transitOptionMetadataList.add(TransitOptionMetadata(
      transitOption: TransitOption.walk,
      icon: Icons.directions_walk_rounded,
      name: appLocalizations.walk));
  transitOptionMetadataList.add(TransitOptionMetadata(
      transitOption: TransitOption.taxi,
      icon: Icons.local_taxi_rounded,
      name: appLocalizations.taxi));
  return transitOptionMetadataList;
}
