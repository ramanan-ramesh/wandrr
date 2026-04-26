class PlatformUser {
  final String userName;
  final String? displayName;
  final String userID;
  final String? photoUrl;

  const PlatformUser(
      {required this.userName,
      required this.userID,
      this.displayName,
      this.photoUrl});
}
