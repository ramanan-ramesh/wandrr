import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wandrr/app_data/models/auth_type.dart';
import 'package:wandrr/app_data/models/platform_user.dart';

class UserManagement {
  static const String _usersCollectionInDB = 'users';

  static const _userName = 'userName';
  static const _authenticationType = 'authType';
  static const _userID = 'userID';
  static const _displayName = 'displayName';
  static const _isLoggedIn = 'isLoggedIn';
  static const _photoUrl = 'photoUrl';

  PlatformUser? _activeUser;

  PlatformUser? get activeUser {
    return _activeUser;
  }

  static Future<UserManagement> create() async {
    var userFromCache = await _getUserFromCache();
    return UserManagement(initialUser: userFromCache);
  }

  UserManagement({PlatformUser? initialUser}) : _activeUser = initialUser;

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
            userID: addedUserDocument.id,
            photoUrl: authProviderUser.photoURL);
      } else {
        var existingUserDocument = queryForExistingUserDocument.docs.first;
        _activeUser = PlatformUser.fromAuth(
            userName: authProviderUser.email!,
            authenticationType: authenticationType,
            userID: existingUserDocument.id,
            photoUrl: authProviderUser.photoURL);
      }
      await _persistUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> trySignOut() async {
    try {
      _activeUser = null;
      await _persistUser();
      return true;
    } catch (e) {
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

  Future _persistUser() async {
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
      if (_activeUser!.photoUrl != null) {
        await _writeRecordToLocalStorage(
            usersBox, _photoUrl, _activeUser!.photoUrl!);
      }
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
