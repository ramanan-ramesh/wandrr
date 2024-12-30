import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wandrr/data/app/models/auth_type.dart';
import 'package:wandrr/data/app/models/platform_user.dart';

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

  FlutterSecureStorage localStorage;

  static Future<UserManagement> create(
      FlutterSecureStorage localStorage) async {
    var userFromCache = await _getUserFromCache(localStorage);
    return UserManagement(
        initialUser: userFromCache, localStorage: localStorage);
  }

  UserManagement({PlatformUser? initialUser, required this.localStorage})
      : _activeUser = initialUser;

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
  static Future<PlatformUser?> _getUserFromCache(
      FlutterSecureStorage localStorage) async {
    var isLoggedInValue = await localStorage.read(key: _isLoggedIn) ?? '';
    if (bool.tryParse(isLoggedInValue) == true) {
      var userID = await localStorage.read(key: _userID) as String;
      var authType =
          await localStorage.read(key: _authenticationType) as String;
      var userName = await localStorage.read(key: _userName) as String;
      return PlatformUser.fromCache(
          userName: userName,
          authenticationTypedValue: authType,
          userID: userID);
    }

    return null;
  }

  Future _persistUser() async {
    if (activeUser != null) {
      await localStorage.write(key: _userID, value: activeUser!.userID);
      await localStorage.write(key: _userName, value: activeUser!.userName);
      await localStorage.write(
          key: _authenticationType, value: activeUser!.authenticationType.name);
      var displayName = activeUser!.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        await localStorage.write(key: _displayName, value: displayName);
      }
      await localStorage.write(key: _isLoggedIn, value: true.toString());
      if (_activeUser!.photoUrl != null) {
        await localStorage.write(key: _photoUrl, value: _activeUser!.photoUrl!);
      }
    } else {
      await localStorage.write(key: _isLoggedIn, value: false.toString());
    }
  }

  static Map<String, dynamic> _userToJsonDocument(
      String userName, AuthenticationType authenticationType) {
    //TODO: Must add display name also here, if it's present
    return {_userName: userName, _authenticationType: authenticationType.name};
  }
}
