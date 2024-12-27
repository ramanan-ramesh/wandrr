import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/app/models/auth_type.dart';
import 'package:wandrr/data/app/models/language_metadata.dart';
import 'package:wandrr/data/app/models/platform_user.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';

import 'firebase_options.dart';
import 'user_management.dart';

class AppDataRepository extends AppDataModifier {
  static const String _platformDataBox = 'platformData';
  static const String _language = "language";
  static const String _defaultLanguage = "en";

  static const String _themeMode = "themeMode";
  static const String _googleWebClientIdField = 'webClientId';

  static const _hindiLanguage = 'हिंदी';
  static const _englishLanguage = 'English';
  static const _imageAssetsLocation = 'assets/images/flags';

  final UserManagement _userManagement;

  static AppDataRepository? _singleTonInstance;

  @override
  String activeLanguage;

  @override
  ThemeMode activeThemeMode;

  @override
  PlatformUser? get activeUser => _activeUser;
  PlatformUser? _activeUser;

  @override
  bool isBigLayout;

  @override
  String get defaultCurrency => 'INR';

  @override
  final String googleWebClientId;

  @override
  final List<LanguageMetadata> languageMetadatas;

  static Future<AppDataModifier> create() async {
    if (_singleTonInstance != null) {
      return _singleTonInstance!;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    var googleConfigDocument = await FirebaseFirestore.instance
        .collection(FirestoreCollections.appConfig)
        .doc('google')
        .get();
    await Hive.initFlutter();
    String googleWebClientId = googleConfigDocument[_googleWebClientIdField];
    var userManagement = await UserManagement.create();
    var platformDataBox = await Hive.openBox(_platformDataBox);
    String language = await platformDataBox.get(_language) ?? _defaultLanguage;
    var themeModeValue = await platformDataBox.get(_themeMode);
    await platformDataBox.close();
    ThemeMode themeMode = themeModeValue is String
        ? (ThemeMode.values
            .firstWhere((element) => element.name == themeModeValue))
        : ThemeMode.dark;

    _singleTonInstance = AppDataRepository._(
        userManagement: userManagement,
        initialLanguage: language,
        initialThemeMode: themeMode,
        googleWebClientId: googleWebClientId);
    return _singleTonInstance!;
  }

  @override
  Future setActiveLanguage(String language) async {
    var platformLocalBox = await Hive.openBox(_platformDataBox);
    await _writeRecordToLocalStorage(platformLocalBox, _language, language);
    await platformLocalBox.close();
    activeLanguage = language;
  }

  @override
  Future setActiveThemeMode(ThemeMode themeMode) async {
    var platformLocalBox = await Hive.openBox(_platformDataBox);
    await _writeRecordToLocalStorage(
        platformLocalBox, _themeMode, themeMode.name);
    await platformLocalBox.close();
    activeThemeMode = themeMode;
  }

  @override
  Future<bool> trySignIn(
      {required User authProviderUser,
      required AuthenticationType authenticationType}) async {
    var didUpdateActiveUser = await _userManagement.tryUpdateActiveUser(
        authProviderUser: authProviderUser,
        authenticationType: authenticationType);
    if (didUpdateActiveUser) {
      _activeUser = _userManagement.activeUser;
    }
    return didUpdateActiveUser;
  }

  @override
  Future<bool> trySignOut() async {
    bool didSignOut = false;
    await FirebaseAuth.instance
        .signOut()
        .onError((error, stackTrace) => didSignOut = false)
        .then((value) => didSignOut = true);
    if (didSignOut) {
      await _userManagement.trySignOut();
      _activeUser = null;
    }
    return didSignOut;
  }

  Future _writeRecordToLocalStorage(
      Box hiveBox, String recordKey, String recordValue) async {
    await hiveBox.put(recordKey, recordValue);
  }

  AppDataRepository._(
      {PlatformUser? initialUser,
      required String initialLanguage,
      required ThemeMode initialThemeMode,
      required this.googleWebClientId,
      required UserManagement userManagement})
      : _userManagement = userManagement,
        _activeUser = initialUser,
        activeThemeMode = initialThemeMode,
        activeLanguage = initialLanguage,
        isBigLayout = false,
        languageMetadatas = [
          const LanguageMetadata(
              '$_imageAssetsLocation/india.png', 'hi', _hindiLanguage),
          const LanguageMetadata(
              '$_imageAssetsLocation/britain.png', 'en', _englishLanguage)
        ];
}
