import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wandrr/app_data/implementations/firebase_options.dart';
import 'package:wandrr/app_data/models/app_level_data.dart';
import 'package:wandrr/app_data/models/auth_type.dart';
import 'package:wandrr/app_data/models/platform_data_repository.dart';
import 'package:wandrr/trip_data/implementations/collection_names.dart';

import '../../api_services/implementations/currency_converter.dart';
import '../../api_services/implementations/flight_operations_service.dart';
import '../../api_services/implementations/geo_locator.dart';
import 'user_management.dart';

class PlatformDataRepository implements PlatformDataRepositoryModifier {
  static const String _platformDataBox = 'platformData';
  static const String _language = "language";
  static const String _defaultLanguage = "en";

  final AppLevelData _appLevelData;
  final UserManagement _userManagement;

  @override
  AppLevelDataFacade get appData {
    return _appLevelData;
  }

  @override
  CurrencyConverter get currencyConverter => _currencyConverter;
  final CurrencyConverter _currencyConverter;

  @override
  GeoLocator get geoLocator => _geoLocator;
  final GeoLocator _geoLocator;

  @override
  FlightOperations get flightOperationsService => _flightOperationsService;
  final FlightOperations _flightOperationsService;

  static const String _themeMode = "themeMode";
  static const String _googleWebClientIdField = 'webClientId';

  static PlatformDataRepositoryFacade? _singleTonInstance;

  static Future<PlatformDataRepositoryFacade> create() async {
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

    var geoLocator = await GeoLocator.create();
    var currencyConverter = CurrencyConverter.create();
    var flightOperationsService = await FlightOperations.create();
    _singleTonInstance = PlatformDataRepository._(
        userManagement: userManagement,
        initialLanguage: language,
        initialThemeMode: themeMode,
        geoLocator: geoLocator,
        flightOperationsService: flightOperationsService,
        currencyConverter: currencyConverter,
        googleWebClientId: googleWebClientId);
    return _singleTonInstance!;
  }

  PlatformDataRepository._(
      {required UserManagement userManagement,
      required String initialLanguage,
      required ThemeMode initialThemeMode,
      required GeoLocator geoLocator,
      required FlightOperations flightOperationsService,
      required CurrencyConverter currencyConverter,
      required String googleWebClientId})
      : _userManagement = userManagement,
        _geoLocator = geoLocator,
        _currencyConverter = currencyConverter,
        _flightOperationsService = flightOperationsService,
        _appLevelData = AppLevelData(
            initialUser: userManagement.activeUser,
            initialLanguage: initialLanguage,
            initialThemeMode: initialThemeMode,
            googleWebClientId: googleWebClientId);

  @override
  Future<bool> tryUpdateActiveUser(
      {required User authProviderUser,
      required AuthenticationType authenticationType}) async {
    var didUpdateActiveUser = await _userManagement.tryUpdateActiveUser(
        authProviderUser: authProviderUser,
        authenticationType: authenticationType);
    if (didUpdateActiveUser) {
      _appLevelData.updateActiveUser(_userManagement.activeUser);
    }
    return didUpdateActiveUser;
  }

  @override
  Future<void> updateActiveLanguage({required String language}) async {
    var platformLocalBox = await Hive.openBox(_platformDataBox);
    await _writeRecordToLocalStorage(platformLocalBox, _language, language);
    await platformLocalBox.close();
    _appLevelData.updateActiveLanguage(language);
  }

  @override
  Future<void> updateActiveThemeMode({required ThemeMode themeMode}) async {
    var platformLocalBox = await Hive.openBox(_platformDataBox);
    await _writeRecordToLocalStorage(
        platformLocalBox, _themeMode, themeMode.name);
    await platformLocalBox.close();
    _appLevelData.updateActiveThemeMode(themeMode);
  }

  Future _writeRecordToLocalStorage(
      Box hiveBox, String recordKey, String recordValue) async {
    await hiveBox.put(recordKey, recordValue);
  }

  @override
  Future<bool> trySignOut() async {
    bool didSignOut = false;
    await FirebaseAuth.instance
        .signOut()
        .onError((error, stackTrace) => didSignOut = false)
        .then((value) => didSignOut = true);
    if (didSignOut) {
      _appLevelData.updateActiveUser(null);
      return await _userManagement.trySignOut();
    }
    return didSignOut;
  }
}
