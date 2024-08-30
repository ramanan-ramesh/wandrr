import 'package:flutter/material.dart';
import 'package:wandrr/contracts/app_level_data.dart';
import 'package:wandrr/contracts/platform_user.dart';

abstract class MasterPageState {}

class Loading extends MasterPageState {}

class Startup extends MasterPageState {
  AppDataFacade appLevelData;

  Startup({required this.appLevelData});
}

class ActiveLanguageChanged extends MasterPageState {
  String language;

  ActiveLanguageChanged({required this.language});
}

class ActiveThemeModeChanged extends MasterPageState {
  ThemeMode themeMode;

  ActiveThemeModeChanged({required this.themeMode});
}

class ActiveUserChanged extends MasterPageState {
  PlatformUser? user;

  ActiveUserChanged({required this.user});
}
