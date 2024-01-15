import 'package:flutter/material.dart';

import 'platform_user.dart';

class AppLevelData implements AppLevelDataFacade, AppLevelDataModifier {
  PlatformUser? _activeUser;
  String _activeLanguage;
  ThemeMode _activeThemeMode;

  @override
  String get activeLanguage => _activeLanguage;

  @override
  ThemeMode get activeThemeMode => _activeThemeMode;

  @override
  PlatformUser? get activeUser => _activeUser;

  AppLevelData(
      {PlatformUser? initialUser,
      required String initialLanguage,
      required ThemeMode initialThemeMode})
      : _activeUser = initialUser,
        _activeThemeMode = initialThemeMode,
        _activeLanguage = initialLanguage;

  @override
  void updateActiveLanguage(String language) {
    _activeLanguage = language;
  }

  @override
  void updateActiveThemeMode(ThemeMode themeMode) {
    _activeThemeMode = themeMode;
  }

  @override
  void updateActiveUser(PlatformUser? platformUser) {
    _activeUser = platformUser;
  }
}

abstract class AppLevelDataFacade {
  PlatformUser? get activeUser;

  String get activeLanguage;

  ThemeMode get activeThemeMode;
}

abstract class AppLevelDataModifier {
  void updateActiveLanguage(String language);

  void updateActiveUser(PlatformUser? platformUser);

  void updateActiveThemeMode(ThemeMode themeMode);
}