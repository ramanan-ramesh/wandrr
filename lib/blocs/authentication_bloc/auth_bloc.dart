import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wandrr/blocs/authentication_bloc/auth_events.dart';
import 'package:wandrr/blocs/authentication_bloc/auth_states.dart';
import 'package:wandrr/contracts/auth_type.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  static final Map<String, AuthenticationFailures>
      _authenticationFailuresAndMessages = {
    'invalid-email': AuthenticationFailures.InvalidEmail,
    'wrong-password': AuthenticationFailures.WrongPassword,
    'user-not-found': AuthenticationFailures.NoSuchUsernameExists,
    'email-already-in-use': AuthenticationFailures.UsernameAlreadyExists
  };

  AuthenticationBloc() : super(AuthInitialState()) {
    on<AuthenticateWithUsernamePassword>(_onAuthWithUsernamePassword);
  }

  static AuthenticationFailures _getAuthFailureReason(
      String errorCode, String? errorMessage) {
    AuthenticationFailures authFailureReason = AuthenticationFailures.Undefined;
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

  Future<FutureOr<void>> _onAuthWithUsernamePassword(
      AuthenticateWithUsernamePassword event,
      Emitter<AuthenticationState> emit) async {
    emit(Authenticating());
    try {
      UserCredential userCredential;
      if (event.isLogin) {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: event.userName, password: event.passWord);
      } else {
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: event.userName, password: event.passWord);
      }
      emit(AuthenticationSuccess(
          authProviderUser: userCredential.user!,
          authenticationType: AuthenticationType.EmailPassword));
    } on FirebaseAuthException catch (exception, stackTrace) {
      emit(AuthenticationFailure(
          failureReason:
              _getAuthFailureReason(exception.code, exception.message)));
    }
  }
}
