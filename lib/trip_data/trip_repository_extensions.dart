import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'models/trip_data.dart';
import 'models/trip_repository.dart';

extension TripRepositoryExtensions on BuildContext {
  TripRepositoryFacade getTripRepository() {
    return RepositoryProvider.of<TripRepositoryFacade>(this);
  }

  TripDataFacade getActiveTrip() {
    return getTripRepository().activeTrip!;
  }
}
