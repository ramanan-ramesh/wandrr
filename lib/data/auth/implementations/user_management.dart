import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/auth/models/platform_user.dart';
import 'package:wandrr/data/auth/models/status.dart';
import 'package:wandrr/data/auth/models/user_management.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';

class UserManagement implements UserManagementModifier {
  static const _userNameField = 'userName';
  static const _userIDField = 'userID';
  static const String _usersDBCollectionName = 'users';
  static const String _googleWebClientIdField = 'webClientId';

  static const _userNotFoundErrorMessage = 'user-not-found';
  static const String _invalidEmailError = 'invalid-email';
  static const String _wrongPasswordError = 'wrong-password';
  static const String _emailAlreadyInUseError = 'email-already-in-use';
  static final Map<String, AuthStatus> _authenticationFailuresAndMessages = {
    _invalidEmailError: AuthStatus.invalidEmail,
    _wrongPasswordError: AuthStatus.wrongPassword,
    _userNotFoundErrorMessage: AuthStatus.noSuchUsernameExists,
    _emailAlreadyInUseError: AuthStatus.usernameAlreadyExists
  };

  final SharedPreferences _localStorage;

  @override
  PlatformUser? activeUser;

  static UserManagementModifier create(SharedPreferences sharedPreferences) {
    var currentUser = FirebaseAuth.instance.currentUser;
    PlatformUser? platformUser;
    if (currentUser != null) {
      platformUser = PlatformUser(
          userName: currentUser.email!,
          userID: currentUser.uid,
          displayName: currentUser.displayName,
          photoUrl: currentUser.photoURL);
    }
    return UserManagement._(
        activeUser: platformUser, localStorage: sharedPreferences);
  }

  @override
  Future<void> initialize() async {
    if (activeUser == null) {
      await _clearCache(_localStorage);
    }
  }

  @override
  Future<bool> doesUserNameExist(String userName) async {
    var existingUserId = await _retrieveUserIDForUserName(userName);
    return existingUserId != null;
  }

  @override
  Future<AuthStatus> trySignInWithUsernamePassword(
      {required String userName, required String password}) async {
    try {
      var existingUserId = await _retrieveUserIDForUserName(userName);
      if (existingUserId == null) {
        var userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: userName, password: password);
        if (userCredential.user != null) {
          if (!userCredential.user!.emailVerified) {
            await FirebaseAuth.instance.signOut();
            return AuthStatus.verificationPending;
          } else {
            return await _signInWithCredential(userCredential, existingUserId);
          }
        }
      } else {
        var userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: userName, password: password);
        return await _signInWithCredential(userCredential, existingUserId);
      }
    } on FirebaseAuthException catch (exception) {
      return _getAuthFailureReason(exception.code, exception.message);
    }
    return AuthStatus.undefined;
  }

  @override
  Future<AuthStatus> trySignUpWithUsernamePassword(
      {required String userName, required String password}) async {
    try {
      var existingUserId = await _retrieveUserIDForUserName(userName);
      if (existingUserId == null) {
        try {
          var userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: userName, password: password);
          if (userCredential.user != null) {
            await FirebaseAuth.instance.signOut();
            return userCredential.user!.emailVerified
                ? AuthStatus.usernameAlreadyExists
                : AuthStatus.verificationPending;
          }
        } on FirebaseAuthException catch (exception) {
          if (!exception.code.contains(_userNotFoundErrorMessage)) {
            return _getAuthFailureReason(exception.code, exception.message);
          }
        }
      }
      var userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: userName, password: password);
      userCredential.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      return AuthStatus.verificationPending;
    } on FirebaseAuthException catch (exception) {
      return _getAuthFailureReason(exception.code, exception.message);
    }
  }

  @override
  Future<AuthStatus> trySignInWithGoogle() async {
    try {
      GoogleSignIn googleSignIn;
      if (kIsWeb) {
        final googleConfigDocument = await FirebaseFirestore.instance
            .collection(FirestoreCollections.appConfig)
            .doc('google')
            .get();
        String googleWebClientId =
            googleConfigDocument[_googleWebClientIdField];
        googleSignIn = GoogleSignIn(
          clientId: googleWebClientId,
          scopes: ['email', 'profile'],
        );
      } else {
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
      }

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return AuthStatus.undefined;
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        return AuthStatus.undefined;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final existingUserId =
          await _retrieveUserIDForUserName(userCredential.user!.email!);
      return await _signInWithCredential(userCredential, existingUserId);
    } on FirebaseAuthException catch (e) {
      return _getAuthFailureReason(e.code, e.message);
    } on Exception {
      return AuthStatus.undefined;
    }
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

  @override
  Future<bool> resendVerificationEmail(String email, String password) async {
    try {
      var userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        if (!userCredential.user!.emailVerified) {
          unawaited(userCredential.user!.sendEmailVerification());
          await FirebaseAuth.instance.signOut();
          return true;
        } else {
          return false;
        }
      }
    } on FirebaseAuthException {
      return false;
    }
    return false;
  }

  Future<String?> _retrieveUserIDForUserName(String userName) async {
    var usersCollectionReference =
        FirebaseFirestore.instance.collection(_usersDBCollectionName);
    var queryForExistingUserDocument = await usersCollectionReference
        .where(_userNameField, isEqualTo: userName)
        .get();
    return queryForExistingUserDocument.docs.singleOrNull?.id;
  }

  Future<AuthStatus> _signInWithCredential(
      UserCredential userCredential, String? existingUserDocumentId) async {
    if (userCredential.user != null) {
      var didUpdateUserInDB = await _tryUpdateActiveUser(
          firebaseUser: userCredential.user!,
          existingUserDocumentId: existingUserDocumentId);
      return didUpdateUserInDB ? AuthStatus.loggedIn : AuthStatus.undefined;
    }
    return AuthStatus.undefined;
  }

  Future<bool> _tryUpdateActiveUser(
      {required User firebaseUser,
      required String? existingUserDocumentId}) async {
    try {
      if (existingUserDocumentId == null) {
        var usersCollectionReference =
            FirebaseFirestore.instance.collection(_usersDBCollectionName);
        var addedUserDocument = await usersCollectionReference
            .add({_userNameField: firebaseUser.email!});
        activeUser = PlatformUser(
            userName: firebaseUser.email!,
            userID: addedUserDocument.id,
            photoUrl: firebaseUser.photoURL);
      } else {
        activeUser = PlatformUser(
            userName: firebaseUser.email!,
            userID: existingUserDocumentId,
            photoUrl: firebaseUser.photoURL);
      }
      await _persistActiveUser();
      return true;
    } on Exception {
      return false;
    }
  }

  Future _persistActiveUser() async {
    if (activeUser != null) {
      await _localStorage.setString(_userIDField, activeUser!.userID);
    } else {
      await _clearCache(_localStorage);
    }
  }

  static Future<void> _clearCache(SharedPreferences localStorage) async {
    await localStorage.remove(_userIDField);
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

  UserManagement._(
      {required this.activeUser, required SharedPreferences localStorage})
      : _localStorage = localStorage;
}
