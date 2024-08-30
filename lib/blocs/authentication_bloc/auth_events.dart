import 'package:wandrr/contracts/auth_type.dart';

abstract class AuthenticationEvent {}

class AuthenticateWithUsernamePassword extends AuthenticationEvent {
  final String userName;
  final String passWord;
  final bool isLogin;

  AuthenticateWithUsernamePassword(
      {required this.userName, required this.passWord, required this.isLogin});
}

class AuthenticateWithThirdParty extends AuthenticationEvent {
  final AuthenticationType authenticationType;

  AuthenticateWithThirdParty(this.authenticationType);
}

class Logout extends AuthenticationEvent {
  Logout();
}
