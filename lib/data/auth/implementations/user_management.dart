import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/auth/models/auth_type.dart';
import 'package:wandrr/data/auth/models/platform_user.dart';
import 'package:wandrr/data/auth/models/status.dart';
import 'package:wandrr/data/auth/models/user_management.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';

class UserManagement implements UserManagementModifier {
  static const _userNameField = 'userName';
  static const _authenticationTypeField = 'authType';
  static const _userIDField = 'userID';
  static const _displayNameField = 'displayName';
  static const _isLoggedInField = 'isLoggedIn';
  static const _photoUrlField = 'photoUrl';
  static const String _usersDBCollectionName = 'users';
  static const String _googleWebClientIdField = 'webClientId';

  // List of all errors available here - https://firebase.google.com/docs/auth/admin/errors
  static final Map<String, AuthStatus> _authenticationFailuresAndMessages = {
    'invalid-email': AuthStatus.invalidEmail,
    'wrong-password': AuthStatus.wrongPassword,
    'user-not-found': AuthStatus.noSuchUsernameExists,
    'email-already-in-use': AuthStatus.usernameAlreadyExists
  };

  final SharedPreferences _localStorage;

  @override
  PlatformUser? activeUser;

  static Future<UserManagementModifier> createInstance() async {
    var sharedPreferences = await SharedPreferences.getInstance();
    var currentUser = FirebaseAuth.instance.currentUser;
    var platformUser = await _getPlatformUser(sharedPreferences, currentUser);
    return UserManagement._(
        activeUser: platformUser, localStorage: sharedPreferences);
  }

  @override
  Future<AuthStatus> trySignInWithUsernamePassword(
      {required String userName, required String password}) async {
    try {
      var userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: userName, password: password);
      return await _signInWithCredential(userCredential);
    } on FirebaseAuthException catch (exception) {
      return _getAuthFailureReason(exception.code, exception.message);
    }
  }

  @override
  Future<AuthStatus> trySignUpWithUsernamePassword(
      {required String userName, required String password}) async {
    try {
      var userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: userName, password: password);
      return await _signInWithCredential(userCredential);
    } on FirebaseAuthException catch (exception) {
      return _getAuthFailureReason(exception.code, exception.message);
    }
  }

  @override
  Future<AuthStatus> trySignInWithThirdParty(
      AuthenticationType authenticationType) async {
    if (authenticationType != AuthenticationType.google) {
      return AuthStatus.undefined;
    }

    var googleConfigDocument = await FirebaseFirestore.instance
        .collection(FirestoreCollections.appConfig)
        .doc('google')
        .get();
    String googleWebClientId = googleConfigDocument[_googleWebClientIdField];

    GoogleSignIn googleSignIn;
    if (Platform.isIOS) {
      googleSignIn = GoogleSignIn();
    } else {
      googleSignIn = GoogleSignIn(clientId: googleWebClientId);
    }
    var googleUser = await googleSignIn.signIn();

    var googleAuth = await googleUser?.authentication;

    var credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    var userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    return await _signInWithCredential(userCredential);
  }

  @override
  Future<bool> trySignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      activeUser = null;
      await _persistActiveUser();
      return true;
    } on Exception {
      return false;
    }
  }

  Future<AuthStatus> _signInWithCredential(
      UserCredential userCredential) async {
    if (userCredential.user != null) {
      var didUpdateUserInDB = await _tryUpdateActiveUser(
          authProviderUser: userCredential.user!,
          authenticationType: AuthenticationType.emailPassword);
      return didUpdateUserInDB ? AuthStatus.loggedIn : AuthStatus.undefined;
    }
    return AuthStatus.undefined;
  }

  Future<bool> _tryUpdateActiveUser(
      {required User authProviderUser,
      required AuthenticationType authenticationType}) async {
    try {
      var usersCollectionReference =
          FirebaseFirestore.instance.collection(_usersDBCollectionName);
      var queryForExistingUserDocument = await usersCollectionReference
          .where(_userNameField, isEqualTo: authProviderUser.email)
          .get();
      if (queryForExistingUserDocument.docs.isEmpty) {
        var addedUserDocument = await usersCollectionReference.add(
            _userToJsonDocument(authProviderUser.email!, authenticationType));
        activeUser = PlatformUser.fromAuth(
            userName: authProviderUser.email!,
            authenticationType: authenticationType,
            userID: addedUserDocument.id,
            photoUrl: authProviderUser.photoURL);
      } else {
        var existingUserDocument = queryForExistingUserDocument.docs.first;
        activeUser = PlatformUser.fromAuth(
            userName: authProviderUser.email!,
            authenticationType: authenticationType,
            userID: existingUserDocument.id,
            photoUrl: authProviderUser.photoURL);
      }
      await _persistActiveUser();
      return true;
    } on Exception {
      return false;
    }
  }

  //TODO: Should ideally attach AuthProviderUser here(if it persists)?
  static Future<PlatformUser?> _getPlatformUser(
      SharedPreferences localStorage, User? currentUser) async {
    var isLoggedInValue = localStorage.getBool(_isLoggedInField) ?? false;
    if (currentUser != null) {
      var authenticationType = AuthenticationType.emailPassword;
      if (isLoggedInValue) {
        var authTypeInLocalStorage =
            localStorage.getString(_authenticationTypeField) as String;
        authenticationType = AuthenticationType.values.firstWhere(
            (element) => element.name == authTypeInLocalStorage,
            orElse: () => AuthenticationType.emailPassword);
      }
      return PlatformUser.fromAuth(
          userName: currentUser.email!,
          authenticationType: authenticationType,
          userID: currentUser.uid,
          displayName: currentUser.displayName,
          photoUrl: currentUser.photoURL);
    } else {
      if (isLoggedInValue) {
        await _clearCache(localStorage);
      }
      return null;
    }
  }

  Future _persistActiveUser() async {
    if (activeUser != null) {
      await _localStorage.setString(_userIDField, activeUser!.userID);
      await _localStorage.setString(_userNameField, activeUser!.userName);
      await _localStorage.setString(
          _authenticationTypeField, activeUser!.authenticationType.name);
      var displayName = activeUser!.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        await _localStorage.setString(_displayNameField, displayName);
      }
      await _localStorage.setBool(_isLoggedInField, true);
      if (activeUser!.photoUrl != null) {
        await _localStorage.setString(_photoUrlField, activeUser!.photoUrl!);
      }
    } else {
      await _clearCache(_localStorage);
    }
  }

  static Future<void> _clearCache(SharedPreferences localStorage) async {
    await localStorage.setBool(_isLoggedInField, false);
    await localStorage.remove(_userIDField);
    await localStorage.remove(_userNameField);
    await localStorage.remove(_authenticationTypeField);
    await localStorage.remove(_displayNameField);
    await localStorage.remove(_photoUrlField);
  }

  static AuthStatus _getAuthFailureReason(
      String errorCode, String? errorMessage) {
    var authFailureReason = AuthStatus.undefined;
    if (errorMessage == null) {
      var matches = _authenticationFailuresAndMessages.keys
          .where((element) => errorCode.contains(element));
      if (matches.isNotEmpty) {
        return _authenticationFailuresAndMessages[matches.first]!;
      }
    } else {
      var matches = _authenticationFailuresAndMessages.keys.where((element) =>
          errorCode.contains(element) || errorMessage.contains(element));
      if (matches.isNotEmpty) {
        return _authenticationFailuresAndMessages[matches.first]!;
      }
    }
    return authFailureReason;
  }

  static Map<String, dynamic> _userToJsonDocument(
          String userName, AuthenticationType authenticationType) =>
      {
        _userNameField: userName,
        _authenticationTypeField: authenticationType.name
      };

  UserManagement._(
      {required this.activeUser, required SharedPreferences localStorage})
      : _localStorage = localStorage;
}
