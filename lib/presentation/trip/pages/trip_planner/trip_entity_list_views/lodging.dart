import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/ui_element.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/constants.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/editable_list_items/lodging.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/trip_entity_list_view.dart';

import 'readonly_list_items/lodging.dart';

class LodgingListView extends StatelessWidget {
  const LodgingListView({super.key});

  @override
  Widget build(BuildContext context) {
    return TripEntityListView<LodgingFacade>(
      canConsiderUiElementForNavigation: (lodging, dateTime) {
        return lodging.checkinDateTime!.isOnSameDayAs(dateTime) ||
            lodging.checkoutDateTime!.isOnSameDayAs(dateTime);
      },
      section: NavigationSections.lodging,
      emptyListMessage: context.localizations.noLodgingCreated,
      headerTileLabel: context.localizations.lodging,
      uiElementsSorter: _sortLodgings,
      openedListElementCreator: (UiElement<LodgingFacade> uiElement,
              ValueNotifier<bool> validityNotifier) =>
          EditableLodgingPlan(
        lodgingUiElement: uiElement,
        validityNotifier: validityNotifier,
      ),
      closedListElementCreator: (UiElement<LodgingFacade> uiElement) =>
          ReadonlyLodgingPlan(lodgingModelFacade: uiElement.element),
      uiElementsCreator: (TripDataFacade tripDataModelFacade) =>
          tripDataModelFacade
              .lodgings
              .map((lodging) =>
                  UiElement(element: lodging, dataState: DataState.none))
              .toList(),
      errorMessageCreator: (lodgingUiElement) {
        var lodging = lodgingUiElement.element;
        if (lodging.location == null) {
          return context.localizations.lodgingAddressCannotBeEmpty;
        } else if (lodging.checkinDateTime == null ||
            lodging.checkoutDateTime == null) {
          return context.localizations.checkInAndCheckoutDatesCannotBeEmpty;
        }
        return null;
      },
    );
  }

  Iterable<UiElement<LodgingFacade>> _sortLodgings(
      List<UiElement<LodgingFacade>> lodgingUiElements) {
    var lodgingsWithValidDateTime = <UiElement<LodgingFacade>>[];
    var lodgingsWithInvalidDateTime = <UiElement<LodgingFacade>>[];
    for (final lodgingUiElement in lodgingUiElements) {
      var lodging = lodgingUiElement.element;
      if (lodging.checkinDateTime != null) {
        lodgingsWithValidDateTime.add(lodgingUiElement);
      } else {
        lodgingsWithInvalidDateTime.add(lodgingUiElement);
      }
    }
    lodgingsWithValidDateTime.sort((a, b) =>
        a.element.checkinDateTime!.compareTo(b.element.checkinDateTime!));
    return lodgingsWithInvalidDateTime..addAll(lodgingsWithValidDateTime);
  }
}
