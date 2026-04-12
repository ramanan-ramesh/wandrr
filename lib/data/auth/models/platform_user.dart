class PlatformUser {
  final String userName;
  final String? displayName;
  final String userID;
  final String? photoUrl;

  const PlatformUser.fromAuth(
      {required this.userName,
      required this.userID,
      this.displayName,
      this.photoUrl});

  PlatformUser.fromCache(
      {required this.userName,
      required String authenticationTypeRawValue,
      required this.userID,
      this.displayName,
      this.photoUrl});
}
