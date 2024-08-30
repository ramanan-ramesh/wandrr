import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/data_states.dart';
import 'package:wandrr/contracts/lodging.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/trip_entity_list_elements.dart';

import 'lodging_list_item_components/closed_lodging.dart';
import 'lodging_list_item_components/opened_lodging.dart';

class LodgingListView extends StatelessWidget {
  const LodgingListView({super.key});

  @override
  Widget build(BuildContext context) {
    return TripEntityListView<LodgingModelFacade>(
      emptyListMessage: AppLocalizations.of(context)!.noLodgingCreated,
      headerTileLabel: AppLocalizations.of(context)!.lodging,
      uiElementsSorter: _sortLodgings,
      openedListElementCreator: (UiElement<LodgingModelFacade> uiElement,
              ValueNotifier<bool> validityNotifier) =>
          OpenedLodgingListItem(
        lodgingUiElement: uiElement,
        validityNotifier: validityNotifier,
      ),
      closedListElementCreator: (UiElement<LodgingModelFacade> uiElement) =>
          ClosedLodgingListItem(lodgingModelFacade: uiElement.element),
      uiElementsCreator: (TripDataModelFacade tripDataModelFacade) =>
          tripDataModelFacade.lodgings
              .map((lodging) =>
                  UiElement(element: lodging, dataState: DataState.None))
              .toList(),
    );
  }

  void _sortLodgings(List<UiElement<LodgingModelFacade>> lodgingUiElements) {
    var lodgingsWithValidDateTime = <UiElement<LodgingModelFacade>>[];
    var lodgingsWithInvalidDateTime = <UiElement<LodgingModelFacade>>[];
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
