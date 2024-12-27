import 'package:firebase_auth/firebase_auth.dart';
import 'package:wandrr/data/app/models/auth_type.dart';

abstract class AuthenticationState {}

class AuthInitialState extends AuthenticationState {}

class Authenticating extends AuthenticationState {}

class AuthenticationSuccess extends AuthenticationState {
  final User authProviderUser;
  final AuthenticationType authenticationType;

  AuthenticationSuccess(
      {required this.authProviderUser, required this.authenticationType});
}

class AuthenticationFailure extends AuthenticationState {
  final AuthenticationFailures failureReason;

  AuthenticationFailure({required this.failureReason});
}

enum AuthenticationFailures {
  UsernameAlreadyExists,
  WrongPassword,
  NoSuchUsernameExists,
  InvalidEmail,
  Undefined,
  WeakPassword
}
