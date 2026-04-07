import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/presentation/app/widgets/auto_complete.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/airport_data_editor_section.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/flight_details_editor_section.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/travel_editor.dart';
import 'package:wandrr/presentation/trip/widgets/geo_location_auto_complete.dart';

import '../../../helpers/test_helpers.dart';
import '../helpers.dart';

class TravelEditorForm {
  final CommonFormElements commonFormElements =
      CommonFormElements(TravelEditor);

  Finder get transitOptionPicker => find.descendant(
      of: find.byType(TravelEditor),
      matching: find
          .byKey(ValueKey('TransitEditor_TransitOptionPicker_DropdownButton')));

  Finder get transitOperatorEditingField => find.descendant(
      of: find.byType(TravelEditor),
      matching:
          find.byKey(ValueKey('TransitEditor_TransitOperator_TextField')));

  Finder get confirmationIdEditingField => find.descendant(
      of: find.byType(TravelEditor),
      matching: find.byKey(ValueKey('TransitEditor_ConfirmationId_TextField')));

  Finder get airportLocationAutoCompleteTextField => find.descendant(
      of: find.byType(AirportsDataEditorSection),
      matching: find.byKey(ValueKey('PlatformAutoComplete_TextField')));

  Finder get airportLocationOption => find.descendant(
      of: find.byType(AirportsDataEditorSection),
      matching: find.byKey(ValueKey('PlatformAutoComplete_ListTile')));

  Finder get geoLocationAutoCompleteTextField => find.descendant(
      of: find.descendant(
          of: find.byType(TravelEditor),
          matching: find.byType(PlatformGeoLocationAutoComplete)),
      matching: find.byKey(ValueKey('PlatformAutoComplete_TextField')));

  Finder get geoLocationOption => find.descendant(
      of: find.byType(PlatformGeoLocationAutoComplete),
      matching: find.byKey(ValueKey('PlatformAutoComplete_ListTile')));

  Finder get airlineNameAutoCompleteTextField => find.descendant(
      of: find.descendant(
          of: find.byType(FlightDetailsEditor),
          matching: find.byType(PlatformAutoComplete)),
      matching: find.byKey(ValueKey('PlatformAutoComplete_TextField')));

  Finder get airlineNameOption => find.descendant(
      of: find.byType(FlightDetailsEditor),
      matching: find.byKey(ValueKey('PlatformAutoComplete_ListTile')));

  Finder get airlineNumberTextField => find.descendant(
      of: find.byType(FlightDetailsEditor),
      matching:
          find.byKey(ValueKey('FlightDetailsEditor_FlightNumber_TextField')));

  // Select a transit option from drop-down
  Future<void> selectTransitOption(
      WidgetTester tester, TransitOption option) async {
    await TestHelpers.tapWidget(tester, transitOptionPicker);
    final transitOptionPickerDropDown =
        tester.widget<DropdownButton>(transitOptionPicker);
    final dropDownMenuItemToSelect = transitOptionPickerDropDown.items!
        .singleWhere((menuItem) => menuItem.value == option);
    final dropDownMenuItemFinder = find.byWidget(dropDownMenuItemToSelect);
    await TestHelpers.tapWidget(tester, dropDownMenuItemFinder,
        warnIfMissed: false);
  }

  // Enter the locationContext.name for departure and arrival
  Future<void> selectDepartureAndArrivalGeoLocations(WidgetTester tester,
      String departureLocation, String arrivalLocation) async {
    final departureLocationField = geoLocationAutoCompleteTextField.first;
    await TestHelpers.enterText(
        tester, departureLocationField, departureLocation);
    final departureLocationOption = geoLocationOption.first;
    await TestHelpers.tapWidget(tester, departureLocationOption);

    final arrivalLocationField = geoLocationAutoCompleteTextField.last;
    await TestHelpers.enterText(tester, arrivalLocationField, arrivalLocation);
    final arrivalLocationOption = geoLocationOption.last;
    await TestHelpers.tapWidget(tester, arrivalLocationOption);
  }
}
