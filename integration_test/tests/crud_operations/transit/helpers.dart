import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/store/models/collection_item_change_metadata.dart';
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
      matching: find.byKey(
          const ValueKey('TransitEditor_TransitOptionPicker_DropdownButton')));

  Finder get transitOperatorEditingField => find.descendant(
      of: find.byType(TravelEditor),
      matching: find
          .byKey(const ValueKey('TransitEditor_TransitOperator_TextField')));

  Finder get confirmationIdEditingField => find.descendant(
      of: find.byType(TravelEditor),
      matching:
          find.byKey(const ValueKey('TransitEditor_ConfirmationId_TextField')));

  Finder get airportLocationAutoCompleteTextField => find.descendant(
      of: find.byType(AirportsDataEditorSection),
      matching: find.byKey(const ValueKey('PlatformAutoComplete_TextField')));

  /// Airport options are rendered in an Overlay, so search globally by key.
  Finder get airportLocationOption =>
      find.byKey(const ValueKey('PlatformAutoComplete_ListTile'));

  Finder get geoLocationAutoCompleteTextField => find.descendant(
      of: find.descendant(
          of: find.byType(TravelEditor),
          matching: find.byType(PlatformGeoLocationAutoComplete)),
      matching: find.byKey(const ValueKey('PlatformAutoComplete_TextField')));

  /// Finds geo-location option items in the autocomplete dropdown.
  /// Options are rendered in an Overlay (not under PlatformGeoLocationAutoComplete),
  /// so we search globally by key.
  Finder get geoLocationOption =>
      find.byKey(const ValueKey('PlatformAutoComplete_ListTile'));

  Finder get airlineNameAutoCompleteTextField => find.descendant(
      of: find.descendant(
          of: find.byType(FlightDetailsEditor),
          matching: find.byType(
              PlatformAutoComplete<(String airLineName, String airLineCode)>)),
      matching: find.byKey(const ValueKey('PlatformAutoComplete_TextField')));

  /// Airline options are rendered in an Overlay, so search globally by key.
  Finder get airlineNameOption =>
      find.byKey(const ValueKey('PlatformAutoComplete_ListTile'));

  Finder get airlineNumberTextField => find.descendant(
      of: find.byType(FlightDetailsEditor),
      matching: find
          .byKey(const ValueKey('FlightDetailsEditor_FlightNumber_TextField')));

  Finder get departurePlatformEditingField => find.descendant(
      of: find.byType(TravelEditor),
      matching: find.byKey(
          const ValueKey('JourneyPointEditor_Platform_TextField_Departure')));

  Finder get arrivalPlatformEditingField => find.descendant(
      of: find.byType(TravelEditor),
      matching: find.byKey(
          const ValueKey('JourneyPointEditor_Platform_TextField_Arrival')));

  Finder get activeUserSeatEditingField => find.descendant(
      of: find.byType(TravelEditor),
      matching:
          find.byKey(const ValueKey('TravelEditor_ActiveUserSeat_TextField')));

  Finder get expandSeatsButton => find.descendant(
      of: find.byType(TravelEditor),
      matching: find.byKey(const ValueKey('TravelEditor_ExpandSeats_Button')));

  Finder tripmateSeatEditingField(String userName) => find.descendant(
      of: find.byType(TravelEditor),
      matching: find
          .byKey(ValueKey('TravelEditor_TripmateSeat_TextField_$userName')));

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

/// Opens the Transit creator bottom-sheet and navigates into the TravelEditor.
Future<void> openTransitCreatorPage(WidgetTester tester) async {
  await openCreatorAndNavigateToEditor(
    tester,
    entityName: 'Transit',
    icon: Icons.flight,
    title: 'Travel Entry',
    subTitle: 'Add transit information',
    editorType: TravelEditor,
  );
  print('[OK] Transit creator opened');
}

/// Taps the ConflictAwareActionPage FAB to submit the transit form, awaits the
/// newly-added [TransitFacade] from the collection stream, then runs [onTransitAdded].
///
/// [form] must be the same [TravelEditorForm] instance used to fill the form fields.
Future<void> submitTransitAndVerify(
  WidgetTester tester,
  TravelEditorForm form, {
  required Future<void> Function(TransitFacade transit) onTransitAdded,
}) async {
  // Subscribe BEFORE tapping so no event is missed.
  final collection =
      TestHelpers.getTripRepository(tester).activeTrip!.transitCollection;
  final completer = Completer<TransitFacade>();
  late StreamSubscription<CollectionItemChangeMetadata<TransitFacade>> sub;
  sub = collection.onDocumentAdded.listen((event) async {
    if (event.isFromExplicitAction && !completer.isCompleted) {
      completer.complete(event.collectionItemChange);
      await sub.cancel();
    }
  });

  final fab = form.commonFormElements.createTripEntityButton;
  expect(fab, findsOneWidget,
      reason: 'ConflictAwareActionPage submit FAB must be present and enabled');
  await TestHelpers.tapWidget(tester, fab);
  print('[OK] Tapped ConflictAwareActionPage FAB -> submitted transit');

  // Keep pumping until TravelEditor is dismissed or timeout.
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.byType(TravelEditor).evaluate().isEmpty) {
      break;
    }
  }
  await Future.delayed(const Duration(seconds: 5), () {
    if (find.byType(TravelEditor).evaluate().isEmpty) {
      return;
    }
  });

  // Verify TravelEditor is dismissed.
  expect(find.byType(TravelEditor), findsNothing,
      reason:
          'TravelEditor must be dismissed after Firestore operation completes');
  print('[OK] Bottom-sheet dismissed');

  // Await the stream event.
  TransitFacade? transit;
  if (completer.isCompleted) {
    transit = await completer.future;
  } else {
    transit = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () async {
        await sub.cancel();
        throw TestFailure(
            'transitCollection.onDocumentAdded did not fire after editor dismissal');
      },
    );
  }
  await sub.cancel();

  print(
      '[OK] transitCollection.onDocumentAdded received: $transit (id: ${transit.id})');

  await tester.pumpAndSettle();
  await onTransitAdded(transit);
}
