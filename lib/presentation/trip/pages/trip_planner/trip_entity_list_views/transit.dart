import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/trip_repository_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/editable_trip_entity/transit/transit.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/trip_entity_list_view.dart';

import '../readonly_trip_entity/transit.dart';

class TransitListView extends StatelessWidget {
  const TransitListView({super.key});

  @override
  Widget build(BuildContext context) {
    var transitOptionMetadataList =
        context.tripRepository.activeTrip!.transitOptionMetadatas;
    return TripEntityListView<TransitFacade>(
      emptyListMessage: context.localizations.noTransitsCreated,
      headerTileLabel: context.localizations.transit,
      uiElementsSorter: _sortTransits,
      openedListElementCreator: (UiElement<TransitFacade> uiElement,
              ValueNotifier<bool> validityNotifier) =>
          EditableTransitListItem(
        transitUiElement: uiElement,
        transitOptionMetadatas: transitOptionMetadataList,
        validityNotifier: validityNotifier,
      ),
      closedListElementCreator: (UiElement<TransitFacade> uiElement) =>
          ReadonlyTransitListItem(transitModelFacade: uiElement.element),
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
