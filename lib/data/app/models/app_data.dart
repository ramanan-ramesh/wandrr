import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/language_metadata.dart';

import 'auth_type.dart';
import 'platform_user.dart';

abstract class AppDataFacade {
  PlatformUser? get activeUser;

  String get activeLanguage;

  ThemeMode get activeThemeMode;

  String get defaultCurrency;

  bool get isBigLayout;

  String get googleWebClientId;

  Iterable<LanguageMetadata> get languageMetadatas;
}

abstract class AppDataModifier extends AppDataFacade {
  Future setActiveLanguage(String language);

  Future trySignOut();

  Future<bool> trySignIn(
      {required User authProviderUser,
      required AuthenticationType authenticationType});

  Future setActiveThemeMode(ThemeMode themeMode);

  set isBigLayout(bool isBigLayout);
}
