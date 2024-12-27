import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/app/models/auth_type.dart';
import 'package:wandrr/presentation/app/blocs/authentication/auth_events.dart';
import 'package:wandrr/presentation/app/blocs/authentication/auth_states.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  static final Map<String, AuthenticationFailures>
      _authenticationFailuresAndMessages = {
    'invalid-email': AuthenticationFailures.InvalidEmail,
    'wrong-password': AuthenticationFailures.WrongPassword,
    'user-not-found': AuthenticationFailures.NoSuchUsernameExists,
    'email-already-in-use': AuthenticationFailures.UsernameAlreadyExists
  };

  AppDataFacade _appLevelData;

  AuthenticationBloc(AppDataFacade appLevelData)
      : _appLevelData = appLevelData,
        super(AuthInitialState()) {
    on<AuthenticateWithUsernamePassword>(_onAuthWithUsernamePassword);
    on<AuthenticateWithThirdParty>(_onAuthWithThirdParty);
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
    } on FirebaseAuthException catch (exception) {
      emit(AuthenticationFailure(
          failureReason:
              _getAuthFailureReason(exception.code, exception.message)));
    }
  }

  FutureOr<void> _onAuthWithThirdParty(AuthenticateWithThirdParty event,
      Emitter<AuthenticationState> emit) async {
    if (event.authenticationType != AuthenticationType.Google) {
      return;
    }

    // Trigger the authentication flow
    var googleSignIn = GoogleSignIn(clientId: _appLevelData.googleWebClientId);
    // var googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    var userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    if (userCredential.user != null) {
      emit(AuthenticationSuccess(
          authProviderUser: userCredential.user!,
          authenticationType: AuthenticationType.Google));
    }
  }
}
