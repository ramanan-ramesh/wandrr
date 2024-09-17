import 'auth_type.dart';

class PlatformUser {
  AuthenticationType authenticationType;
  String userName;
  bool isLoggedIn;
  String? displayName;
  String userID;
  String? photoUrl;

  PlatformUser.fromAuth(
      {required this.userName,
      required this.authenticationType,
      required this.userID,
      this.displayName,
      this.photoUrl})
      : isLoggedIn = true;

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
