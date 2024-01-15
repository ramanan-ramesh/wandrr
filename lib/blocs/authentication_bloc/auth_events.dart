abstract class AuthenticationEvent {}

class AuthenticateWithUsernamePassword extends AuthenticationEvent {
  final String userName;
  final String passWord;
  final bool isLogin;

  AuthenticateWithUsernamePassword(
      {required this.userName, required this.passWord, required this.isLogin});
}

class Logout extends AuthenticationEvent {
  Logout();
}
