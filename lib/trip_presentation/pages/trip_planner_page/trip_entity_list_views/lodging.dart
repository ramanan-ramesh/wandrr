import 'package:flutter/material.dart';
import 'package:wandrr/app_data/models/data_states.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/trip_data/models/lodging.dart';
import 'package:wandrr/trip_data/models/trip_data.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/editable_list_elements/lodging.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/readonly_list_elements/lodging.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/trip_entity_list_elements.dart';

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
          EditableLodgingListItem(
        lodgingUiElement: uiElement,
        validityNotifier: validityNotifier,
      ),
      closedListElementCreator: (UiElement<LodgingFacade> uiElement) =>
          ReadonlyLodgingListItem(lodgingModelFacade: uiElement.element),
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
