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
  Future<void> enterNote(WidgetTester tester, String note) async {
    await TestHelpers.enterText(
        tester, commonFormElements.noteEditingField, note);
    print('[OK] Note entered');
  }

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

  /// Airport options are rendered in an Overlay, so search globally by key.
  Finder get airportLocationOption =>
      find.byKey(ValueKey('PlatformAutoComplete_ListTile'));

  Finder get geoLocationAutoCompleteTextField => find.descendant(
      of: find.descendant(
          of: find.byType(TravelEditor),
          matching: find.byType(PlatformGeoLocationAutoComplete)),
      matching: find.byKey(ValueKey('PlatformAutoComplete_TextField')));

  /// Finds geo-location option items in the autocomplete dropdown.
  /// Options are rendered in an Overlay (not under PlatformGeoLocationAutoComplete),
  /// so we search globally by key.
  Finder get geoLocationOption =>
      find.byKey(ValueKey('PlatformAutoComplete_ListTile'));

  Finder get airlineNameAutoCompleteTextField => find.descendant(
      of: find.descendant(
          of: find.byType(FlightDetailsEditor),
          matching: find.byType(
              PlatformAutoComplete<(String airLineName, String airLineCode)>)),
      matching: find.byKey(ValueKey('PlatformAutoComplete_TextField')));

  /// Airline options are rendered in an Overlay, so search globally by key.
  Finder get airlineNameOption =>
      find.byKey(ValueKey('PlatformAutoComplete_ListTile'));

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
    print('  [OK] Transit type switched to ${option.name}');
  }

  /// Enters [locationName] into a geo-location auto-complete field, waits for
  /// the debounce + async API call to complete, then taps the first matching
  /// option in the dropdown.
  Future<void> _selectGeoLocation(
    WidgetTester tester, {
    required Finder textField,
    required String locationName,
  }) async {
    await TestHelpers.enterText(tester, textField, locationName);
    // The PlatformAutoComplete debounces for 500 ms before querying.
    await tester.pump(const Duration(milliseconds: 600));
    // Allow the async HTTP mock response to arrive and the widget to rebuild.
    await tester.pumpAndSettle();

    final option = geoLocationOption;
    expect(option, findsAtLeastNWidgets(1),
        reason:
            'At least one geo-location option must appear for "$locationName"');
    await TestHelpers.tapWidget(tester, option.first);
  }

  // Enter the locationContext.name for departure and arrival
  Future<void> selectDepartureAndArrivalGeoLocations(WidgetTester tester,
      String departureLocation, String arrivalLocation) async {
    await _selectGeoLocation(
      tester,
      textField: geoLocationAutoCompleteTextField.first,
      locationName: departureLocation,
    );

    await _selectGeoLocation(
      tester,
      textField: geoLocationAutoCompleteTextField.last,
      locationName: arrivalLocation,
    );

    print(
        '[OK] Departure "$departureLocation" -> Arrival "$arrivalLocation" set');
  }
}
