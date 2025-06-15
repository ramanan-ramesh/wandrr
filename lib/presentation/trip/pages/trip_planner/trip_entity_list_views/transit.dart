import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/editable_list_items/transit/transit.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/readonly_list_items/transit.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/trip_entity_list_view.dart';

class TransitListView extends StatelessWidget {
  const TransitListView({super.key});

  @override
  Widget build(BuildContext context) {
    return TripEntityListView<TransitFacade>(
      emptyListMessage: context.localizations.noTransitsCreated,
      headerTileLabel: context.localizations.transit,
      uiElementsSorter: _sortTransits,
      openedListElementCreator: (UiElement<TransitFacade> uiElement,
              ValueNotifier<bool> validityNotifier) =>
          EditableTransitPlan(
        transitUiElement: uiElement,
        validityNotifier: validityNotifier,
      ),
      closedListElementCreator: (UiElement<TransitFacade> uiElement) =>
          ReadonlyTransitPlan(transitFacade: uiElement.element),
      uiElementsCreator: (TripDataFacade tripDataModelFacade) =>
          tripDataModelFacade
              .transits
              .map((transit) =>
                  UiElement(element: transit, dataState: DataState.none))
              .toList(),
      errorMessageCreator: (transitUiElement) {
        var transit = transitUiElement.element;
        if (transit.arrivalLocation == null ||
            transit.departureLocation == null) {
          return context.localizations.departureArrivalLocationCannotBeEmpty;
        } else if (transit.departureLocation == transit.arrivalLocation) {
          return context.localizations.departureAndArrivalLocationsCannotBeSame;
        } else if (transit.departureDateTime == null ||
            transit.arrivalDateTime == null) {
          return context.localizations.departureArrivalDateTimeCannotBeEmpty;
        } else if (transit.arrivalDateTime!
            .isBefore(transit.departureDateTime!)) {
          return context.localizations.arrivalDepartureDateTimesError;
        }
        return null;
      },
    );
  }

  Iterable<UiElement<TransitFacade>> _sortTransits(
      List<UiElement<TransitFacade>> transitUiElements) {
    var newUiEntries = transitUiElements
        .where((element) => element.dataState == DataState.newUiEntry)
        .toList();
    transitUiElements
        .removeWhere((element) => element.dataState == DataState.newUiEntry);
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
