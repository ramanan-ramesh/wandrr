import 'auth_type.dart';

class PlatformUser {
  final AuthenticationType authenticationType;
  final String userName;
  final bool isLoggedIn;
  final String? displayName;
  final String userID;
  final String? photoUrl;

  const PlatformUser.fromAuth(
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
