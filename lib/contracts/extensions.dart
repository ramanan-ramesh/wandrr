import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/contracts/app_level_data.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/contracts/trip_repository.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';

extension DateTimeExt on DateTime {
  int calculateDaysInBetween(DateTime dateTime,
      {bool includeExtraDay = false}) {
    var startDate = DateTime(year, month, day);
    var endDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    var numberOfDaysOfTrip = startDate.difference(endDate).inDays;
    return numberOfDaysOfTrip.abs() + (includeExtraDay ? 1 : 0);
  }

  bool isOnSameDayAs(DateTime dateTime) {
    return year == dateTime.year &&
        month == dateTime.month &&
        day == dateTime.day;
  }
}

extension RepositoryExt on BuildContext {
  PlatformDataRepositoryFacade getPlatformDataRepository() {
    return RepositoryProvider.of<PlatformDataRepositoryFacade>(this);
  }

  AppLevelDataFacade getAppLevelData() {
    return getPlatformDataRepository().appData;
  }

  bool isBigLayout() {
    return getAppLevelData().isBigLayout;
  }

  TripRepositoryModelFacade getTripRepository() {
    return RepositoryProvider.of<TripRepositoryModelFacade>(this);
  }

  TripDataModelFacade getActiveTrip() {
    return getTripRepository().activeTrip!;
  }
}
