import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/presentation/app/extensions.dart';

import '../../data/trip/models/api_services/currency_data.dart';
import '../../data/trip/models/trip_data.dart';
import '../../data/trip/models/trip_repository.dart';

extension TripRepositoryExtensions on BuildContext {
  Iterable<CurrencyData> get supportedCurrencies =>
      tripRepository.currencyConverter.supportedCurrencies;

  TripRepositoryFacade get tripRepository =>
      RepositoryProvider.of<TripRepositoryFacade>(this);

  TripDataFacade get activeTrip => tripRepository.activeTrip!;

  void updateLocalizations() {
    (tripRepository as TripRepositoryEventHandler)
        .updateLocalizations(localizations);
  }
}
