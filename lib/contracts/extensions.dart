import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/authentication_bloc/auth_bloc.dart';
import 'package:wandrr/blocs/authentication_bloc/auth_events.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_bloc.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_events.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
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

extension AppLocalizationsExt on BuildContext {
  AppLocalizations withLocale() {
    return AppLocalizations.of(this)!;
  }
}

extension BlocProviderExt on BuildContext {
  void addAuthenticationEvent(AuthenticationEvent event) {
    BlocProvider.of<AuthenticationBloc>(this).add(event);
  }

  void addMasterPageEvent(MasterPageEvent event) {
    BlocProvider.of<MasterPageBloc>(this).add(event);
  }

  void addTripManagementEvent(TripManagementEvent event) {
    BlocProvider.of<TripManagementBloc>(this).add(event);
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

  TripRepositoryFacade getTripRepository() {
    return RepositoryProvider.of<TripRepositoryFacade>(this);
  }

  TripDataFacade getActiveTrip() {
    return getTripRepository().activeTrip!;
  }
}
