import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/api_services/models/currency_converter.dart';
import 'package:wandrr/api_services/models/flight_operations.dart';
import 'package:wandrr/api_services/models/geo_locator.dart';

import 'app_level_data.dart';
import 'auth_type.dart';

abstract class PlatformDataRepositoryFacade {
  AppLevelDataFacade get appData;

  CurrencyConverterService get currencyConverter;

  FlightOperationsService get flightOperationsService;

  GeoLocatorService get geoLocator;
}

abstract class PlatformDataRepositoryModifier
    extends PlatformDataRepositoryFacade {
  Future<bool> tryUpdateActiveUser(
      {required User authProviderUser,
      required AuthenticationType authenticationType});

  Future<void> updateActiveLanguage({required String language});

  Future<void> updateActiveThemeMode({required ThemeMode themeMode});

  Future<bool> trySignOut();
}
