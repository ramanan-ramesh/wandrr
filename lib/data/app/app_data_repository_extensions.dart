import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/auth/models/platform_user.dart';

extension RepositoryExt on BuildContext {
  AppDataFacade get appDataRepository =>
      RepositoryProvider.of<AppDataFacade>(this);

  AppDataModifier get appDataModifier => appDataRepository as AppDataModifier;

  bool get isBigLayout => appDataRepository.isBigLayout;

  set isBigLayout(bool isBigLayout) {
    (appDataRepository as AppDataModifier).isBigLayout = isBigLayout;
  }

  bool get isLightTheme => appDataRepository.activeThemeMode == ThemeMode.light;

  PlatformUser? get activeUser =>
      appDataRepository.userManagementFacade.activeUser;
}
