import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/api_services/models/currency_data.dart';
import 'package:wandrr/app_data/models/app_level_data.dart';
import 'package:wandrr/app_data/models/platform_data_repository.dart';

extension RepositoryExt on BuildContext {
  PlatformDataRepositoryFacade getPlatformDataRepository() {
    return RepositoryProvider.of<PlatformDataRepositoryFacade>(this);
  }

  Iterable<CurrencyData> getSupportedCurrencies() {
    return getPlatformDataRepository().currencyConverter.supportedCurrencies;
  }

  AppLevelDataFacade getAppLevelData() {
    return getPlatformDataRepository().appData;
  }

  bool isBigLayout() {
    return getAppLevelData().isBigLayout;
  }
}
