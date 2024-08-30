import 'package:firebase_auth/firebase_auth.dart';

import 'auth_type.dart';

class PlatformUser {
  AuthenticationType authenticationType;
  String userName;
  bool isLoggedIn;
  String? displayName;
  String userID;
  String? photoUrl;

  User? authProviderUser;

  PlatformUser.fromAuth(
      {required this.userName,
      required this.authenticationType,
      required this.userID,
      this.displayName,
      this.photoUrl})
      : isLoggedIn = true;

  void attachAuthProviderUser(User authProviderUser) {
    this.authProviderUser = authProviderUser;
  }

  PlatformUser.fromCache(
      {required this.userName,
      required String authenticationTypedValue,
      this.displayName,
      required this.userID,
      this.photoUrl})
      : isLoggedIn = true,
        authenticationType = AuthenticationType.values.firstWhere((authValue) =>
            authValue.toString() ==
            'AuthenticationType.$authenticationTypedValue');
}
