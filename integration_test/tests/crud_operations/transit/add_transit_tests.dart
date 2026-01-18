import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/travel_editor.dart';

import '../../../helpers/test_config.dart';
import '../../../helpers/test_helpers.dart';
import '../helpers.dart';
import 'helpers.dart';

/// Test: Add new transit via FloatingActionButton
Future<void> runVerifyDefaultStateTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

  // Tap the FAB to open add menu
  final addFabButton = find.descendant(
      of: find.byType(Scaffold),
      matching: find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byIcon(Icons.add)));
  await TestHelpers.tapWidget(tester, addFabButton);

  // Look for "Travel Entry" or travel option
  await verifyAndOpenTripEntityEditor(tester, 'Transit', Icons.flight,
      'Travel Entry', 'Add a new travel entry', TravelEditor);

  final travelEditorForm = TravelEditorForm();

  final transitOptionPicker =
      tester.widget<DropdownButton>(travelEditorForm.transitOptionPicker);
  expect(transitOptionPicker.value == TransitOption.publicTransport, isTrue,
      reason: 'Public transport option should be selected by default');
  _verifyAvailableTransitOptions(transitOptionPicker, tester);

  final tripMetadata =
      TestHelpers.getTripRepository(tester).activeTrip!.tripMetadata;
  for (final transitOption in TransitOption.values) {
    await travelEditorForm.selectTransitOption(tester, transitOption);

    final paidByContributorTileFinder =
        travelEditorForm.commonFormElements.paidByTabContributorTile;
    final expenseAmountTextFieldFinder = find.descendant(
        of: paidByContributorTileFinder,
        matching: find.byKey(ValueKey('ExpenseAmountEditField_TextField')));
    if (transitOption == TransitOption.walk) {
      expect(paidByContributorTileFinder, findsNothing,
          reason: 'Paid by contributor tile should not be displayed for walk');
      expect(expenseAmountTextFieldFinder, findsNothing,
          reason: 'Expense amount field should not be displayed for walk');

      expect(travelEditorForm.transitOperatorEditingField, findsNothing,
          reason: 'Transit operator field should not be displayed for walk');
      expect(travelEditorForm.geoLocationAutoCompleteTextField, findsNothing,
          reason:
              'Departure and arrival Geo location text fields should not be displayed for walk');
      expect(
          travelEditorForm.airportLocationAutoCompleteTextField, findsNothing,
          reason:
              'Departure and arrival Airport location text fields should not be displayed for walk');
    } else {
      var numberOfContributors = tripMetadata.contributors.length;
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
              of: travelEditorForm.commonFormElements.paidByTabContributorTile,
              matching: find.text('You')),
          findsOneWidget,
          reason: 'You should be a contributor in PaidBy');
      expect(
          find.descendant(
              of: travelEditorForm.commonFormElements.paidByTabContributorTile,
              matching:
                  find.text(TestConfig.tripMateUserName.split('@').first)),
          findsOneWidget,
          reason: 'Tripmate should be a contributor in PaidBy');
      expect(
          find.descendant(
              of: travelEditorForm.commonFormElements.splitByContributorTile,
              matching: find.text('You')),
          findsOneWidget,
          reason: 'You should be a contributor to split');
      expect(
          find.descendant(
              of: travelEditorForm.commonFormElements.splitByContributorTile,
              matching:
                  find.text(TestConfig.tripMateUserName.split('@').first)),
          findsOneWidget,
          reason: 'Tripmate should be a contributor to split');
      final splitByListTiles = tester.widgetList<ListTile>(
          travelEditorForm.commonFormElements.splitByContributorTile);
      for (final splitByListTile in splitByListTiles) {
        expect(splitByListTile.selected, isTrue,
            reason: 'Entry should be selected in SplitBy');
      }

      expect(travelEditorForm.transitOperatorEditingField,
          transitOption != TransitOption.flight ? findsOneWidget : findsNothing,
          reason:
              'Transit operator field should be displayed only for non-flight transit options');
      expect(travelEditorForm.airlineNameAutoCompleteTextField,
          transitOption == TransitOption.flight ? findsOneWidget : findsNothing,
          reason:
              'Airline name text field should be displayed only for flights');
      expect(travelEditorForm.airlineNumberTextField,
          transitOption == TransitOption.flight ? findsOneWidget : findsNothing,
          reason:
              'Airline number text field should be displayed only for flights');

      expect(
          travelEditorForm.geoLocationAutoCompleteTextField,
          transitOption != TransitOption.flight
              ? findsNWidgets(2)
              : findsNothing,
          reason:
              'Departure and arrival Geo location text fields should be displayed only for non-flight transit options');
      expect(
          travelEditorForm.airportLocationAutoCompleteTextField,
          transitOption == TransitOption.flight
              ? findsNWidgets(2)
              : findsNothing,
          reason:
              'Departure and arrival Airport location text fields should be displayed only for flights');
    }
    expect(travelEditorForm.confirmationIdEditingField,
        transitOption == TransitOption.walk ? findsNothing : findsOneWidget,
        reason:
            'Confirmation ID field should not be displayed for walk. It should be displayed otherwise.');

    expect(travelEditorForm.commonFormElements.noteEditingField, findsOneWidget,
        reason: 'Note field should be displayed');
  }
}

/// Test: Add new transit via FloatingActionButton
Future<void> runAddTransitTest(WidgetTester tester) async {
  // Launch the app
  await TestHelpers.pumpAndSettleApp(tester);

  await TestHelpers.navigateToTripEditorPage(tester);

  // Tap the FAB to open add menu
  final addFabButton = find.descendant(
      of: find.byType(Scaffold),
      matching: find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byIcon(Icons.add)));
  await TestHelpers.tapWidget(tester, addFabButton);

  // Look for "Travel Entry" or travel option
  await verifyAndOpenTripEntityEditor(tester, 'Transit', Icons.flight,
      'Travel Entry', 'Add a new travel entry', TravelEditor);

  final travelEditorForm = TravelEditorForm();

  final transitOptionPicker =
      tester.widget<DropdownButton>(travelEditorForm.transitOptionPicker);
  expect(transitOptionPicker.value == TransitOption.publicTransport, isTrue,
      reason: 'Public transport option should be selected by default');
  _verifyAvailableTransitOptions(transitOptionPicker, tester);
}

void _verifyAvailableTransitOptions(
    DropdownButton<dynamic> transitOptionPicker, WidgetTester tester) {
  final displayedTransitOptions = transitOptionPicker.items!;
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
    expect(
        find.descendant(
            of: find.byWidget(displayedTransitOptionMenuItem),
            matching: find.byIcon(expectedTransitOption.icon)),
        findsOneWidget,
        reason: 'Transit option icon should be displayed');
    expect(
        find.descendant(
            of: find.byWidget(displayedTransitOptionMenuItem),
            matching: find.text(expectedTransitOption.name)),
        findsOneWidget,
        reason: 'Transit option name should be displayed');
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
