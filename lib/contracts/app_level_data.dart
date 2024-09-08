import 'package:flutter/material.dart';

import 'platform_user.dart';

class AppLevelData implements AppLevelDataModifier {
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
        _activeLanguage = initialLanguage,
        isBigLayout = false;

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

  @override
  String get defaultCurrency => 'INR';

  @override
  bool isBigLayout;

  @override
  void updateLayoutType(bool isBigLayout) {
    this.isBigLayout = isBigLayout;
  }
}

abstract class AppLevelDataFacade {
  PlatformUser? get activeUser;

  String get activeLanguage;

  ThemeMode get activeThemeMode;

  String get defaultCurrency;

  bool get isBigLayout;
}

abstract class AppLevelDataModifier extends AppLevelDataFacade {
  void updateActiveLanguage(String language);

  void updateActiveUser(PlatformUser? platformUser);

  void updateActiveThemeMode(ThemeMode themeMode);

  void updateLayoutType(bool isBigLayout);
}
