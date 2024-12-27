import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/auth_type.dart';

abstract class MasterPageEvent {}

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

class Logout extends MasterPageEvent {
  Logout();
}
