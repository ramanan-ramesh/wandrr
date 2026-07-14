import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/auth/models/status.dart';

abstract class MasterPageState {
  const MasterPageState();
}

class Loading extends MasterPageState {
  const Loading();
}

class LoadedRepository extends MasterPageState {
  final AppDataFacade appData;

  const LoadedRepository({required this.appData});
}

class ActiveLanguageChanged extends MasterPageState {
  final Locale locale;

  const ActiveLanguageChanged({required this.locale});
}

class ActiveThemeModeChanged extends MasterPageState {
  final ThemeMode themeMode;

  const ActiveThemeModeChanged({required this.themeMode});
}

class AuthStateChanged extends MasterPageState {
  final AuthStatus authStatus;

  const AuthStateChanged({required this.authStatus});
}

class UpdateAvailable extends MasterPageState {
  final UpdateInfo updateInfo;

  const UpdateAvailable({required this.updateInfo});
}

class UpdateInfo {
  final String latestVersion;
  final bool isForceUpdate;
  final String releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.isForceUpdate,
    required this.releaseNotes,
  });
}
