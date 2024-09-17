import 'package:flutter/material.dart';
import 'package:wandrr/app_data/models/data_states.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/trip_data/models/transit.dart';
import 'package:wandrr/trip_data/models/trip_data.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/editable_list_elements/transit.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/trip_entity_list_elements.dart';

import '../readonly_list_elements/transit.dart';
import '../transit_option_metadata.dart';

class TransitListView extends StatelessWidget {
  const TransitListView({super.key});

  @override
  Widget build(BuildContext context) {
    var transitOptionMetadataList = _initializeIconsAndTransitOptions(context);
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

  List<TransitOptionMetadata> _initializeIconsAndTransitOptions(
      BuildContext context) {
    var transitOptionMetadataList = <TransitOptionMetadata>[];
    var appLocalizations = context.withLocale();
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.PublicTransport,
        icon: Icons.emoji_transportation_rounded,
        name: appLocalizations.publicTransit));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Flight,
        icon: Icons.flight_rounded,
        name: appLocalizations.flight));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Bus,
        icon: Icons.directions_bus_rounded,
        name: appLocalizations.bus));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Cruise,
        icon: Icons.kayaking_rounded,
        name: appLocalizations.cruise));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Ferry,
        icon: Icons.directions_ferry_outlined,
        name: appLocalizations.ferry));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.RentedVehicle,
        icon: Icons.car_rental_rounded,
        name: appLocalizations.carRental));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Train,
        icon: Icons.train_rounded,
        name: appLocalizations.train));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Vehicle,
        icon: Icons.bike_scooter_rounded,
        name: appLocalizations.personalVehicle));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.Walk,
        icon: Icons.directions_walk_rounded,
        name: appLocalizations.walk));
    return transitOptionMetadataList;
  }

  void _sortTransits(List<UiElement<TransitFacade>> transitUiElements) {
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
  }
}
