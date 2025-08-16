import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/auth/models/auth_type.dart';

abstract class MasterPageEvent {}

abstract class AuthenticationEvent extends MasterPageEvent {}

class LoadApp extends MasterPageEvent {}

class ChangeLanguage extends MasterPageEvent {
  String languageToChangeTo;

  ChangeLanguage({required this.languageToChangeTo});
}

class ChangeTheme extends MasterPageEvent {
  ThemeMode themeModeToChangeTo;

  ChangeTheme({required this.themeModeToChangeTo});
}

class ChangeUser extends MasterPageEvent {
  User? authProviderUser;
  AuthenticationType? authenticationType;

  ChangeUser.signIn(
      {required User this.authProviderUser, required this.authenticationType});

  ChangeUser.signOut();
}

class AuthenticateWithUsernamePassword extends AuthenticationEvent {
  final String userName;
  final String password;
  final bool shouldRegister;

  AuthenticateWithUsernamePassword(
      {required this.userName,
      required this.password,
      required this.shouldRegister});
}

class AuthenticateWithThirdParty extends AuthenticationEvent {
  final AuthenticationType authenticationType;

  AuthenticateWithThirdParty(this.authenticationType);
}

class Logout extends AuthenticationEvent {
  Logout();
}
