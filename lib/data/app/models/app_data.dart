import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/language_metadata.dart';
import 'package:wandrr/data/auth/models/user_management.dart';

abstract class AppDataFacade {
  UserManagementFacade get userManagementFacade;

  String get activeLanguage;

  ThemeMode get activeThemeMode;

  bool get isBigLayout;

  Iterable<LanguageMetadata> get languageMetadatas;
}

abstract class AppDataModifier extends AppDataFacade {
  Future setActiveLanguage(String language);

  UserManagementModifier get userManagementModifier;

  Future setActiveThemeMode(ThemeMode themeMode);

  set isBigLayout(bool isBigLayout);
}
