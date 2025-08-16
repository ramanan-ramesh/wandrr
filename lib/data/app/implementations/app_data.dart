import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/app/models/language_metadata.dart';
import 'package:wandrr/data/auth/implementations/user_management.dart';
import 'package:wandrr/data/auth/models/user_management.dart';

import 'firebase_options.dart';

class AppDataRepository extends AppDataModifier {
  static const String _language = "language";
  static const String _defaultLanguage = "en";

  static const String _themeMode = "themeMode";

  static const _hindiLanguage = 'हिंदी';
  static const _tamilLanguage = 'தமிழ்';
  static const _englishLanguage = 'English';
  static const _imageAssetsLocation = 'assets/images/flags';

  final UserManagement _userManagement;

  @override
  UserManagementFacade get userManagementFacade => _userManagement;

  @override
  UserManagementModifier get userManagementModifier => _userManagement;

  @override
  String activeLanguage;

  @override
  ThemeMode activeThemeMode;

  @override
  bool isBigLayout;

  final SharedPreferences localStorage;

  @override
  final List<LanguageMetadata> languageMetadatas;

  static Future<AppDataModifier> create() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    var localStorage = await SharedPreferences.getInstance();
    var userManagement = await UserManagement.createInstance(localStorage);
    String language = localStorage.getString(_language) ?? _defaultLanguage;
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
        initialLanguage: language,
        initialThemeMode: themeMode,
        localStorage: localStorage);
  }

  @override
  Future setActiveLanguage(String language) async {
    await localStorage.setString(_language, language);
    activeLanguage = language;
  }

  @override
  Future setActiveThemeMode(ThemeMode themeMode) async {
    await localStorage.setString(_themeMode, themeMode.name);
    activeThemeMode = themeMode;
  }

  AppDataRepository._(
      {required String initialLanguage,
      required ThemeMode initialThemeMode,
      required UserManagement userManagement,
      required this.localStorage})
      : _userManagement = userManagement,
        activeThemeMode = initialThemeMode,
        activeLanguage = initialLanguage,
        isBigLayout = false,
        languageMetadatas = [
          const LanguageMetadata(
              '$_imageAssetsLocation/india.png', 'ta', _tamilLanguage),
          const LanguageMetadata(
              '$_imageAssetsLocation/india.png', 'hi', _hindiLanguage),
          const LanguageMetadata(
              '$_imageAssetsLocation/britain.png', 'en', _englishLanguage),
        ];
}
