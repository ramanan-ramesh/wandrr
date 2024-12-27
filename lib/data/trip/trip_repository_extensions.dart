import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'models/api_services/currency_data.dart';
import 'models/trip_data.dart';
import 'models/trip_repository.dart';

extension TripRepositoryExtensions on BuildContext {
  Iterable<CurrencyData> get supportedCurrencies =>
      tripRepository.currencyConverter.supportedCurrencies;

  TripRepositoryFacade get tripRepository =>
      RepositoryProvider.of<TripRepositoryFacade>(this);

  TripDataFacade get activeTrip => tripRepository.activeTrip!;
}
