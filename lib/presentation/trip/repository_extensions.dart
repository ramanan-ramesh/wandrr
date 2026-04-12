import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/transit_option_metadata.dart';

extension TripRepositoryExtensions on BuildContext {
  Iterable<CurrencyData> get supportedCurrencies =>
      tripRepository.supportedCurrencies;

  TripRepositoryFacade get tripRepository =>
      RepositoryProvider.of<TripRepositoryFacade>(this);

  ApiServicesRepositoryFacade get apiServicesRepository =>
      RepositoryProvider.of<ApiServicesRepositoryFacade>(this);

  TripDataFacade get activeTrip => tripRepository.activeTrip!;

  String get activeTripId => activeTrip.tripMetadata.id!;

  List<TransitOptionMetadata> get transitOptionMetadatas => [
        TransitOptionMetadata(
            transitOption: TransitOption.publicTransport,
            icon: Icons.emoji_transportation_rounded,
            name: localizations.publicTransit),
        TransitOptionMetadata(
            transitOption: TransitOption.flight,
            icon: Icons.flight_rounded,
            name: localizations.flight),
        TransitOptionMetadata(
            transitOption: TransitOption.bus,
            icon: Icons.directions_bus_rounded,
            name: localizations.bus),
        TransitOptionMetadata(
            transitOption: TransitOption.cruise,
            icon: Icons.kayaking_rounded,
            name: localizations.cruise),
        TransitOptionMetadata(
            transitOption: TransitOption.ferry,
            icon: Icons.directions_ferry_outlined,
            name: localizations.ferry),
        TransitOptionMetadata(
            transitOption: TransitOption.rentedVehicle,
            icon: Icons.car_rental_rounded,
            name: localizations.carRental),
        TransitOptionMetadata(
            transitOption: TransitOption.train,
            icon: Icons.train_rounded,
            name: localizations.train),
        TransitOptionMetadata(
            transitOption: TransitOption.vehicle,
            icon: Icons.bike_scooter_rounded,
            name: localizations.personalVehicle),
        TransitOptionMetadata(
            transitOption: TransitOption.walk,
            icon: Icons.directions_walk_rounded,
            name: localizations.walk),
        TransitOptionMetadata(
            transitOption: TransitOption.taxi,
            icon: Icons.local_taxi_rounded,
            name: localizations.taxi),
      ];

  TransitOptionMetadata getTransitOptionMetadata(TransitOption option) {
    return transitOptionMetadatas.firstWhere((e) => e.transitOption == option);
  }
}
