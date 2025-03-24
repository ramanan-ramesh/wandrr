import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/trip/models/currency_data.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/l10n/extension.dart';

extension TripRepositoryExtensions on BuildContext {
  Iterable<CurrencyData> get supportedCurrencies =>
      tripRepository.supportedCurrencies;

  TripRepositoryFacade get tripRepository =>
      RepositoryProvider.of<TripRepositoryFacade>(this);

  TripDataFacade get activeTrip => tripRepository.activeTrip!;

  void updateLocalizations() {
    (tripRepository as TripRepositoryEventHandler)
        .updateLocalizations(localizations);
  }
}
