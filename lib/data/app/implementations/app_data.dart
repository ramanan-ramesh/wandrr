import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/app/models/language_metadata.dart';
import 'package:wandrr/data/auth/implementations/user_management.dart';
import 'package:wandrr/data/auth/models/user_management.dart';

import 'firebase_options.dart';

class AppDataRepository extends AppDataModifier {
  static const String _themeMode = "themeMode";

  static const _hindiLanguage = '\u0939\u093f\u0902\u0926\u0940';
  static const _tamilLanguage = '\u0ba4\u0bae\u0bbf\u0bb4\u0bcd';
  static const _englishLanguage = 'English';
  static const String _language = "language";
  static const String _defaultLanguage = "en";

  final SharedPreferences _localStorage;

  @override
  final UserManagementModifier userManagement;
  @override
  String activeLanguage;

  @override
  ThemeMode activeThemeMode;

  @override
  bool isBigLayout;

  @override
  final Iterable<LanguageMetadata> languageMetadatas;

  static Future<AppDataModifier> createInstance() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    var userManagement = await UserManagement.createInstance();
    var localStorage = await SharedPreferences.getInstance();
    var languageValue = localStorage.getString(_language);
    if (languageValue == null || languageValue.isEmpty) {
      await localStorage.setString(_language, _defaultLanguage);
      languageValue = _defaultLanguage;
    }
    var themeModeValue = localStorage.getString(_themeMode);
    if (themeModeValue == null) {
      await localStorage.setString(_themeMode, ThemeMode.dark.name);
    }
    var themeMode = themeModeValue is String
        ? (ThemeMode.values
            .firstWhere((element) => element.name == themeModeValue))
        : ThemeMode.dark;
    return AppDataRepository._(
        userManagement: userManagement,
        initialLanguage: languageValue,
        initialThemeMode: themeMode,
        localStorage: localStorage);
  }

  @override
  Future setActiveLanguage(String language) async {
    await _localStorage.setString(_language, language);
    activeLanguage = language;
  }

  @override
  Future setActiveThemeMode(ThemeMode themeMode) async {
    await _localStorage.setString(_themeMode, themeMode.name);
    activeThemeMode = themeMode;
  }

  AppDataRepository._(
      {required String initialLanguage,
      required ThemeMode initialThemeMode,
      required this.userManagement,
      required SharedPreferences localStorage})
      : _localStorage = localStorage,
        activeThemeMode = initialThemeMode,
        activeLanguage = initialLanguage,
        isBigLayout = false,
        languageMetadatas = [
          LanguageMetadata(
              Assets.images.flags.india.path, 'ta', _tamilLanguage),
          LanguageMetadata(
              Assets.images.flags.india.path, 'hi', _hindiLanguage),
          LanguageMetadata(
              Assets.images.flags.britain.path, 'en', _englishLanguage),
        ];
}
