import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wandrr/contracts/app_level_data.dart';
import 'package:wandrr/contracts/auth_type.dart';
import 'package:wandrr/contracts/platform_user.dart';
import 'package:wandrr/firebase_options.dart';

abstract class PlatformDataRepositoryFacade {
  AppLevelDataFacade get appLevelData;
}

abstract class PlatformDataRepositoryModifier {
  Future<bool> tryUpdateActiveUser(
      {required User authProviderUser,
      required AuthenticationType authenticationType});

  Future<void> updateActiveLanguage({required String language});

  Future<void> updateActiveThemeMode({required ThemeMode themeMode});

  Future<bool> trySignOut();
}

class PlatformDataRepository
    implements PlatformDataRepositoryFacade, PlatformDataRepositoryModifier {
  static const String _platformDataBox = 'platformData';
  static const String _language = "language";
  static const String _defaultLanguage = "en";

  AppLevelData _appLevelData;
  final _UserManagement _userManagement;

  @override
  AppLevelDataFacade get appLevelData {
    return _appLevelData;
  }

  static const String _themeMode = "themeMode";

  static PlatformDataRepository? _singleTonInstance;

  static Future<PlatformDataRepository> create() async {
    if (_singleTonInstance != null) {
      return _singleTonInstance!;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Hive.initFlutter();
    var userManagement = await _UserManagement.create();
    var platformDataBox = await Hive.openBox(_platformDataBox);
    String language = await platformDataBox.get(_language) ?? _defaultLanguage;
    var themeModeValue = await platformDataBox.get(_themeMode);
    await platformDataBox.close();
    ThemeMode themeMode = themeModeValue is String
        ? (ThemeMode.values
            .firstWhere((element) => element.name == themeModeValue))
        : ThemeMode.dark;
    _singleTonInstance = PlatformDataRepository._(
        userManagement: userManagement,
        initialLanguage: language,
        initialThemeMode: themeMode);
    return _singleTonInstance!;
  }

  PlatformDataRepository._(
      {required _UserManagement userManagement,
      required String initialLanguage,
      required ThemeMode initialThemeMode})
      : _userManagement = userManagement,
        _appLevelData = AppLevelData(
            initialUser: userManagement.activeUser,
            initialLanguage: initialLanguage,
            initialThemeMode: initialThemeMode);

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

class _UserManagement {
  static const String _usersCollectionInDB = 'users';

  static const _userName = 'userName';
  static const _authenticationType = 'authType';
  static const _userID = 'userID';
  static const _displayName = 'displayName';
  static const _isLoggedIn = 'isLoggedIn';

  PlatformUser? _activeUser;

  PlatformUser? get activeUser {
    return _activeUser;
  }

  static Future<_UserManagement> create() async {
    var userFromCache = await _getUserFromCache();
    return _UserManagement(initialUser: userFromCache);
  }

  _UserManagement({PlatformUser? initialUser}) : _activeUser = initialUser;

  Future<bool> tryUpdateActiveUser(
      {required User authProviderUser,
      required AuthenticationType authenticationType}) async {
    try {
      var usersCollectionReference =
          FirebaseFirestore.instance.collection(_usersCollectionInDB);
      var queryForExistingUserDocument = await usersCollectionReference
          .where(_userName, isEqualTo: authProviderUser.email)
          .get();
      if (queryForExistingUserDocument.docs.isEmpty) {
        var addedUserDocument = await usersCollectionReference.add(
            _userToJsonDocument(authProviderUser.email!, authenticationType));
        _activeUser = PlatformUser.fromAuth(
            userName: authProviderUser.email!,
            authenticationType: authenticationType,
            userID: addedUserDocument.id);
      } else {
        var existingUserDocument = queryForExistingUserDocument.docs.first;
        _activeUser = PlatformUser.fromAuth(
            userName: authProviderUser.email!,
            authenticationType: authenticationType,
            userID: existingUserDocument.id);
      }
      _activeUser?.attachAuthProviderUser(authProviderUser);
      _persistUser();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> trySignOut() async {
    try {
      _activeUser = null;
      _persistUser();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  //TODO: Should ideally attach AuthProviderUser here(if it persists)?
  static Future<PlatformUser?> _getUserFromCache() async {
    var usersBox = await Hive.openBox(_usersCollectionInDB);
    var isLoggedInValue = usersBox.get(_isLoggedIn) ?? '';
    if (bool.tryParse(isLoggedInValue) == true) {
      var userID = await usersBox.get(_userID) as String;
      var authType = await usersBox.get(_authenticationType) as String;
      var userName = await usersBox.get(_userName) as String;
      return PlatformUser.fromCache(
          userName: userName,
          authenticationTypedValue: authType,
          userID: userID);
    }
    await usersBox.close();

    return null;
  }

  void _persistUser() async {
    var usersBox = await Hive.openBox(_usersCollectionInDB);
    if (activeUser != null) {
      await _writeRecordToLocalStorage(usersBox, _userID, activeUser!.userID);
      await _writeRecordToLocalStorage(
          usersBox, _userName, activeUser!.userName);
      await _writeRecordToLocalStorage(
          usersBox, _authenticationType, activeUser!.authenticationType.name);
      var displayName = activeUser!.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        await _writeRecordToLocalStorage(usersBox, _displayName, displayName);
      }
      await _writeRecordToLocalStorage(usersBox, _isLoggedIn, true.toString());
    } else {
      await usersBox.clear();
      await _writeRecordToLocalStorage(usersBox, _isLoggedIn, false.toString());
    }
    await usersBox.close();
  }

  Future _writeRecordToLocalStorage(
      Box hiveBox, String recordKey, String recordValue) async {
    await hiveBox.put(recordKey, recordValue);
  }

  static Map<String, dynamic> _userToJsonDocument(
      String userName, AuthenticationType authenticationType) {
    //TODO: Must add display name also here, if it's present
    return {_userName: userName, _authenticationType: authenticationType.name};
  }
}
