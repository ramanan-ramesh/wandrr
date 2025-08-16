import 'auth_type.dart';

class PlatformUser {
  final AuthenticationType authenticationType;
  final String userName;
  final String? displayName;
  final String userID;
  final String? photoUrl;

  const PlatformUser.fromAuth(
      {required this.userName,
      required this.authenticationType,
      required this.userID,
      this.displayName,
      this.photoUrl});

  PlatformUser.fromCache(
      {required this.userName,
      required String authenticationTypeRawValue,
      this.displayName,
      required this.userID,
      this.photoUrl})
      : authenticationType = AuthenticationType.values.firstWhere((authValue) =>
            authValue.toString() ==
            'AuthenticationType.$authenticationTypeRawValue');
}
