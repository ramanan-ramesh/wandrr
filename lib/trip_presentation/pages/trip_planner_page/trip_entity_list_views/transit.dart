import 'package:flutter/material.dart';
import 'package:wandrr/app_data/models/data_states.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/trip_data/models/transit.dart';
import 'package:wandrr/trip_data/models/trip_data.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/editable_list_elements/transit/transit.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/trip_entity_list_views/trip_entity_list_view.dart';

import '../readonly_list_elements/transit.dart';

class TransitListView extends StatelessWidget {
  const TransitListView({super.key});

  @override
  Widget build(BuildContext context) {
    var transitOptionMetadataList =
        context.getTripRepository().activeTrip!.transitOptionMetadatas;
    return TripEntityListView<TransitFacade>(
      emptyListMessage: context.withLocale().noTransitsCreated,
      headerTileLabel: context.withLocale().transit,
      uiElementsSorter: _sortTransits,
      openedListElementCreator: (UiElement<TransitFacade> uiElement,
              ValueNotifier<bool> validityNotifier) =>
          EditableTransitListItem(
        transitUiElement: uiElement,
        transitOptionMetadatas: transitOptionMetadataList,
        validityNotifier: validityNotifier,
      ),
      closedListElementCreator: (UiElement<TransitFacade> uiElement) =>
          ReadonlyTransitListItem(
              transitModelFacade: uiElement.element,
              transitOptionMetadatas: transitOptionMetadataList),
      uiElementsCreator: (TripDataFacade tripDataModelFacade) =>
          tripDataModelFacade
              .transits
              .map((transit) =>
                  UiElement(element: transit, dataState: DataState.None))
              .toList(),
    );
  }

  Iterable<UiElement<TransitFacade>> _sortTransits(
      List<UiElement<TransitFacade>> transitUiElements) {
    var newUiEntries = transitUiElements
        .where((element) => element.dataState == DataState.NewUiEntry)
        .toList();
    transitUiElements
        .removeWhere((element) => element.dataState == DataState.NewUiEntry);
    var transitsWithValidDateTime = <UiElement<TransitFacade>>[];
    var transitsWithInvalidDateTime = <UiElement<TransitFacade>>[];
    for (var transitUiElement in transitUiElements) {
      var transit = transitUiElement.element;
      if (transit.departureDateTime != null &&
          transit.arrivalDateTime != null) {
        transitsWithValidDateTime.add(transitUiElement);
      } else {
        transitsWithInvalidDateTime.add(transitUiElement);
      }
    }
    transitUiElements.clear();
    transitUiElements.addAll(newUiEntries);
    transitsWithValidDateTime.sort((a, b) =>
        a.element.departureDateTime!.compareTo(b.element.departureDateTime!));
    transitUiElements.addAll(transitsWithValidDateTime);
    transitUiElements.addAll(transitsWithInvalidDateTime);
    return transitUiElements;
  }
}
