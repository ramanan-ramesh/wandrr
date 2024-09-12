import 'package:flutter/material.dart';
import 'package:wandrr/contracts/database_connectors/data_states.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_entity_facades/lodging.dart';
import 'package:wandrr/contracts/ui_element.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/trip_entity_list_elements.dart';

import 'lodging_list_item_components/closed_lodging.dart';
import 'lodging_list_item_components/opened_lodging.dart';

class LodgingListView extends StatelessWidget {
  const LodgingListView({super.key});

  @override
  Widget build(BuildContext context) {
    return TripEntityListView<LodgingFacade>(
      emptyListMessage: context.withLocale().noLodgingCreated,
      headerTileLabel: context.withLocale().lodging,
      uiElementsSorter: _sortLodgings,
      openedListElementCreator: (UiElement<LodgingFacade> uiElement,
              ValueNotifier<bool> validityNotifier) =>
          OpenedLodgingListItem(
        lodgingUiElement: uiElement,
        validityNotifier: validityNotifier,
      ),
      closedListElementCreator: (UiElement<LodgingFacade> uiElement) =>
          ClosedLodgingListItem(lodgingModelFacade: uiElement.element),
      uiElementsCreator: (TripDataFacade tripDataModelFacade) =>
          tripDataModelFacade
              .lodgings
              .map((lodging) =>
                  UiElement(element: lodging, dataState: DataState.None))
              .toList(),
    );
  }

  void _sortLodgings(List<UiElement<LodgingFacade>> lodgingUiElements) {
    var lodgingsWithValidDateTime = <UiElement<LodgingFacade>>[];
    var lodgingsWithInvalidDateTime = <UiElement<LodgingFacade>>[];
    for (var lodgingUiElement in lodgingUiElements) {
      var lodging = lodgingUiElement.element;
      if (lodging.checkinDateTime != null) {
        lodgingsWithValidDateTime.add(lodgingUiElement);
      } else {
        lodgingsWithInvalidDateTime.add(lodgingUiElement);
      }
    }
    lodgingsWithValidDateTime.sort((a, b) =>
        a.element.checkinDateTime!.compareTo(b.element.checkinDateTime!));
    lodgingUiElements = lodgingsWithValidDateTime
      ..addAll(lodgingsWithInvalidDateTime);
  }
}
