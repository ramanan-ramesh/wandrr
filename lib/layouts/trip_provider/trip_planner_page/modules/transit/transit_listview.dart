import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/data_states.dart';
import 'package:wandrr/contracts/transit.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/trip_entity_list_elements.dart';

import 'transit_list_item_components/closed_transit.dart';
import 'transit_list_item_components/opened_transit.dart';
import 'transit_option_metadata.dart';

class TransitListView extends StatelessWidget {
  const TransitListView({super.key});

  @override
  Widget build(BuildContext context) {
    var transitOptionMetadataList = _initializeIconsAndTransitOptions(context);
    return TripEntityListView<TransitModelFacade>(
      emptyListMessage: AppLocalizations.of(context)!.noTransitsCreated,
      headerTileLabel: AppLocalizations.of(context)!.transit,
      uiElementsSorter: _sortTransits,
      openedListElementCreator: (UiElement<TransitModelFacade> uiElement,
              ValueNotifier<bool> validityNotifier) =>
          OpenedTransitListItem(
        transitUiElement: uiElement,
        transitOptionMetadatas: transitOptionMetadataList,
        validityNotifier: validityNotifier,
      ),
      closedListElementCreator: (UiElement<TransitModelFacade> uiElement) =>
          ClosedTransitListItem(
              transitModelFacade: uiElement.element,
              transitOptionMetadatas: transitOptionMetadataList),
      uiElementsCreator: (TripDataModelFacade tripDataModelFacade) =>
          tripDataModelFacade.transits
              .map((transit) =>
                  UiElement(element: transit, dataState: DataState.None))
              .toList(),
    );
  }

  List<TransitOptionMetadata> _initializeIconsAndTransitOptions(
      BuildContext context) {
    var transitOptionMetadataList = <TransitOptionMetadata>[];
    var appLocalizations = AppLocalizations.of(context)!;
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

  void _sortTransits(List<UiElement<TransitModelFacade>> transitUiElements) {
    var newUiEntries = transitUiElements
        .where((element) => element.dataState == DataState.NewUiEntry)
        .toList();
    transitUiElements
        .removeWhere((element) => element.dataState == DataState.NewUiEntry);
    var transitsWithValidDateTime = <UiElement<TransitModelFacade>>[];
    var transitsWithInvalidDateTime = <UiElement<TransitModelFacade>>[];
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
