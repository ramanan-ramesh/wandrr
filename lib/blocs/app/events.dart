import 'package:flutter/material.dart';
import 'package:wandrr/data/auth/models/auth_type.dart';

abstract class MasterPageEvent {
  const MasterPageEvent();
}

abstract class AuthenticationEvent extends MasterPageEvent {
  const AuthenticationEvent();
}

class ChangeLanguage extends MasterPageEvent {
  final String languageToChangeTo;

  const ChangeLanguage({required this.languageToChangeTo});
}

class ChangeTheme extends MasterPageEvent {
  final ThemeMode themeModeToChangeTo;

  const ChangeTheme({required this.themeModeToChangeTo});
}

class AuthenticateWithUsernamePassword extends AuthenticationEvent {
  final String userName;
  final String password;
  final bool shouldRegister;

  const AuthenticateWithUsernamePassword(
      {required this.userName,
      required this.password,
      required this.shouldRegister});
}

class AuthenticateWithThirdParty extends AuthenticationEvent {
  final AuthenticationType authenticationType;

  const AuthenticateWithThirdParty(this.authenticationType);
}

class ResendEmailVerification extends AuthenticationEvent {
  final String userName;
  final String password;

  const ResendEmailVerification(
      {required this.userName, required this.password});
}

class Logout extends AuthenticationEvent {
  const Logout();
}
