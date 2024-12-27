import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/app/models/platform_user.dart';

abstract class MasterPageState {}

class Loading extends MasterPageState {}

class LoadedRepository extends MasterPageState {
  AppDataFacade appData;

  LoadedRepository({required this.appData});
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
